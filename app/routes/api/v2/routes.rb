# frozen_string_literal: true

# This module defines routes for the V2 API namespace related to routing information.
module Routes::API::V2::Routes
  # Constants defining the required parameters for the route endpoint.
  ROUTE_PARAMS = %w[from_stop_name to_stop_name datetime interval is_arrival_time].freeze
  NUM_ITINERARIES = 100
  TRANSFER_PENALTY = 30
  WALK_RELUCTANCE = 60
  WAIT_RELUCTANCE = 1
  WALK_BOARD_COST = 700

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
      r.get(params!: ROUTE_PARAMS) do |from, to, datetime, interval, is_arrival_time|
        validation_result = Routes::API::V2::Routes.validate_params(from, to, datetime, interval, is_arrival_time)

        if validation_result.success?
          Routes::API::V2::Routes.handle_routes_request(response, from, to, datetime, interval, is_arrival_time)
        else
          APIResponse.error(response, validation_result.errors.to_h, 400)
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
  def self.validate_params(from_stop_name, to_stop_name, datetime, interval, is_arrival_time)
    contract = Validations::RoutesValidation::RouteContract.new
    contract.call(from_stop_name:, to_stop_name:, datetime:, interval:, is_arrival_time:)
  end

  def self.handle_routes_request(response, from_stop_name, to_stop_name, datetime, interval, is_arrival_time)
    date, time = Helpers::TimeHelper.split_date_and_time(datetime)
    interval_sec = Helpers::TimeHelper.min_in_sec(interval)

    from_lat, from_lon = fetch_location(from_stop_name)
    to_lat, to_lon = fetch_location(to_stop_name)

    if invalid_location?(from_lat, from_lon) || invalid_location?(to_lat, to_lon)
      return APIResponse.error(response, 'The stop names provided are incorrect!', 400)
    end

    result = Application['graphql'].query(
      Graphql::PlanQueries::PLAN,
      variables: {
        flat: from_lat,
        flon: from_lon,
        tlat: to_lat,
        tlon: to_lon,
        date:,
        time:,
        search_window: interval_sec,
        is_arrival_time:,
        num_itineraries: NUM_ITINERARIES,
        transfer_penalty: TRANSFER_PENALTY,
        walk_reluctance: WALK_RELUCTANCE,
        wait_reluctance: WAIT_RELUCTANCE,
        walk_board_cost: WALK_BOARD_COST
      }
    )['data']['plan']

    res_no_extra_walks = trim_walk_paths(result['itineraries'])
    if res_no_extra_walks.size == 1 && res_no_extra_walks[0]['legs'].empty?
      APIResponse.success(response, [])
    else
      APIResponse.success(response, Serializers::PlanSerializer.new(res_no_extra_walks).to_json)
    end
  end

  def self.invalid_location?(lat, lon)
    lat.nil? && lon.nil?
  end

  def self.fetch_location(stop_name)
    lat, lon = Models::StopCluster.search_location_in_cluster_by_name(stop_name)

    # If not in cluster
    lat, lon = Models::Stop.search_location_in_stops_by_name(stop_name) if invalid_location?(lat, lon)

    [lat, lon]
  end

  def self.trim_walk_paths(itineraries)
    itineraries.each do |it|
      leg = it['legs']

      unless leg.empty?
        if leg.first['mode'] == 'WALK' && leg.last['mode'] == 'WALK'
          leg.shift
          leg.pop
        elsif leg.first['mode'] == 'WALK'
          leg.shift
        elsif leg.last['mode'] == 'WALK'
          leg.pop
        end
      end
    end

    itineraries
  end
end
