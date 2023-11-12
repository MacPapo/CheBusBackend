# frozen_string_literal: true

Sequel.migration do
  change do
    drop_enum(:pickup_drop_off_type, if_exists: true)

    # regular       -- 0 or empty - Regularly scheduled pickup/dropoff.
    # not_available -- 1          – No pickup/dropoff available.
    # call          -- 2          – Must phone agency to arrange pickup/dropoff.
    # driver        -- 3          – Must coordinate with driver to arrange pickup/dropoff.
    create_enum(:pickup_drop_off_type, %w[regular not_available call driver])

    drop_enum(:timepoint_v, if_exists: true)

    # approximate  -- 0          – Times are considered approximate.
    # exact        -- 1 or empty - Times are considered exact.
    create_enum(:timepoint_v, %w[approximate exact])

    create_table(:stop_times) do
      String                :trip_id,              null: false
      String                :stop_id,              null: false

      Interval              :arrival_time
      Interval              :departure_time

      Integer               :stop_sequence, null: false
      Integer               :stop_sequence_consec
      String                :stop_headsign
      pickup_drop_off_type  :pickup_type
      pickup_drop_off_type  :drop_off_type
      Float                 :shape_dist_traveled
      timepoint_v           :timepoint

      index :trip_id
      index :stop_id

      index :stop_sequence_consec
      index %i[trip_id stop_sequence_consec]
      index :arrival_time
      index :departure_time
    end
  end
end
