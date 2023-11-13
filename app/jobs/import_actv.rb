# frozen_string_literal: true

require 'gtfs'

module Jobs
  class ImportActvJob
    def self.perform
      puts "Esecuzione di ImportJob: #{Time.now}"

      gtfs_url = "https://actv.avmspa.it/sites/default/files/attachments/opendata/automobilistico/actv_aut.zip"
      gtfs_source = GTFS::Source.build(gtfs_url)

      gtfs_source.each_agency { |agency_data| update_or_create_agency(agency_data) }
      gtfs_source.each_calendar { |calendar_data| update_or_create_calendar(calendar_data) }
      gtfs_source.each_calendar_date { |calendar_date_data| update_or_create_calendar_date(calendar_date_data) }
      gtfs_source.each_route { |route_data| update_or_create_route(route_data) }
      gtfs_source.each_shape { |shape_data| update_or_create_shape(shape_data) }
      gtfs_source.each_stop { |stop_data| update_or_create_stop(stop_data) }
      gtfs_source.each_trip { |trip_data| update_or_create_trip(trip_data) }
      gtfs_source.each_stop_time { |stop_time_data| update_or_create_stop_time(stop_time_data) }

      updated_values = Models::StopTime
        .select{
          [
            (row_number.function.over(partition: trip_id, order: Sequel.asc(stop_sequence)) - 1).as(:seq),
            :trip_id,
            :stop_sequence
          ]
        }

      updated_values.each do |row|
        Models::StopTime
          .where(trip_id: row[:trip_id], stop_sequence: row[:stop_sequence])
          .update(stop_sequence_consec: row[:seq])
      end
      
      Application['database'].refresh_view(:service_days)
    end

    def self.update_or_create_agency(agency_data)
      agency = Models::Agency[agency_id: agency_data.id] || Models::Agency.new

      agency.set(
        agency_name: agency_data.name,
        agency_url: agency_data.url,
        agency_timezone: agency_data.timezone,
        agency_lang: agency_data.lang,
        agency_phone: agency_data.phone,
        agency_fare_url: agency_data.fare_url
      )

      # Assegna l'agency_id separatamente se l'oggetto è nuovo
      agency.agency_id = agency_data.id if agency.new?

      if agency.modified?
        agency.save
        puts "Aggiornato: #{agency.agency_name}"
      end
    end

    def self.update_or_create_calendar(calendar_data)
      calendar = Models::Calendar.where(service_id: calendar_data.service_id).first || Models::Calendar.new

      convert_availability = ->(x) { x.to_i == 1 ? 'available' : 'not_available' }

      calendar.set(
        monday: convert_availability.call(calendar_data.monday),
        tuesday: convert_availability.call(calendar_data.tuesday),
        wednesday: convert_availability.call(calendar_data.wednesday),
        thursday: convert_availability.call(calendar_data.thursday),
        friday: convert_availability.call(calendar_data.friday),
        saturday: convert_availability.call(calendar_data.saturday),
        sunday: convert_availability.call(calendar_data.sunday),
        start_date: calendar_data.start_date,
        end_date: calendar_data.end_date
      )

      # Assegna il service_id separatamente se l'oggetto è nuovo
      calendar.service_id = calendar_data.service_id if calendar.new?

      if calendar.modified?
        calendar.save
        puts "Aggiornato: #{calendar.service_id}"
      end
    end

    def self.update_or_create_calendar_date(calendar_date_data)
      calendar_date = Models::CalendarDate.where(service_id: calendar_date_data.service_id,
                                         date: calendar_date_data.date).first || Models::CalendarDate.new

      if calendar_date.new?
        # Assegna direttamente i campi della chiave primaria per i nuovi record
        calendar_date.service_id = calendar_date_data.service_id
        calendar_date.date = calendar_date_data.date
      end

      # Mappa per convertire i tipi di eccezione
      exception_type_map = { 1 => 'added', 2 => 'removed' }

      # Aggiorna gli altri campi
      calendar_date.exception_type = exception_type_map[calendar_date_data.exception_type.to_i]

      if calendar_date.modified?
        calendar_date.save
        puts "Aggiornato: #{calendar_date.service_id}"
      end
    end


    def self.update_or_create_route(route_data)
      route = Models::Route.where(route_id: route_data.id).first || Models::Route.new

      # Mappa per convertire i tipi di rotte
      route_type_map = {
        0 => '0', 1 => '1', 2 => '2', 3 => '3', 4 => '4', 
        5 => '5', 6 => '6', 7 => '7', 11 => '11', 12 => '12'
      }

      route.set(
        agency_id: route_data.agency_id,
        route_short_name: route_data.short_name,
        route_long_name: route_data.long_name,
        route_desc: route_data.desc,
        route_type: route_type_map[route_data.type.to_i], # Usando la mappa per il tipo di rotta
        route_url: route_data.url,
        route_color: route_data.color,
        route_text_color: route_data.text_color
      )

      # Assegna route_id solo se l'oggetto è nuovo
      route.route_id = route_data.id if route.new?

      if route.modified?
        route.save
        puts "Aggiornato: #{route.route_short_name}" # o un altro attributo identificativo
      end
    end


    def self.update_or_create_shape(shape_data)
      shape = Models::Shape.where(
        shape_id: shape_data.id,
        shape_pt_sequence: shape_data.pt_sequence.to_i
      ).first || Models::Shape.new

      # Creazione del punto geografico
      point = Sequel.lit("ST_Point(?, ?)", shape_data.pt_lon, shape_data.pt_lat)

      shape.set(
        shape_id: shape_data.id,
        shape_pt_sequence: shape_data.pt_sequence.to_i,
        shape_pt_loc: point,
        shape_dist_traveled: shape_data.dist_traveled
      )

      if shape.modified?
        shape.save
        puts "Aggiornato: Shape ID #{shape.shape_id}"
      end
    end


    def self.update_or_create_stop(stop_data)
      stop = Models::Stop.where(stop_id: stop_data.id.to_s).first || Models::Stop.new

      # Mappa per i valori enum
      location_type_map = {
        0 => 'stop', 1 => 'station', 2 => 'entrance_exit', 3 => 'node', 4 => 'boarding_area'
      }
      wheelchair_boarding_map = {
        0 => 'no_info_or_inherit', 1 => 'accessible', 2 => 'not_accessible'
      }

      # Creazione del punto geografico
      point = Sequel.lit("ST_Point(?, ?)", stop_data.lon, stop_data.lat)

      stop.set(
        stop_code: stop_data.code,
        stop_name: stop_data.name,
        stop_desc: stop_data.desc,
        stop_loc: point, # Aggiornato per utilizzare il campo geography(POINT)
        zone_id: stop_data.zone_id,
        stop_url: stop_data.url,
        location_type: location_type_map[stop_data.location_type.to_i],
        parent_station: stop_data.parent_station,
        stop_timezone: stop_data.timezone,
        wheelchair_boarding: wheelchair_boarding_map[stop_data.wheelchair_boarding.to_i]
      )

      # Assegna stop_id solo se l'oggetto è nuovo
      stop.stop_id = stop_data.id.to_s if stop.new?

      if stop.modified?
        stop.save
        puts "Aggiornato: Stop ID #{stop.stop_id}"
      end
    end


    def self.update_or_create_trip(trip_data)
      trip = Models::Trip.where(trip_id: trip_data.id).first || Models::Trip.new

      # Mappe per convertire i valori enum, con un'attenzione particolare per nil
      wheelchair_accessible_map = {
        nil => 'unknown', '0' => 'unknown', '1' => 'accessible', '2' => 'not_accessible'
      }

      bikes_allowed_map = {
        nil => 'unknown', '0' => 'unknown', '1' => 'allowed', '2' => 'not_allowed'
      }

      wheelchair_value = wheelchair_accessible_map[trip_data.wheelchair_accessible]
      bikes_value = bikes_allowed_map[trip_data.bikes_allowed]

      # Utilizza Sequel.lit per forzare la stringa nella query
      wheelchair_literal = Sequel.lit("#{wheelchair_value}")
      bikes_literal = Sequel.lit("#{bikes_value}")

      trip.set(
        route_id: trip_data.route_id,
        service_id: trip_data.service_id,
        trip_headsign: trip_data.headsign,
        trip_short_name: trip_data.short_name,
        direction_id: trip_data.direction_id,
        block_id: trip_data.block_id,
        shape_id: trip_data.shape_id,
        wheelchair_accessible: wheelchair_literal,
        bikes_allowed: bikes_literal
      )
      
      trip.trip_id = trip_data.id if trip.new?

      if trip.modified?
        trip.save
        puts "Aggiornato: Trip ID #{trip.trip_id}"
      end
    end



    def self.update_or_create_stop_time(stop_time_data)
      stop_time = Models::StopTime.where(
        trip_id: stop_time_data.trip_id,
        stop_id: stop_time_data.stop_id,
        stop_sequence: stop_time_data.stop_sequence
      ).first || Models::StopTime.new

      # Mappe per convertire i valori enum
      pickup_drop_off_map = {
        nil => 'regular', '0' => 'regular', '1' => 'not_available', '2' => 'call', '3' => 'driver'
      }
      timepoint_map = {
        nil => 'approximate', '0' => 'approximate', '1' => 'exact'
      }

      # Converti i valori enum usando le mappe
      pickup_type_value = pickup_drop_off_map[stop_time_data.pickup_type]
      drop_off_type_value = pickup_drop_off_map[stop_time_data.drop_off_type]
      timepoint_value = timepoint_map[stop_time_data.timepoint]

      # Utilizza Sequel.lit per forzare le stringhe nella query
      pickup_type_literal = Sequel.lit("#{pickup_type_value}")
      drop_off_type_literal = Sequel.lit("#{drop_off_type_value}")
      timepoint_literal = Sequel.lit("#{timepoint_value}")

      stop_time.set(
        trip_id: stop_time_data.trip_id,
        stop_id: stop_time_data.stop_id,
        arrival_time: stop_time_data.arrival_time,
        departure_time: stop_time_data.departure_time,
        stop_sequence: stop_time_data.stop_sequence,
        stop_headsign: stop_time_data.stop_headsign,
        pickup_type: pickup_type_literal,
        drop_off_type: drop_off_type_literal,
        shape_dist_traveled: stop_time_data.shape_dist_traveled,
        timepoint: timepoint_literal
      )

      if stop_time.modified?
        stop_time.save
        puts "Aggiornato: Stop_Time ID #{stop_time.id}"
      end
    end

  end
end
