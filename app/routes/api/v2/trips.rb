# frozen_string_literal: true

# This module defines routes for trips in the API version 1.
# It includes routes for retrieving trip information and stops associated with a trip.
module Routes::API::V2::Trips
  # Constants defining the required parameters for the stops endpoint.
  STOP_PARAMS = %w[departure_stop_name service_id datetime].freeze

  # Registers the trips related routes within the application.
  # @param app [Roda] The instance of the Roda application.
  def self.register(app)
    # Handles requests for '/v2/trips'.
    app.hash_branch(:v2, 'trips') do |r|
      # Handles requests with a trip ID.
      r.on Integer do |id|
        # Route: GET /v2/trips/:trip_id
        # Retrieves specific trip information based on the provided trip ID.
        r.is do
          # Retrieves specific trip information based on the provided trip ID.
          # @param id [Integer] The ID of the trip.
          # @return [String] A JSON formatted response containing trip information or an error message.
          query = Application['database'][:trips]
            .where(trip_id: id.to_s)
            .first
          query ? APIResponse.success(response, query) : APIResponse.error(response, 'Trip not found', 404)
        end

        # Route: GET /v2/trips/:trip_id/stops
        # Retrieves the stops for a specific trip based on the provided parameters.
        r.on 'stops' do
          r.get(params!: STOP_PARAMS) do |departure_stop_name, service_id, datetime|
            # Retrieves the stops for a specific trip based on the provided parameters.
            # @param departure_stop_name [String] Name of the departure stop.
            # @param service_id [String] Service ID of the trip.
            # @param datetime [String] Date and time of the trip.
            # @param id [Integer] The ID of the trip.
            # @return [String] A JSON formatted response containing stops information or an error message.
            validation_result = Routes::API::V2::Trips.validate_params(departure_stop_name, service_id, datetime)

            if validation_result.success?
              result = Routes::API::V2::Trips.handle_stops_request(id, departure_stop_name, service_id, datetime)
              result ? APIResponse.success(response, result) : APIResponse.error(response, 'No stops found', 404)
            else
              error_messages = validation_result.errors.to_h
              APIResponse.error(response, error_messages, 400)
            end
          end
        end
      end
    end
  end

  # Validates the input parameters using a defined contract.
  # @param departure_stop_name [String] Name of the departure stop.
  # @param service_id [String] Service ID of the trip.
  # @param datetime [String] Date and time of the trip.
  # @return [Dry::Validation::Result] The result of the validation.
  def self.validate_params(departure_stop_name, service_id, datetime)
    contract = Validations::TripsValidation::TripContract.new
    contract.call(departure_stop_name:, service_id:, datetime:)
  end

  # Handles the request for stops on a specific trip.
  # Retrieves the requested information from the database based on input parameters.
  # @param id [Integer] The trip ID.
  # @param departure_stop_name [String] Name of the departure stop.
  # @param service_id [String] Service ID of the trip.
  # @param datetime [String] Date and time of the trip.
  # @return [Array<Hash>, Hash] An array of stop information for the trip or an error message if validation fails.
  def self.handle_stops_request(id, departure_stop_name, service_id, datetime)

    stop_ids = Application['database'][:stops]
      .where(stop_name: departure_stop_name)
      .select_map(:stop_id)

    consec = Application['database'][:stop_times]
      .where(trip_id: id.to_s, stop_id: stop_ids)
      .select_map(:stop_sequence_consec)

    return nil if consec.empty?

    from_date = DateTime.parse(datetime)
    to_date = from_date + 1

    Application['database'][:connections]
      .where(
        trip_id: id.to_s,
        t_departure: from_date..to_date,
        from_stop_sequence_consec: consec..,
        service_id: service_id
      )
      .select(
        :to_stop_headsign, :from_stop_id, :from_stop_name, :t_departure,
        :from_stop_sequence, :from_stop_sequence_consec, :to_stop_sequence,
        :to_stop_sequence_consec, :t_arrival, :to_stop_id, :to_stop_name
      )
      .order(:t_departure, :from_stop_sequence_consec)
      .to_a
  end
end
