# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:stops) do
      primary_key      :id

      Integer          :stop_id
      String           :stop_code
      String           :stop_name
      Float            :stop_lat
      Float            :stop_lon
      String           :stop_category
      String           :parent_station

      index :stop_id
      index :stop_name
      index :stop_lat
      index :stop_lon
      index :stop_category
      index :parent_station
    end
  end
end
