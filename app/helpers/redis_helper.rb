# frozen-string-literal: true

module Helpers::RedisHelper
  @geo_import_in_progress = false
  @import_all_stops_in_progress = false
  GEO_KEY = 'geo_stops'
  ALL_KEY = 'stops'

  def self.geo_import_stops_if_needed(stops)
    return if @geo_import_in_progress

    @geo_import_in_progress = true
    Thread.new do
      begin
        Application['redis'].pipelined do
          stops.each do |stop|
            self.geo_add_stop(stop)
          end
        end
      ensure
        @geo_import_in_progress = false
      end
    end
  end

  def self.import_all_stops_if_needed(stops)
    return if @import_all_stops_in_progress

    @import_all_stops_in_progress = true
    Thread.new do
      Application['redis'].set(ALL_KEY, stops)
    ensure
      @import_all_stops_in_progress = false
    end
  end

  def self.prepare_geo_stop(stop)
    # stop[0] -> name
    # stop[1] -> lat
    # stop[2] -> lon
    # stop[3] -> category
    # stop[4] -> rating
    [stop[2], stop[1], stop[0]]
  end

  def self.calculate_rating(distance)
    1.0 / distance.to_f
  end

  def self.geo_add_stop(stop)
    Application['redis'].geoadd(GEO_KEY, self.prepare_geo_stop(stop))
  end

  def self.geo_rating(point, radius_km = 1)
    lon = point[1]
    lat = point[0]
    unit = 'km'.freeze
    options = %w[WITHCOORD WITHDIST]

    # Chiamata a georadius
    stops_data = Application['redis'].georadius([GEO_KEY, lon, lat, radius_km, unit], *options)

    return if stops_data.nil? || stops_data.empty?

    stops_data.map { |x| {name: x[0], lat: x[2][1], lon: x[2][0], rating: self.calculate_rating(x[1])} }
  end

  def self.get_stops
    cached_data = Application['redis'].get(ALL_KEY)
    cached_data.nil? ? [] : Oj.load(cached_data)
  end
end
