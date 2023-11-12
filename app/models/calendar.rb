# frozen_string_literal: true

module Models
  # The Calendar class represents a schedule for public transport services.
  # It associates specific dates with the availability of services.
  #
  # @!attribute [r] service_id
  #   @return [String] the unique ID representing a specific service schedule
  #
  # @!attribute [r] monday
  #   @return [String] availability of the service on Mondays
  #
  # @!attribute [r] tuesday
  #   @return [String] availability of the service on Tuesdays
  #
  # @!attribute [r] wednesday
  #   @return [String] availability of the service on Wednesdays
  #
  # @!attribute [r] thursday
  #   @return [String] availability of the service on Thursdays
  #
  # @!attribute [r] friday
  #   @return [String] availability of the service on Fridays
  #
  # @!attribute [r] saturday
  #   @return [String] availability of the service on Saturdays
  #
  # @!attribute [r] sunday
  #   @return [String] availability of the service on Sundays
  #
  # @!attribute [r] start_date
  #   @return [Date] the start date of the service schedule
  #
  # @!attribute [r] end_date
  #   @return [Date] the end date of the service schedule
  #
  class Calendar < Sequel::Model
    # Associates multiple CalendarDate objects with this calendar.
    # Each CalendarDate represents a specific date with an exception to the regular schedule.
    # @return [Array<CalendarDate>] an array of CalendarDate objects linked to this calendar
    one_to_many :calendar_dates, key: :service_id
  end

  # Table: calendars
  # Columns:
  #  service_id | text         | PRIMARY KEY
  #  monday     | availability | NOT NULL
  #  tuesday    | availability | NOT NULL
  #  wednesday  | availability | NOT NULL
  #  thursday   | availability | NOT NULL
  #  friday     | availability | NOT NULL
  #  saturday   | availability | NOT NULL
  #  sunday     | availability | NOT NULL
  #  start_date | date         | NOT NULL
  #  end_date   | date         | NOT NULL
  # Indexes:
  #  calendars_pkey | PRIMARY KEY btree (service_id)
end
