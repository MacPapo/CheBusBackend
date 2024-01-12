# frozen_string_literal: true

module Validations::RoutesValidation
  # A contract class for validating route parameters using Dry::Validation.
  class RouteContract < Dry::Validation::Contract
    include Helpers::ValidatorHelper

    # Defines the parameters to be validated and their requirements.
    params do
      required(:from_stop_name).filled(:string)
      required(:to_stop_name).filled(:string)
      required(:datetime).filled(:string, format?: DATETIME_REGEXP)
      required(:interval).filled(:integer, gt?: 0)
      required(:is_arrival_time).filled(:bool)
    end

    # Custom validation rule for 'from_stop_name' and 'to_stop_name'.
    # Ensures that the stop names match a specific format.
    rule(:from_stop_name, :to_stop_name) do
      key.failure(STOPNAME_ERROR) unless Helpers::ValidatorHelper.stop_names_regex(value)
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
  end
end
