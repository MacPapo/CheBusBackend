# frozen_string_literal: true

# Registers the `:environment_variables` provider within the Application container.
# This provider is responsible for managing environment variables, particularly
# for development and test environments.

Application.register_provider(:environment_variables) do
  # Starts the environment_variables provider. This method is invoked during the application
  # initialization process and is responsible for setting up environment variables.
  start do
    # Retrieves the current environment of the Application (development, test, or production).
    env = Application.env

    # Checks if the current environment is either development or test.
    # In these cases, environment variables are loaded from .env files.
    if %w[development test].include?(env)
      require 'dotenv' # Requires the dotenv library, which handles .env file loading.

      # Loads environment variables from the .env file and an environment-specific .env file.
      # For example, .env.development for the development environment.
      # This enables different configurations for different environments.
      Dotenv.load('.env', ".env.#{env}")
    end
  end
end
