# frozen_string_literal: true

module Helpers::TimeHelper
  def self.from_unix_to_formatted_date(unix_time_str)
    Time.at(unix_time_str / 1000).strftime('%FT%H:%M:%S')
  end

  def self.from_date_to_unix_str(datetime)
    datetime.to_time.to_i
  end

  def self.min_in_sec(min)
    min.to_i.minutes.in_seconds
  end

  def self.sec_til_mid(secs)
    arrival_time = Date.today.to_time + secs.to_i.seconds
    arrival_time.strftime('%FT%H:%M:%S')
  end


  def self.split_date_and_time(datetime_str)
    date, time = datetime_str.split('T')
    [date, time]
  end

  def self.format_service_date(datetime)
    service_date = datetime.to_datetime
    service_date.strftime('%Y%m%d')
  end
end
