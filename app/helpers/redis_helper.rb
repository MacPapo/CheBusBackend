# frozen-string-literal: true

module Helpers::RedisHelper
  KEY = 'stops'

  def self.round_point(point)
    point.to_f.round(5)
  end

  def self.import_stops(stops)
    Application['redis'].pipelined do
      stops.each { |stop| self.geo_add_stop(stop) }
    end
  end

  def self.prepare_geo_stop(stop)
    # stop[0] -> name
    # stop[1] -> lat
    # stop[2] -> lon
    # stop[3] -> category
    [stop[2], stop[1], stop[0]]
  end
  
  def self.geo_add_stop(stop)
    Application['redis'].geoadd(KEY, self.prepare_geo_stop(stop))
    self.hash_set_stop(stop)
  end

  def self.hash_set_stop(stop)
    lon = self.round_point(stop[2])
    lat = self.round_point(stop[1])
    Application['redis'].hset("stop_info:#{lon}:#{lat}", { CATEGORY: stop[-1].to_s })
  end
  
  def self.hash_get_stop(lon, lat)
    lon = self.round_point(lon)
    lat = self.round_point(lat)
    Application['redis'].hget("stop_info:#{lon}:#{lat}", 'CATEGORY')
  end

    # Metodo per recuperare tutte le fermate con le loro categorie
  def self.get_all_stops
    central_lon = 12.0
    central_lat = 45.0
    radius = 20000000
    unit = 'km'

    options = ['WITHCOORD']

    # Chiamata a georadius
    stops_data = Application['redis'].georadius([KEY, central_lon, central_lat, radius, unit], *options)

    formatted_stops_data = stops_data.map do |stop|
      name = stop[0]  # Nome della fermata
      lon, lat = stop[1] # Coordinate [lon, lat]

      category = self.hash_get_stop(lon, lat)
      [name, self.round_point(lon), self.round_point(lat), category]
    end

    formatted_stops_data
  end
end
