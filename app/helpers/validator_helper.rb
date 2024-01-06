# frozen_string_literal: true

module Helpers::ValidatorHelper
  DATETIME_REGEXP = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\z/
  STOPNAME_REGEXP = /^[A-Za-z0-9'.\- ]+(?:\s+[A-Za-z0-9'.\- ]+)*$/
  ID_REGEXP = /\A[0-9]+:[0-9]+\z/

  def self.stop_names_regex(stop_name)
    stop_name.match?(STOPNAME_REGEXP)
  end

  def self.datetime_range(datetime)
    datetime.between?(Date.today, 1.months.from_now)
  end

  def self.interval_range(interval)
    interval >= 30 && interval <= 180
  end

  def self.id_regex(id)
    id.match?(ID_REGEXP)
  end

  def self.valid_date?(date)
    date.to_time
  rescue StandardError
    false
  end
end
