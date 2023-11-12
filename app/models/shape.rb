# frozen_string_literal: true

module Models
  # The Shape class represents the physical path that a vehicle takes for a specific route
  # in a public transportation system. It is associated with geographic points and is linked
  # to one or more trips.
  #
  # @!attribute [r] id
  #   @return [Integer] the primary key identifier for each shape entry
  #
  # @!attribute [r] shape_id
  #   @return [String] an identifier for a set of shape entries that describe a path
  #
  # @!attribute [r] shape_pt_sequence
  #   @return [Integer] the sequence in which shape points are traveled for a trip
  #
  # @!attribute [r] shape_pt_loc
  #   @return [Geography] the geographic location of the shape point (latitude and longitude)
  #
  # @!attribute [r] shape_dist_traveled
  #   @return [Float] the cumulative distance traveled along the path to this point
  #
  class Shape < Sequel::Model
    # Associates multiple Trip objects with this Shape.
    # Each Trip represents a journey that follows the path described by this Shape.
    # @return [Array<Trip>] an array of Trip objects that follow this shape
    one_to_many :trips, key: :shape_id
  end

  # Table: shapes
  # Columns:
  #  id                  | integer               | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
  #  shape_id            | text                  |
  #  shape_pt_sequence   | integer               |
  #  shape_pt_loc        | geography(Point,4326) |
  #  shape_dist_traveled | double precision      |
  # Indexes:
  #  shapes_pkey                             | PRIMARY KEY btree (id)
  #  shapes_shape_id_index                   | btree (shape_id)
  #  shapes_shape_id_shape_pt_sequence_index | btree (shape_id, shape_pt_sequence)
end
