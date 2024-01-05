# frozen_string_literal: true

# This file is responsible for finalizing the application setup. It completes the
# automatic registration of application classes and external dependencies.

require 'active_support'
require 'active_support/all'
require_relative 'application'

# Start GraphQL provider
Application.start(:graphql)
Application.start(:redis)


# Completes the application setup by finalizing the registration of application
# classes and external dependencies located in the /system/providers folder.
# This is a crucial step for preparing the application environment for use.
Application.finalize!

# Additional configuration steps for specific components of the application.
# The following block is executed if both 'database' and 'logger' components
# are registered within the application.
if Application.key?('database') && Application.key?('logger')
  # Integrates the existing Logger instance with the database. This enables
  # the application's logger to log database operations, enhancing debuggability and monitoring.
  Application['database'].loggers << Application['logger']

  # Optimizes the application by freezing internal data structures of the Database
  # instance in production-like environments. This step is bypassed in development
  # environment to allow for more flexibility and ease of changes during development.
  Application['database'].freeze unless Application.env == 'development'
end
