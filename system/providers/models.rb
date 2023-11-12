# frozen_string_literal: true

# Registers the `:models` provider within the Application container.
# This provider is responsible for configuring the Sequel Model settings based on the application environment.

Application.register_provider(:models) do
  # Prepares the models provider by requiring necessary dependencies.
  # This method is invoked before the provider is started.
  prepare do
    require 'sequel/model' # Requires the Sequel::Model class from the Sequel gem.
  end

  # Starts the models provider. This method is invoked during the application
  # initialization process and is responsible for configuring the Sequel Model settings.
  start do
    # Customizes the configuration of Sequel::Model based on the current environment.
    if Application.env == 'development'
      # Disables the caching of associations in the development environment.
      # This setting helps during development by allowing changes in associations
      # to be reflected without needing to restart the server.
      Sequel::Model.cache_associations = false
    else
      # Enables the subclasses plugin for Sequel::Model in non-development environments.
      # This plugin tracks subclasses of models and is useful for applications using STI (Single Table Inheritance).
      Sequel::Model.plugin(:subclasses)

      # Freezes all descendents of Sequel::Model to prevent modifications in non-development environments.
      # This is an optimization that improves performance and thread-safety by making model classes immutable.
      Sequel::Model.freeze_descendents
    end
  end
end
