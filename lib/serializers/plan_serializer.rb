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

    def format_time(time)
      Time.at(time / 1000).strftime('%FT%H:%M:%S')
    end

    def format_itinerary(itinerary)
      {
        start_time: format_time(itinerary.start_time),
        end_time: format_time(itinerary.end_time),
        legs: legs(itinerary.legs)
      }
    end

    def legs(legs)
      format_legs(legs) { |leg| format_leg(leg) }
    end

    def format_leg(leg)
      {
        mode: leg.mode,
        start_time: format_time(leg.start_time),
        end_time: format_time(leg.end_time),
        from: format_location(leg.from),
        to: format_location(leg.to),
        route: format_route(leg.route),
        legGeometry: format_leg_geometry(leg.leg_geometry)
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
        name: loc.name,
        latitude: loc.lat,
        longitude: loc.lon,
        departure_time: format_time(loc.departure_time),
        arrival_time: format_time(loc.arrival_time)
      }
    end

    def format_leg_geometry(geo)
      {
        points: geo.points
      }
    end

    def format_route(route)
      return nil if route.nil?

      {
        gtfs_id: route.gtfs_id,
        long_name: route.long_name,
        short_name: route.short_name
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
