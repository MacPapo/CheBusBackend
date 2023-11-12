# frozen_string_literal: true

Sequel.migration do
  change do
    drop_enum(:exception_type_v, if_exists: true)

    # added    -- 1  – Service has been added for the specified date.
    # removed  -- 2  – Service has been removed for the specified date.
    create_enum(:exception_type_v, %w[added removed])

    create_table(:calendar_dates) do
      primary_key      %i[service_id date]

      String           :service_id,      null: false
      Date             :date,            null: false
      exception_type_v :exception_type,  null: false

      index :service_id
      index :exception_type
    end
  end
end
