# frozen_string_literal: true

module Models
  # The CalendarDate class represents specific dates for public transport services,
  # including exceptions to the regular schedule defined in the Calendar class.
  #
  # @!attribute [r] service_id
  #   @return [String] the ID of the service schedule this date is associated with
  #
  # @!attribute [r] date
  #   @return [Date] the specific date for the service exception
  #
  # @!attribute [r] exception_type
  #   @return [String] the type of exception for this date (e.g., service added, service removed)
  #
  class CalendarDate < Sequel::Model
    # Associates this CalendarDate object with a Calendar object.
    # A Calendar object represents a regular schedule, and CalendarDate represents exceptions to it.
    # @return [Calendar] the Calendar object this date is associated with
    many_to_one :calendar, key: :service_id
  end

  # Table: calendar_dates
  # Primary Key: (service_id, date)
  # Columns:
  #  service_id     | text             |
  #  date           | date             |
  #  exception_type | exception_type_v | NOT NULL
  # Indexes:
  #  calendar_dates_pkey                 | PRIMARY KEY btree (service_id, date)
  #  calendar_dates_exception_type_index | btree (exception_type)
  #  calendar_dates_service_id_index     | btree (service_id)
end
