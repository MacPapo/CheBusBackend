# frozen_string_literal: true

# This module defines routes for the V2 API namespace related to routing information.
module Routes::API::V2::Routes
  # Constants defining the required parameters for the route endpoint.
  ROUTE_PARAMS = %w[from_stop_name to_stop_name datetime interval].freeze

  # Registers routes under the '/v2/routes' path.
  # @param app [Roda] The main application instance.
  def self.register(app)
    app.hash_branch(:v2, 'routes') do |r|
      # GET request handler for '/v2/routes'.
      # Validates the parameters and returns either a successful route data or an error message.
      # @param from [String] The name of the departure stop.
      # @param to [String] The name of the arrival stop.
      # @param datetime [String] The starting date and time.
      # @param interval [String] The time interval in minutes.
      r.get(params!: ROUTE_PARAMS) do |from, to, datetime, interval|
        validation_result = Routes::API::V2::Routes.validate_params(from, to, datetime, interval)
        
        if validation_result.success?
          result = Routes::API::V2::Routes.handle_routes_request(from, to, datetime, interval)
          result ? APIResponse.success(response, result) : APIResponse.error(response, 'No routes found', 404)
        else
          error_messages = validation_result.errors.to_h
          APIResponse.error(response, error_messages, 400)
        end
      end
    end
  end

  # Validates the input parameters using the defined contract.
  # @param from_stop_name [String] The name of the departure stop.
  # @param to_stop_name [String] The name of the arrival stop.
  # @param datetime [String] The specified datetime.
  # @param interval [String] The time interval in minutes.
  # @return [Dry::Validation::Result] The result of the validation.
  def self.validate_params(from_stop_name, to_stop_name, datetime, interval)
    contract = Validations::RoutesValidation::RouteContract.new
    contract.call(from_stop_name:, to_stop_name:, datetime:, interval:)
  end
  
  # Handles the request for route information.
  # Fetches the route data based on the validated parameters.
  # @param from_stop_name [String] The name of the departure stop.
  # @param to_stop_name [String] The name of the arrival stop.
  # @param datetime [String] The starting date and time.
  # @param interval [String] The time interval in minutes.
  # @return [Array<Hash>] The route data.
  def self.handle_routes_request(from_stop_name, to_stop_name, datetime, interval)
    from_datetime, to_datetime = Routes::API::V2::Routes.parse_datetime_and_interval(datetime, interval.to_i)
    from_stop_ids, to_stop_ids = Routes::API::V2::Routes.fetch_stop_ids(from_stop_name, to_stop_name)

    departures = Routes::API::V2::Routes.fetch_departures(from_stop_ids, from_datetime, to_datetime)
    arrivals   = Routes::API::V2::Routes.fetch_arrivals(to_stop_ids, from_datetime, to_datetime)

    Routes::API::V2::Routes.join_and_sort_departures_and_arrivals(departures, arrivals)
  end

  # Parses the datetime and calculates the interval end time.
  # @param datetime [String] The starting datetime.
  # @param interval [Integer] Interval in minutes.
  # @return [Array<DateTime>] The start and end datetime objects.
  def self.parse_datetime_and_interval(datetime, interval)
    [DateTime.parse(datetime), DateTime.parse(datetime) + (interval / 1440.0)]
  end

  # Fetches stop IDs for given stop names.
  # @param from_stop_name [String] The departure stop name.
  # @param to_stop_name [String] The arrival stop name.
  # @return [Array<Array<Integer>>] Arrays of stop IDs for departure and arrival stops.
  def self.fetch_stop_ids(from_stop_name, to_stop_name)
    from_stop_ids = Application['database'][:stops].where(stop_name: from_stop_name).select_map(:stop_id)
    to_stop_ids = Application['database'][:stops].where(stop_name: to_stop_name).select_map(:stop_id)
    [from_stop_ids, to_stop_ids]
  end

  # Fetches departure information based on given stop IDs and datetime range.
  # @param from_stop_ids [Array<Integer>] The departure stop IDs.
  # @param from_datetime [DateTime] The starting datetime.
  # @param to_datetime [DateTime] The ending datetime.
  # @return [Sequel::Dataset] Dataset containing departure information.
  def self.fetch_departures(from_stop_ids, from_datetime, to_datetime)
    Application['database'][:connections]
      .select(:trip_id, :t_departure, :from_stop_name, :route_short_name)
      .where(from_stop_id: from_stop_ids, t_departure: from_datetime..to_datetime)
      .from_self(alias: :departures)
  end

  # Fetches arrival information based on given stop IDs and datetime range.
  # @param to_stop_ids [Array<Integer>] The arrival stop IDs.
  # @param from_datetime [DateTime] The starting datetime.
  # @param to_datetime [DateTime] The ending datetime.
  # @return [Sequel::Dataset] Dataset containing arrival information.
  def self.fetch_arrivals(to_stop_ids, from_datetime, to_datetime)
    Application['database'][:connections]
      .select(:trip_id, :t_arrival, :to_stop_name)
      .where(to_stop_id: to_stop_ids, t_arrival: from_datetime..to_datetime)
      .from_self(alias: :arrivals)
  end

  # Joins and sorts the departures and arrivals datasets.
  # @param departures [Sequel::Dataset] Dataset containing departure information.
  # @param arrivals [Sequel::Dataset] Dataset containing arrival information.
  # @return [Array<Hash>] An array of hashes containing joined departure and arrival information.
  def self.join_and_sort_departures_and_arrivals(departures, arrivals)
    departures
      .join(arrivals, [%i[trip_id trip_id]], table_alias: :arrivals)
      .select(Sequel[:departures][:trip_id], Sequel[:departures][:t_departure], Sequel[:departures][:from_stop_name],
              Sequel[:departures][:route_short_name], Sequel[:arrivals][:t_arrival], Sequel[:arrivals][:to_stop_name])
      .to_a
      .sort_by { |departure| departure[:t_departure] }
  end
end
