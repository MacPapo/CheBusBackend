# frozen-string-literal: true

module Helpers::RedisHelper
  KEY = 'stops'
  CATEGORY = 'category'

  def self.import_stops (stops)
    Application['redis'].pipelined do
      stops.each { |stop| self.geo_add_stop (stop) }
    end
  end
  
  def self.geo_add_stop (stop)
    Application['redis'].geoadd (KEY, stop)
    self.hash_set (stop)
  end

  def self.hash_set_stop (stop)
    Application['redis'].hset ("stop_info:#{stop[:name]}", CATEGORY, stop[:category])
  end
end
