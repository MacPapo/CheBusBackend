# frozen_string_literal: true

module Helpers::TimeHelper
  def self.unix_converter(unix_time)
    Time.at(unix_time / 1000).strftime('%FT%H:%M:%S')
  end

  def self.sec_til_mid(secs)
    arrival_time = Date.today.to_time + secs.seconds
    arrival_time.strftime('%FT%H:%M:%S')
  end
end
