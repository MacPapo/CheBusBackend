# frozen_string_literal: true

module Models
  # The Stop class represents a physical location where vehicles pick up or drop off
  # passengers in a public transportation system. It is linked to specific times at
  # which vehicles will be at this stop.
  #
  # @!attribute [r] stop_id
  #   @return [String] the unique identifier for the stop
  #
  # @!attribute [r] stop_code
  #   @return [String] a short text code that uniquely identifies the stop within a certain area
  #
  # @!attribute [r] stop_name
  #   @return [String] the name of the stop
  #
  # @!attribute [r] stop_desc
  #   @return [String] a description of the stop
  #
  # @!attribute [r] stop_loc
  #   @return [Geography] the geographic location of the stop (latitude and longitude)
  #
  # @!attribute [r] zone_id
  #   @return [String] the identifier of the fare zone for this stop
  #
  # @!attribute [r] stop_url
  #   @return [String] the URL providing more information about the stop
  #
  # @!attribute [r] location_type
  #   @return [String] the type of location (e.g., station, stop)
  #
  # @!attribute [r] parent_station
  #   @return [String] the identifier of the parent station if this is a sub-stop
  #
  # @!attribute [r] stop_timezone
  #   @return [String] the timezone of the stop
  #
  # @!attribute [r] wheelchair_boarding
  #   @return [String] indicates the level of wheelchair accessibility at the stop
  #
  class Stop < Sequel::Model
    # Associates multiple StopTime objects with this Stop.
    # Each StopTime represents a specific time a vehicle stops here.
    # @return [Array<StopTime>] an array of StopTime objects associated with this stop
    one_to_many :stop_times, key: :stop_id
  end

  # Table: stops
  # Columns:
  #  stop_id             | text                    | PRIMARY KEY
  #  stop_code           | text                    |
  #  stop_name           | text                    |
  #  stop_desc           | text                    |
  #  stop_loc            | geography(Point,4326)   |
  #  zone_id             | text                    |
  #  stop_url            | text                    |
  #  location_type       | location_type_val       |
  #  parent_station      | text                    |
  #  stop_timezone       | text                    |
  #  wheelchair_boarding | wheelchair_boarding_val |
  # Indexes:
  #  stops_pkey            | PRIMARY KEY btree (stop_id)
  #  stops_stop_id_index   | btree (stop_id)
  #  stops_stop_loc_index  | gist (stop_loc)
  #  stops_stop_name_index | btree (stop_name)
  # Check constraints:
  #  stops_stop_timezone_check | (is_timezone(stop_timezone))
  # Referenced By:
  #  stop_times | stop_times_stop_id_fkey | (stop_id) REFERENCES stops(stop_id)
end
