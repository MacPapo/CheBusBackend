# frozen_string_literal: true

require 'bundler/setup'
require 'dry/system'

# The Application class is a container for registering and managing dependencies
# within the system. It uses Dry::System for dependency injection and management.
# This class configures the environment and loads various components and plugins needed
# for the application.
class Application < Dry::System::Container
  # Sets up the environment inferrer which determines the current environment
  # based on the 'RACK_ENV' environment variable, defaulting to 'development' if
  # 'RACK_ENV' is not set.
  use :env, inferrer: -> { ENV.fetch('RACK_ENV', 'development') }

  # Initializes Zeitwerk for autoloading with debug mode enabled.
  # Zeitwerk is an efficient and configurable code loader for Ruby.
  use :zeitwerk, debug: true

  # Configures the component directories for the application.
  # Components in 'app' and 'lib' directories are added to the container
  # for dependency management.
  configure do |config|
    config.component_dirs.add 'app'
    config.component_dirs.add 'lib'
  end
end

# Starts various system providers including environment variables, Oj (optimized JSON),
# logger, database connection, and model initialization.
# These are essential components for the application's runtime environment.
Application.start(:environment_variables)
Application.start(:oj)
Application.start(:logger)
Application.start(:database)
Application.start(:models)
Application.start(:validation)
