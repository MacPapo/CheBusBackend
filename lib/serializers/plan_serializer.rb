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
        start_time: Helpers::TimeHelper.unix_converter(itinerary['startTime']),
        end_time: Helpers::TimeHelper.unix_converter(itinerary['endTime']),
        legs: legs(itinerary['legs'])
      }
    end

    def legs(legs)
      format_legs(legs) { |leg| format_leg(leg) }
    end

    def format_leg(leg)
      {
        mode: leg['mode'],
        start_time: Helpers::TimeHelper.unix_converter(leg['startTime']),
        end_time: Helpers::TimeHelper.unix_converter(leg['endTime']),
        from: format_location(leg['from']),
        to: format_location(leg['to']),
        route: format_route(leg['route']),
        legGeometry: format_leg_geometry(leg['legGeometry'])
      }
    end

    def format_plans(&block)
      if @object.is_a?(Array)
        @object.map(&block)
      else
        yield(@object)
      end
    end

    def format_location(loc)
      {
        name: loc['name'],
        latitude: loc['lat'],
        longitude: loc['lon'],
        departure_time: Helpers::TimeHelper.unix_converter(loc['departureTime']),
        arrival_time: Helpers::TimeHelper.unix_converter(loc['arrivalTime'])
      }
    end

    def format_leg_geometry(geo)
      {
        points: geo['points']
      }
    end

    def format_route(route)
      return nil if route.nil?

      {
        gtfs_id: route['gtfs_id'],
        long_name: route['longName'],
        short_name: route['shortName']
      }
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
