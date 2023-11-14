# frozen_string_literal: true

require 'roda'
require 'newrelic_rpm'
require_relative './system/boot'

# The App class is the main entry point for the Roda application. It includes
# configuration for different environments, plugins for additional functionalities,
# and routes handling.
class App < Roda
  # Adds support for handling different execution environments (development, test, production).
  plugin :environments

  # Adds support for heartbeats, a simple way to check if the application is alive.
  plugin :heartbeat

  # Configures the logger plugin for development and production environments.
  # It provides an enhanced logger with additional features.
  configure :development, :production do
    plugin :enhanced_logger
  end

  # Adds automatic error handling capabilities to the application.
  # It enables custom responses for exceptions raised during request processing.
  plugin :error_handler

  # Provides custom handling for HTTP status codes.
  plugin :status_handler

  # Sets default headers for all responses. Includes headers for security and content type.
  plugin :default_headers,
         'content-type' => 'application/json',
         'strict-transport-security' => 'max-age=16070400;',
         'x-frame-options' => 'deny',
         'x-content-type-options' => 'nosniff',
         'x-xss-protection' => '1; mode=block'

  # Ensures that response headers are set as plain hashes.
  plugin :plain_hash_response_headers

  # Adds support for parameter matching in routes.
  plugin :param_matchers

  # Enables the use of 'hash branches' for routing.
  plugin :hash_branches

  # Custom handler for 404 Not Found HTTP status code.
  # @return [String] JSON string for the 404 error message.
  status_handler(404) do
    APIResponse.error(response, 'Where did it go?', 404)
  end

  # Registers the API routes from the Routes::API::Base module.
  Routes::API::Base.register(self)

  # Main routing block for the application.
  # It delegates the request handling to the hash branches.
  route do |r|
    r.hash_branches
  end
end
