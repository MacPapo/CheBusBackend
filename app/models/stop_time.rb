# frozen_string_literal: true

module Models
  # The StopTime class represents the times at which a vehicle arrives at and departs from
  # individual stops for a specific trip in a public transportation system. It links
  # the timing information to both the Trip and the Stop.
  #
  # @!attribute [r] trip_id
  #   @return [String] the identifier of the trip this stop time is associated with
  #
  # @!attribute [r] stop_id
  #   @return [String] the identifier of the stop this stop time is for
  #
  # @!attribute [r] arrival_time
  #   @return [Interval] the time at which a vehicle arrives at the stop
  #
  # @!attribute [r] departure_time
  #   @return [Interval] the time at which a vehicle departs from the stop
  #
  # @!attribute [r] stop_sequence
  #   @return [Integer] the sequence number of the stop for a particular trip
  #
  # @!attribute [r] stop_sequence_consec
  #   @return [Integer, nil] a consecutive sequence number for stops within a trip
  #
  # @!attribute [r] stop_headsign
  #   @return [String, nil] the text that appears on a sign that identifies the trip's destination
  #
  # @!attribute [r] pickup_type
  #   @return [String] the type of pickup service available at the stop
  #
  # @!attribute [r] drop_off_type
  #   @return [String] the type of drop-off service available at the stop
  #
  # @!attribute [r] shape_dist_traveled
  #   @return [Float, nil] the distance traveled along the shape from the start of the trip
  #
  # @!attribute [r] timepoint
  #   @return [String, nil] indicates if the stop time is an exact time or an estimate
  #
  class StopTime < Sequel::Model
    # Associates this StopTime with a Trip.
    # @return [Trip] the Trip object this stop time is associated with
    many_to_one :trip, key: :trip_id

    # Associates this StopTime with a Stop.
    # @return [Stop] the Stop object this stop time is for
    many_to_one :stop, key: :stop_id
  end

  # Table: stop_times
  # Columns:
  #  trip_id              | text                 | NOT NULL
  #  stop_id              | text                 | NOT NULL
  #  arrival_time         | interval             |
  #  departure_time       | interval             |
  #  stop_sequence        | integer              | NOT NULL
  #  stop_sequence_consec | integer              |
  #  stop_headsign        | text                 |
  #  pickup_type          | pickup_drop_off_type |
  #  drop_off_type        | pickup_drop_off_type |
  #  shape_dist_traveled  | double precision     |
  #  timepoint            | timepoint_v          |
  # Indexes:
  #  stop_times_arrival_time_index                 | btree (arrival_time)
  #  stop_times_departure_time_index               | btree (departure_time)
  #  stop_times_stop_id_index                      | btree (stop_id)
  #  stop_times_stop_sequence_consec_index         | btree (stop_sequence_consec)
  #  stop_times_trip_id_index                      | btree (trip_id)
  #  stop_times_trip_id_stop_sequence_consec_index | btree (trip_id, stop_sequence_consec)
  # Foreign key constraints:
  #  stop_times_stop_id_fkey | (stop_id) REFERENCES stops(stop_id)
  #  stop_times_trip_id_fkey | (trip_id) REFERENCES trips(trip_id)
end
