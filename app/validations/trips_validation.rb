# frozen_string_literal: true

module Validations::TripsValidation
  # A contract class for validating trip parameters using Dry::Validation.
  class TripContract < Dry::Validation::Contract
    # Defines the parameters to be validated and their requirements.
    params do
      required(:departure_stop_name).filled(:string)
      required(:service_id).filled(:string)
      required(:datetime).filled(:string, format?: /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\z/)
    end

    # Custom validation rule for 'departure_stop_name'.
    # Ensures that the departure stop name matches a specific format.
    rule(:departure_stop_name) do
      regex = /^[A-Za-z0-9' ]+(?:\s+[A-Za-z0-9' ]+)*$/
      key.failure('must be a valid stop name format') unless value.match?(regex)
    end

    # Custom validation rule for 'service_id'.
    # Ensures that the service ID matches the expected format (e.g., "3B0803_000").
    rule(:service_id) do
      key.failure('must match the expected format (e.g., 3B0803_000)') unless value.match?(/\A[0-9A-Z]+_[0-9]+\z/)
    end

    # Custom validation rule for 'datetime'.
    # Ensures that the datetime is valid, from the current year, and not in the past.
    rule(:datetime) do
      if (parsed_date = begin
                          DateTime.iso8601(value)
                        rescue StandardError
                          false
                        end)
        current_year = DateTime.now.year
        key.failure('must be a date from the current year') unless parsed_date.year == current_year
        key.failure('must not be before today') if parsed_date < DateTime.now
      else
        key.failure('must be a valid datetime')
      end
    end
  end
end
