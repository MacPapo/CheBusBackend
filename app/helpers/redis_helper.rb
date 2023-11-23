# frozen_string_literal: true

module Helpers
  module RedisHelper
    def self.get_key_from_redis(key)
      return nil unless key.is_a?(String)

      Oj.load(Application['redis'].get(key))
    end

    # 86400 -> 24H
    def self.set_key_in_redis(key, value, exp = 86_400)
      return nil unless key.is_a?(String)

      Application['redis'].set(key, Oj.dump(value))
      Application['redis'].expire(key, exp)
    end
  end
end
