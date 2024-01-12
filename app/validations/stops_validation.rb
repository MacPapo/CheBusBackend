# frozen_string_literal: true

module Validations::StopsValidation
  # A contract class for validating stop parameters using Dry::Validation.
  class DepartureContract < Dry::Validation::Contract
    include Helpers::ValidatorHelper

    # Defines the parameters to be validated and their requirements.
    params do
      required(:stopname).filled(:string)
      required(:datetime).filled(:string, format?: DATETIME_REGEXP)
      required(:interval).filled(:integer, gt?: 0)
    end

    # Custom validation rule for 'datetime'.
    # Ensures that the datetime is valid, from the current year, and not in the past.
    rule(:datetime) do
      if (parsed_date = Helpers::ValidatorHelper.valid_date?(value))
        key.failure(DATETIME_ERROR) unless Helpers::ValidatorHelper.datetime_range(parsed_date)
      else
        key.failure(INVALID_DATETIME_ERROR)
      end
    end

    # Custom validation rule for 'interval'.
    # Ensures that the interval is within the specified range (30 minutes to 3 hours).
    rule(:interval) do
      key.failure(INTERVAL_ERROR) unless Helpers::ValidatorHelper.interval_range(value)
    end

    # Custom validation rule for 'stopname'.
    # Ensures that the stop name matches a specific format.
    rule(:stopname) do
      key.failure(STOPNAME_ERROR) unless Helpers::ValidatorHelper.stop_names_regex(value)
    end
  end

  class StopsContract < Dry::Validation::Contract
    params do
      required(:latitude).filled(:float)
      required(:longitude).filled(:float)
    end

    rule(:latitude) do
      key.failure(LATITUDE_ERROR) unless Helpers::ValidatorHelper.latitude_in_range(value)
    end

    rule(:longitude) do
      key.failure(LONGITUDE_ERROR) unless Helpers::ValidatorHelper.longitude_in_range(value)
    end
  end
end
