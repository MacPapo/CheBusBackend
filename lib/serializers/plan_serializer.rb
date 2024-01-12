# frozen_string_literal: true

module Serializers
  # SERIALIZER
  class PlanSerializer < ApplicationSerializer
    def to_json(*_args)
      plans
    end

    private

    def plans
      format_plans { |itinerary| format_itinerary(itinerary) }
    end

    def format_itinerary(itinerary)
      {
        start_time: Helpers::TimeHelper.from_unix_to_formatted_date(itinerary['legs'][0]['startTime']),
        end_time: Helpers::TimeHelper.from_unix_to_formatted_date(itinerary['endTime']),
        stops: format_stops(itinerary['legs'])
      }
    end

    def format_stops(legs)
      format_legs(legs) { |leg| format_leg(leg) }
    end

    def format_leg(leg)
      retrive_from_route = ->(hash, key) { hash['route'].nil? || hash['route'].empty? ? nil : hash['route'][key] }
      {
        mode: leg['mode'],
        start_time: Helpers::TimeHelper.from_unix_to_formatted_date(leg['startTime']),
        end_time: Helpers::TimeHelper.from_unix_to_formatted_date(leg['endTime']),
        duration: Helpers::TimeHelper.sec_in_min(leg['duration']),
        distance: leg['distance'],
        line: retrive_from_route.call(leg, 'shortName'),
        line_bg_color: retrive_from_route.call(leg, 'color'),
        line_txt_color: retrive_from_route.call(leg, 'textColor'),
        times: format_times(leg['from'], leg['intermediatePlaces'], leg['to']),
        geometry: leg['legGeometry']['points']
      }
    end

    def format_times(first, mid, last)
      res = []
      res << format_location(first)
      res << mid.map { |x| format_location x } unless mid.nil? || mid.empty?
      res << format_location(last)

      res.flatten
    end

    def format_location(loc)
      {
        t_departure: Helpers::TimeHelper.from_unix_to_formatted_date(loc['departureTime']),
        name: loc['name'],
        mode: loc['stop']['vehicleMode'],
        latitude: loc['lat'],
        longitude: loc['lon']
      }
    end

    def format_plans(&block)
      if @object.is_a?(Array)
        @object.map(&block)
      else
        yield(@object)
      end
    end

    def format_legs(legs, &block)
      if legs.is_a?(Array)
        legs.map(&block)
      else
        yield(legs)
      end
    end
  end
end
