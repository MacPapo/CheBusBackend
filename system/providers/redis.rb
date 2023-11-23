# frozen_string_literal: true

Application.register_provider(:redis) do
  # Prepares the database provider by requiring necessary libraries.
  # This is the initial setup step before the provider is started.
  prepare do
    require 'redis'
  end

  # Starts the redis provider. This method establishes the redis connection.
  start do
    redis = Redis.new(url: ENV.delete('REDIS_URL'))

    register(:redis, redis)
  end
end
