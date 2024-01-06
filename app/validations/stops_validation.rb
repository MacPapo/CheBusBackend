# frozen_string_literal: true

module Validations::StopsValidation
  # A contract class for validating stop parameters using Dry::Validation.
  class StopContract < Dry::Validation::Contract
    # Defines the parameters to be validated and their requirements.
    params do
      required(:stopname).filled(:string)
      required(:datetime).filled(:string, format?: Helpers::ValidatorHelper.datetime_regex)
      required(:interval).filled(:integer, gt?: 0)
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

    # Custom validation rule for 'interval'.
    # Ensures that the interval is within the specified range (30 minutes to 3 hours).
    rule(:interval) do
      key.failure('must be between 30 minutes and 3 hours') unless Helpers::ValidatorHelper.interval_range(value)
    end

    # Custom validation rule for 'stopname'.
    # Ensures that the stop name matches a specific format.
    rule(:stopname) do
      key.failure('must be a valid stop name format') unless Helpers::ValidatorHelper.stop_names_regex(value)
    end
  end
end
