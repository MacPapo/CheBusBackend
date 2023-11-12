# frozen_string_literal: true

Sequel.migration do
  change do
    drop_enum(:availability, if_exists: true)

    # not_available   -- 0  – Service is not available for Mondays in the date range.
    # available       -- 1  – Service is available for all Mondays in the date range.
    create_enum(:availability, %w[not_available available])

    create_table(:calendars) do
      String        :service_id,     null: false, primary_key: true
      availability  :monday,         null: false
      availability  :tuesday,        null: false
      availability  :wednesday,      null: false
      availability  :thursday,       null: false
      availability  :friday,         null: false
      availability  :saturday,       null: false
      availability  :sunday,         null: false
      Date          :start_date,     null: false
      Date          :end_date,       null: false
    end
  end
end
