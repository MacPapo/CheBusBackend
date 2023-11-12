# frozen_string_literal: true

module Models
  # The Route class represents a specific route in a public transportation system.
  # It defines the details of a route and is associated with an agency and multiple trips.
  #
  # @!attribute [r] route_id
  #   @return [String] the unique identifier of the route
  #
  # @!attribute [r] agency_id
  #   @return [String] the identifier of the agency that operates this route
  #
  # @!attribute [r] route_short_name
  #   @return [String] the short name of the route
  #
  # @!attribute [r] route_long_name
  #   @return [String] the long name of the route
  #
  # @!attribute [r] route_desc
  #   @return [String] the description of the route
  #
  # @!attribute [r] route_type
  #   @return [String] the type of route (e.g., bus, train)
  #
  # @!attribute [r] route_url
  #   @return [String] the URL providing more information about the route
  #
  # @!attribute [r] route_color
  #   @return [String] the color representing the route, in hexadecimal format
  #
  # @!attribute [r] route_text_color
  #   @return [String] the text color for the route, in hexadecimal format
  #
  # @!attribute [r] route_sort_order
  #   @return [Integer] the order in which the route is sorted
  #
  class Route < Sequel::Model
    # Associates this Route with an Agency.
    # @return [Agency] the Agency object that operates this route
    many_to_one :agency, key: :agency_id

    # Associates multiple Trip objects with this Route.
    # Each Trip represents a specific journey on this route.
    # @return [Array<Trip>] an array of Trip objects that operate on this route
    one_to_many :trips, key: :route_id
  end

  # Table: routes
  # Columns:
  #  route_id         | text                 | PRIMARY KEY
  #  agency_id        | text                 | NOT NULL
  #  route_short_name | text                 |
  #  route_long_name  | text                 |
  #  route_desc       | text                 |
  #  route_type       | route_type_val       | NOT NULL
  #  route_url        | text                 |
  #  route_color      | character varying(6) | DEFAULT 'FFFFFF'::character varying
  #  route_text_color | character varying(6) | DEFAULT '000000'::character varying
  #  route_sort_order | integer              |
  # Indexes:
  #  routes_pkey                   | PRIMARY KEY btree (route_id)
  #  routes_agency_id_index        | btree (agency_id)
  #  routes_route_short_name_index | btree (route_short_name)
  # Foreign key constraints:
  #  routes_agency_id_fkey | (agency_id) REFERENCES agencies(agency_id)
  # Referenced By:
  #  trips | trips_route_id_fkey | (route_id) REFERENCES routes(route_id)
end
