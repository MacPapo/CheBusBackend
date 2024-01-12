# frozen_string_literal: true

module Helpers::TimeHelper
  TIMEZONE = 'Europe/Rome'

  def self.today
    Date.today.in_time_zone(TIMEZONE)
  end

  def self.to_date(date)
    date.to_time.in_time_zone(TIMEZONE)
  end

  def self.months_from_now(num)
    num.months.from_now.in_time_zone(TIMEZONE)
  end

  def self.from_unix_to_formatted_date(unix_time_str)
    Time.at(unix_time_str / 1000).in_time_zone(TIMEZONE).strftime('%FT%H:%M:%S')
  end

  def self.from_date_to_unix_str(datetime)
    datetime.in_time_zone(TIMEZONE).to_time.to_i
  end

  def self.min_in_sec(min)
    min.to_i.minutes.in_seconds
  end

  def self.sec_in_min(sec)
    sec.to_i.seconds.in_minutes
  end

  def self.sec_til_mid(secs)
    arrival_time = Date.today.to_time + secs.to_i.seconds
    arrival_time.strftime('%H:%M')
  end

  def self.split_date_and_time(datetime_str)
    date, time = datetime_str.split('T')
    [date, time]
  end
end
