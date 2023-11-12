# frozen_string_literal: true

Sequel.migration do
  change do
    drop_enum(:wheelchair_accessibility, if_exists: true)
    # unknown         -- 0 or empty - No accessibility information for the trip.
    # accessible      -- 1          – Vehicle being used on this particular trip can accommodate at least one rider in a wheelchair.
    # not_accessible  -- 2          – No riders in wheelchairs can be accommodated on this trip.
    create_enum(:wheelchair_accessibility, %w[unknown accessible not_accessible])

    drop_enum(:bikes_allowance, if_exists: true)
    # unknown      -- 0 or empty - No bike information for the trip.
    # allowed      -- 1          – Vehicle being used on this particular trip can accommodate at least one bicycle.
    # not_allowed  -- 2          – No bicycles are allowed on this trip.
    create_enum(:bikes_allowance, %w[unknown allowed not_allowed])

    create_table(:trips) do
      String                   :trip_id,                primary_key: true
      String                   :route_id,               null: false
      String                   :service_id,             null: false
      String                   :trip_headsign
      String                   :trip_short_name
      Integer                  :direction_id,           null: false
      String                   :block_id,               null: false
      String                   :shape_id,               null: false

      wheelchair_accessibility :wheelchair_accessible
      bikes_allowance          :bikes_allowed

      index :route_id
      index :service_id
      index :shape_id
      index :trip_headsign
    end
  end
end
