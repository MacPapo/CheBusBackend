# frozen_string_literal: true

# Registers the `:database` provider within the Application container. This provider
# is responsible for setting up, starting, and stopping the database connection.

Application.register_provider(:database) do
  # Prepares the database provider by requiring necessary libraries.
  # This is the initial setup step before the provider is started.
  prepare do
    require 'sequel/core'
  end

  # Starts the database provider. This method establishes the database connection
  # and applies necessary extensions based on the database type.
  start do
    # Removes DATABASE_URL from the environment to prevent its accidental use
    # in subprocesses. Then establishes a connection to the database using Sequel.
    database = Sequel.connect(ENV.delete('DATABASE_URL'))

    # Adds the pg_auto_parameterize extension for PostgreSQL databases to optimize
    # query parameter handling. Checks for PostgreSQL adapter and compatibility.
    database.extension :pg_auto_parameterize if database.adapter_scheme == :postgres && Sequel::Postgres::USES_PG

    # Enables PostgreSQL array and enum extensions, enhancing the handling of these
    # specific data types in database interactions.
    database.extension :pg_array
    database.extension :pg_enum

    # Registers the established database connection as a component in the Application container.
    # This makes the database connection available application-wide.
    register(:database, database)
  end

  # Stops the database provider. This method is called when the application is shutting down
  # or when the database connection needs to be refreshed or reconfigured.
  stop do
    # Disconnects the database connection if it exists within the container.
    # This ensures proper closure of the connection when the application stops.
    container[:database].disconnect if container.key?(:database)
  end
end
