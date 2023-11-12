# frozen_string_literal: true

# Module for defining API endpoints related to bus stops.
# Provides RESTful routes for accessing stop information and departures.
module Routes::API::V1::Stops
  MAX_DEPARTURES = 50
  DEPARTURES_PARAMS = %w[stopname datetime interval].freeze

  # Registers routes under the 'stops' namespace.
  # @param app [Roda] The Roda application to which the routes are registered.
  def self.register(app)
    app.hash_branch(:v1, 'stops') do |r|
      r.is do
        r.get { Routes::API::V1::Stops.handle_all_stops_request(r) }
      end

      r.on Integer do |stop_id|
        r.get { Routes::API::V1::Stops.handle_specific_stop_request(r, stop_id) }
      end

      r.on 'departures' do
        r.get(params!: DEPARTURES_PARAMS) do |stopname, datetime, interval|
          Routes::API::V1::Stops.handle_departures_request(r, stopname, datetime, interval)
        end
      end
    end
  end

  # Handles requests for all bus stops.
  # @param _r [Roda::RodaRequest] The Roda request object.
  # @return [String] Serialized JSON response containing all stops.
  def self.handle_all_stops_request(_r)
    query = Application['database'][:stops]
      .select(:stop_name)
      .distinct
      .to_a

    APIResponse.success(_r.response, Serializers::StopSerializer.new(query, view: :stop_only_name).to_json)
  end

  # Handles requests for a specific bus stop by its ID.
  # @param _r [Roda::RodaRequest] The Roda request object.
  # @param stop_id [Integer] The ID of the stop.
  # @return [String] Serialized JSON response of the specific stop.
  def self.handle_specific_stop_request(_r, stop_id)
    query = Application['database'][:stops]
      .where(stop_id: stop_id.to_s)
      .first

    if query
      APIResponse.success(_r.response, Serializers::StopSerializer.new(query, view: :detailed).to_json)
    else
      APIResponse.error(_r.response, 'Stop not found', 404)
    end
  end

  # Handles requests for departures from a specific stop within a given time interval.
  # @param _r [Roda::RodaRequest] The Roda request object.
  # @param stopname [String] The name of the stop.
  # @param datetime [String] The starting datetime for departures.
  # @param interval [String] The time interval in minutes.
  # @return [String] Serialized JSON response of departures.
  def self.handle_departures_request(_r, stopname, datetime, interval)
    contract = Validations::StopsValidation::StopContract.new
    validation_result = contract.call(stopname:, datetime:, interval:)

    if validation_result.success?
      from_date = DateTime.parse(datetime)
      to_date = from_date + (interval.to_i / 1440.0)

      query = Application['database'][:arrivals_departures]
        .where(stop_name: stopname, t_departure: from_date..to_date)
        .select(:trip_headsign, :service_id, :t_departure, :route_color, :route_text_color, :route_short_name, :trip_id)
        .limit(MAX_DEPARTURES)
        .to_a
      
      APIResponse.success(_r.response, Serializers::StopSerializer.new(query.sort_by { |departure| departure[:t_departure] }, view: :departures).to_json)
    else
      APIResponse.error(_r.response, validation_result.errors.to_h, 400)
    end
  end
end
