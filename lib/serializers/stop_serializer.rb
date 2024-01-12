# frozen_string_literal: true

module Serializers
  class StopSerializer < ApplicationSerializer
    def initialize(object, opts = {})
      super(object)
      @opts = opts
    end

    def to_json(*_args)
      case @opts[:view]
      when :stops
        all_stops
      when :departures
        departures_stops
      else
        all_stops
      end
    end

    private

    def all_stops
      format_stops { |stop| format_stop(stop) }
    end

    def departures_stops
      format_stops { |departure| format_departure_stop(departure) }
    end

    def format_departure_stop(departure)
      retrive_from_route = ->(hash, key) { hash['route'].nil? || hash['route'].empty? ? nil : hash['route'][key] }
      {
        departure_stop_name: departure['from_stop'],
        departure_stop_lat: departure['from_lat'],
        departure_stop_lon: departure['from_lon'],
        departure_stop_mode: departure['from_mode'],
        first_departure_time: Helpers::TimeHelper.sec_til_mid(departure['scheduledArrival']),
        headsign: departure['headsign'],
        line: retrive_from_route.call(departure['trip'], 'shortName'),
        line_bg_color: retrive_from_route.call(departure['trip'], 'color'),
        line_txt_color: retrive_from_route.call(departure['trip'], 'textColor'),
        times: format_stop_times(departure['trip']['stoptimes']),
        geometries: departure['trip']['tripGeometry']['points']
      }
    end

    def format_stop(stop)
      {
        name: stop[0],
        lat: stop[1],
        lon: stop[2],
        category: stop[3],
        rating: stop[4]
      }
    end

    def format_stop_times(stop_times)
      stop_times.map do |stime|
        {
          t_departure: Helpers::TimeHelper.sec_til_mid(stime['scheduledDeparture']),
          stop_name: stime['stop']['name'],
          stop_lat: stime['stop']['lat'],
          stop_lon: stime['stop']['lon'],
          mode: stime['stop']['vehicleMode']
        }
      end
    end

    def format_stops(&block)
      if @object.is_a?(Array)
        @object.map(&block)
      else
        yield(@object)
      end
    end
  end
end
