# frozen_string_literal: true

module Validations::TripsValidation
  # A contract class for validating trip parameters using Dry::Validation.
  class TripContract < Dry::Validation::Contract
    # Defines the parameters to be validated and their requirements.
    params do
      required(:trip_id).filled(:string)
      required(:datetime).filled(:string, format?: Helpers::ValidatorHelper.datetime_regex)
    end

    # Custom validation rule for 'stop_id'.
    # Ensures that the service ID matches the expected format (e.g., "3B0803_000").
    rule(:trip_id) do
      key.failure('must match the expected format (e.g., 1:6015)') unless Helpers::ValidatorHelper.id_regex(value)
    end

    # Custom validation rule for 'datetime'.
    # Ensures that the datetime is valid, from the current year, and not in the past.
    rule(:datetime) do
      if (parsed_date = Helpers::ValidatorHelper.valid_date?(value))
        key.failure('must be a date from the current year') unless Helpers::ValidatorHelper.datetime_range(parsed_date)
      else
        key.failure('must be a valid datetime')
      end
    end
  end
end
