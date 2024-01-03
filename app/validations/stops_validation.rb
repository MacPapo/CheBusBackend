# frozen_string_literal: true

module Validations::StopsValidation
  # A contract class for validating stop parameters using Dry::Validation.
  class StopContract < Dry::Validation::Contract
    # Defines the parameters to be validated and their requirements.
    params do
      required(:stopname).filled(:string)
      required(:datetime).filled(:string, format?: /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\z/)
      required(:interval).filled(:integer, gt?: 0)
    end

    # Custom validation rule for 'datetime'.
    # Ensures that the datetime is valid, from the current year, and not in the past.
    rule(:datetime) do
      if (parsed_date = begin
                          DateTime.iso8601(value)
                        rescue StandardError
                          false
                        end)
        current_date = DateTime.now - 1.hour
        date_interval = current_date + 3.months
        key.failure('must be a date within the next 3 months') unless parsed_date <= date_interval
        key.failure('must not be before today') if parsed_date < current_date
      else
        key.failure('must be a valid datetime')
      end
    end

    # Custom validation rule for 'interval'.
    # Ensures that the interval is within the specified range (30 minutes to 3 hours).
    rule(:interval) do
      key.failure('must be between 30 minutes and 3 hours') unless value >= 30 && value <= 180
    end

    # Custom validation rule for 'stopname'.
    # Ensures that the stop name matches a specific format.
    rule(:stopname) do
      regex = /^[A-Za-z0-9'. ]+(?:\s+[A-Za-z0-9'. ]+)*$/
      key.failure('must be a valid stop name format') unless value.match?(regex)
    end
  end
end
