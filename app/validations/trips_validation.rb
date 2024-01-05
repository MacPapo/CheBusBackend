# frozen_string_literal: true

module Validations::TripsValidation
  # A contract class for validating trip parameters using Dry::Validation.
  class TripContract < Dry::Validation::Contract
    # Defines the parameters to be validated and their requirements.
    params do
      required(:trip_id).filled(:string)
      required(:datetime).filled(:string, format?: /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\z/)
    end

    # Custom validation rule for 'stop_id'.
    # Ensures that the service ID matches the expected format (e.g., "3B0803_000").
    rule(:trip_id) do
      key.failure('must match the expected format (e.g., 1:6015)') unless value.match?(/\A[0-9]+:[0-9]+\z/)
    end

    # Custom validation rule for 'datetime'.
    # Ensures that the datetime is valid, from the current year, and not in the past.
    rule(:datetime) do
      if (parsed_date = begin
                          value.to_time
                        rescue StandardError
                          false
                        end)
        current_date = Date.today
        key.failure('must be a date from the current year') unless parsed_date.between?(current_date, 1.months.from_now)
      else
        key.failure('must be a valid datetime')
      end
    end
  end
end
