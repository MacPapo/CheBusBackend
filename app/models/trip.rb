# frozen_string_literal: true

module Models
  # The Trip class represents a journey on a route within a public transportation system.
  # It includes details about the trip and its association with a route, shape, and stop times.
  #
  # @!attribute [r] trip_id
  #   @return [String] the unique identifier for the trip
  #
  # @!attribute [r] route_id
  #   @return [String] the identifier of the route this trip is part of
  #
  # @!attribute [r] service_id
  #   @return [String] the identifier of the service schedule for this trip
  #
  # @!attribute [r] trip_headsign
  #   @return [String, nil] the text that appears on a sign that identifies the trip's destination
  #
  # @!attribute [r] trip_short_name
  #   @return [String, nil] the short name of the trip
  #
  # @!attribute [r] direction_id
  #   @return [Integer] the direction in which the trip travels (e.g., north, south)
  #
  # @!attribute [r] block_id
  #   @return [String] the identifier of the block this trip is a part of
  #
  # @!attribute [r] shape_id
  #   @return [String] the identifier of the shape describing the path of this trip
  #
  # @!attribute [r] wheelchair_accessible
  #   @return [String, nil] indicates the level of wheelchair accessibility for the trip
  #
  # @!attribute [r] bikes_allowed
  #   @return [String, nil] indicates whether bikes are allowed on the trip
  #
  class Trip < Sequel::Model
    # Associates this Trip with a Shape.
    # @return [Shape] the Shape object describing the path of this trip
    many_to_one :shape, key: :shape_id

    # Associates this Trip with a Route.
    # @return [Route] the Route object this trip is part of
    many_to_one :route, key: :route_id

    # Associates multiple StopTime objects with this Trip.
    # Each StopTime represents a specific time a vehicle stops on this trip.
    # @return [Array<StopTime>] an array of StopTime objects associated with this trip
    one_to_many :stop_times, key: :trip_id
  end

  # Table: trips
  # Columns:
  #  trip_id               | text                     | PRIMARY KEY
  #  route_id              | text                     | NOT NULL
  #  service_id            | text                     | NOT NULL
  #  trip_headsign         | text                     |
  #  trip_short_name       | text                     |
  #  direction_id          | integer                  | NOT NULL
  #  block_id              | text                     | NOT NULL
  #  shape_id              | text                     | NOT NULL
  #  wheelchair_accessible | wheelchair_accessibility |
  #  bikes_allowed         | bikes_allowance          |
  # Indexes:
  #  trips_pkey                | PRIMARY KEY btree (trip_id)
  #  trips_route_id_index      | btree (route_id)
  #  trips_service_id_index    | btree (service_id)
  #  trips_shape_id_index      | btree (shape_id)
  #  trips_trip_headsign_index | btree (trip_headsign)
  # Foreign key constraints:
  #  trips_route_id_fkey | (route_id) REFERENCES routes(route_id)
  # Referenced By:
  #  frequencies | frequencies_trip_id_fkey | (trip_id) REFERENCES trips(trip_id)
  #  stop_times  | stop_times_trip_id_fkey  | (trip_id) REFERENCES trips(trip_id)
end
