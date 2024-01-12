# frozen_string_literal: true

module Helpers::ValidatorHelper
  DATETIME_REGEXP = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\z/
  STOPNAME_REGEXP = /^[A-Za-z0-9'.\- ]+(?:\s+[A-Za-z0-9'.\- ]+)*$/

  MIN_LAT = 45.0
  MAX_LAT = 45.7

  MIN_LON = 11.7
  MAX_LON = 12.5

  STOPNAME_ERROR = 'must be a valid stop name format'
  INTERVAL_ERROR = 'must be between 30 minutes and 2 hours'
  DATETIME_ERROR = 'datetime must be from today or from the current year'
  LATITUDE_ERROR = 'must be a valid latitude or a 0 value'
  LONGITUDE_ERROR = 'must be a valid longitude or a 0 value'
  INVALID_DATETIME_ERROR = 'must be a valid datetime'

  def self.stop_names_regex(stop_name)
    stop_name.match?(STOPNAME_REGEXP)
  end

  def self.datetime_range(datetime)
    datetime.between?(Helpers::TimeHelper.today, Helpers::TimeHelper.months_from_now(1))
  end

  def self.interval_range(interval)
    interval.between?(30, 120)
  end

  def self.latitude_in_range(lat)
    lat.between?(MIN_LAT, MAX_LAT) || lat.zero?
  end

  def self.longitude_in_range(lon)
    lon.between?(MIN_LON, MAX_LON) || lon.zero?
  end

  def self.valid_date?(date)
    Helpers::TimeHelper.to_date(date)
  rescue StandardError
    false
  end
end
