# frozen_string_literal: true

# Registers the `:oj` provider within the Application container.
# This provider is responsible for configuring the Oj (Optimized JSON) gem used for JSON parsing and generation.

Application.register_provider(:oj) do
  # Prepares the Oj provider by requiring necessary dependencies.
  # This method is invoked before the provider is started.
  prepare do
    require 'oj' # Requires the Oj gem, a fast JSON parser and Object marshaller.
  end

  # Starts the Oj provider. This method is invoked during the application
  # initialization process and is responsible for configuring the default options for the Oj gem.
  start do
    # Configures the default options for the Oj gem.
    # The :compat mode is used to ensure maximum compatibility with the JSON standard and various Ruby objects.
    # In this mode, Oj attempts to serialize objects first by calling to_json() or to_hash() methods on the object.
    # If neither method is available, Oj will serialize the object by iterating over its instance variables.
    Oj.default_options = { mode: :compat }
  end
end
