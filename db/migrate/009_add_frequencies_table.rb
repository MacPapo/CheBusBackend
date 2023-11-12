# frozen_string_literal: true

Sequel.migration do
  change do
    drop_enum(:exact_times_v, if_exists: true)

    # frequency_based -- 0 or empty - Frequency-based trips.
    # schedule_based  -- 1          - Schedule-based trips with the exact same headway throughout the day. In this case the end_time value must be greater than the last desired trip start_time but less than the last desired trip start_time + headway_secs.
    create_enum(:exact_times_v, %w[frequency_based schedule_based])

    create_table(:frequencies) do
      String        :trip_id,       null: false
      Interval      :start_time,    null: false
      Interval      :end_time,      null: false
      Integer       :headway_secs,  null: false
      exact_times_v :exact_times

      unique %i[trip_id start_time end_time headway_secs exact_times]

      index :trip_id
      index :exact_times
    end
  end
end
