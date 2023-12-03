# frozen_string_literal: true

module Models
  # The Agency class represents a public transport agency.
  # Each agency can have multiple associated routes.
  #
  # @!attribute [r] agency_id
  #   @return [String] the unique ID of the agency
  #
  # @!attribute [r] agency_name
  #   @return [String] the name of the agency
  #
  # @!attribute [r] agency_url
  #   @return [String] the URL of the agency's website
  #
  # @!attribute [r] agency_timezone
  #   @return [String] the timezone of the agency
  #
  # @!attribute [r] agency_lang
  #   @return [String, nil] the language of the agency
  #
  # @!attribute [r] agency_phone
  #   @return [String, nil] the phone number of the agency
  #
  # @!attribute [r] agency_fare_url
  #   @return [String, nil] the URL for the agency's fare information
  #
  # @!attribute [r] agency_email
  #   @return [String, nil] the email address of the agency
  #
  class Agency < Sequel::Model
    # Associates multiple Route objects with this agency.
    # @return [Array<Route>] an array of Route objects associated with this agency
    one_to_many :gtfs_status, key: :agency_id
  end

  # Table: agencies
  # Columns:
  #  agency_id       | text | PRIMARY KEY
  #  agency_name     | text | NOT NULL
  #  agency_url      | text | NOT NULL
  #  agency_timezone | text | NOT NULL
  #  agency_lang     | text |
  #  agency_phone    | text |
  #  agency_fare_url | text |
  #  agency_email    | text |
  # Indexes:
  #  agencies_pkey | PRIMARY KEY btree (agency_id)
  # Check constraints:
  #  agencies_agency_timezone_check | (is_timezone(agency_timezone))
  # Referenced By:
  #  routes | routes_agency_id_fkey | (agency_id) REFERENCES agencies(agency_id)
end
