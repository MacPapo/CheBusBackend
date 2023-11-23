# frozen_string_literal: true

# require 'gtfs'

module Jobs
  class ImportActv
    include Models
    
    def self.perform
      puts "Esecuzione di ImportJob: #{Time.now}"
      
      gtfs_url = "https://actv.avmspa.it/sites/default/files/attachments/opendata/automobilistico/actv_aut.zip"
      gtfs_source = GTFS::Source.build(gtfs_url)

      puts "BEGIN TO SLICE: #{Time.now}"
      agencies_raw = gtfs_source.agencies
      calendars_raw = gtfs_source.calendars
      calendar_dates_raw = gtfs_source.calendar_dates
      routes_raw = gtfs_source.routes
      shapes_raw = gtfs_source.shapes
      stops_raw = gtfs_source.stops
      trips_raw = gtfs_source.trips
      stop_times_raw = gtfs_source.stop_times
      
      mapped_agencies = agencies_raw.map do |agency|
        # Logica di mappatura per ogni agency
        {
          agency_id: agency.id,
          agency_name: agency.name,
          agency_url: agency.url,
          agency_timezone: agency.timezone,
          agency_lang: agency.lang,
          agency_phone: agency.phone,
          agency_fare_url: agency.fare_url
        }
      end

      convert_availability = ->(x) { x.to_i == 1 ? 'available' : 'not_available' }
      mapped_calendars = calendars_raw.map do |calendar|
        {
          service_id: calendar.service_id,
          monday: convert_availability.call(calendar.monday),
          tuesday: convert_availability.call(calendar.tuesday),
          wednesday: convert_availability.call(calendar.wednesday),
          thursday: convert_availability.call(calendar.thursday),
          friday: convert_availability.call(calendar.friday),
          saturday: convert_availability.call(calendar.saturday),
          sunday: convert_availability.call(calendar.sunday),
          start_date: calendar.start_date,
          end_date: calendar.end_date
        }
      end

      exception_type_map = { 1 => 'added', 2 => 'removed' }
      mapped_calendar_dates = calendar_dates_raw.map do |calendar_date|
        exception_type_value = exception_type_map[calendar_date.exception_type.to_i]
        
        {
          service_id: calendar_date.service_id,
          date: calendar_date.date,
          exception_type: exception_type_value
        }
      end

      route_type_map = {
        0 => '0', 1 => '1', 2 => '2', 3 => '3', 4 => '4', 
        5 => '5', 6 => '6', 7 => '7', 11 => '11', 12 => '12'
      }

      mapped_routes = routes_raw.flat_map do |route|
        route_value = route_type_map[route.type.to_i]

        new_route = Route.new(
          agency_id: route.agency_id,
          route_short_name: route.short_name,
          route_long_name: route.long_name,
          route_desc: route.desc,
          route_type: route_value,
          route_url: route.url,
          route_color: route.color,
          route_text_color: route.text_color
        )
        new_route.route_id = route.id
        new_route
      end

      mapped_shapes = shapes_raw.flat_map do |shape|
        point = Sequel.lit("ST_Point(?, ?)", shape.pt_lon, shape.pt_lat)

        Shape.new(
          shape_id: shape.id,
          shape_pt_sequence: shape.pt_sequence.to_i,
          shape_pt_loc: point,
          shape_dist_traveled: shape.dist_traveled
        )
      end

      location_type_map = {
        0 => 'stop', 1 => 'station', 2 => 'entrance_exit', 3 => 'node', 4 => 'boarding_area'
      }
      wheelchair_boarding_map = {
        0 => 'no_info_or_inherit', 1 => 'accessible', 2 => 'not_accessible'
      }
      
      mapped_stops = stops_raw.flat_map do |stop|
        point = Sequel.lit("ST_Point(?, ?)", stop.lon, stop.lat)
        location_value = location_type_map[stop.location_type.to_i]
        wheelchair_boarding_value = wheelchair_boarding_map[stop.wheelchair_boarding.to_i]
        
        {
          stop_id: stop.id.to_s,
          stop_code: stop.code,
          stop_name: stop.name,
          stop_desc: stop.desc,
          stop_loc: point,
          zone_id: stop.zone_id,
          stop_url: stop.url,
          location_type: location_value,
          parent_station: stop.parent_station,
          stop_timezone: stop.timezone,
          wheelchair_boarding: wheelchair_boarding_value
        }
      end

      wheelchair_accessible_map = {
        nil => 'unknown', '0' => 'unknown', '1' => 'accessible', '2' => 'not_accessible'
      }

      bikes_allowed_map = {
        nil => 'unknown', '0' => 'unknown', '1' => 'allowed', '2' => 'not_allowed'
      }

      mapped_trips = trips_raw.flat_map do |trip|
        wheelchair_accessible_value = Sequel.lit("#{wheelchair_accessible_map[trip.wheelchair_accessible]}")
        bikes_allowed_value = Sequel.lit("#{bikes_allowed_map[trip.bikes_allowed]}")

        new_trip = Trip.new(
          route_id: trip.route_id,
          service_id: trip.service_id,
          trip_headsign: trip.headsign,
          trip_short_name: trip.short_name,
          direction_id: trip.direction_id,
          block_id: trip.block_id,
          shape_id: trip.shape_id,
          wheelchair_accessible: wheelchair_accessible_value,
          bikes_allowed: bikes_allowed_value
        )
        new_trip.trip_id = trip.id
        new_trip
      end

      pickup_drop_off_map = {
        nil => 'regular', '0' => 'regular', '1' => 'not_available', '2' => 'call', '3' => 'driver'
      }
      timepoint_map = {
        nil => 'approximate', '0' => 'approximate', '1' => 'exact'
      }
      
      mapped_stop_times = stop_times_raw.flat_map do |stop_time|
        pickup_type_value = pickup_drop_off_map[stop_time.pickup_type]
        drop_off_type_value = pickup_drop_off_map[stop_time.drop_off_type]
        timepoint_value = timepoint_map[stop_time.timepoint]
      
        StopTime.new(
          trip_id: stop_time.trip_id,
          stop_id: stop_time.stop_id,
          arrival_time: stop_time.arrival_time,
          departure_time: stop_time.departure_time,
          stop_sequence: stop_time.stop_sequence,
          stop_headsign: stop_time.stop_headsign,
          pickup_type: pickup_type_value,
          drop_off_type: drop_off_type_value,
          shape_dist_traveled: stop_time.shape_dist_traveled,
          timepoint: timepoint_value
        )
      end

      Application['database'].transaction do
        puts 'Elimino in Agencies'
        Application['database'][:stop_times].delete
        Application['database'][:trips].delete
        Application['database'][:routes].delete
        Application['database'][:agencies].delete
        Application['database'][:shapes].delete
        Application['database'][:calendars].delete
        Application['database'][:calendar_dates].delete
        Application['database'][:stops].delete
        
        puts 'Inserisco in Agencies'
        Application['database'][:agencies].multi_insert(mapped_agencies)
        Application['database'][:calendars].multi_insert(mapped_calendars)
        Application['database'][:calendar_dates].multi_insert(mapped_calendar_dates)
        Application['database'][:routes].multi_insert(mapped_routes)
        Application['database'][:shapes].multi_insert(mapped_shapes)
        Application['database'][:stops].multi_insert(mapped_stops)
        Application['database'][:trips].multi_insert(mapped_trips)
        Application['database'][:stop_times].multi_insert(mapped_stop_times)


        updated_values = StopTime
          .select{
            [
              (row_number.function.over(partition: trip_id, order: Sequel.asc(stop_sequence)) - 1).as(:seq),
              :trip_id,
              :stop_sequence
            ]
          }

        updated_values.each do |row|
          StopTime
            .where(trip_id: row[:trip_id], stop_sequence: row[:stop_sequence])
            .update(stop_sequence_consec: row[:seq])
        end
        
        Application['database'].refresh_view(:service_days, concurrently: true)
      end
    end
  end
end
