# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:stops) do
      primary_key      :id

      Integer          :stop_id,             null: false
      String           :stop_code
      String           :stop_name,           null: false
      Float            :stop_lat,            null: false
      Float            :stop_lon,            null: false
      String           :stop_category,       null: false
      String           :parent_station
      Integer          :cluster_id,          null: false
      foreign_key      :id, :stop_clusters,  null: false

      index :stop_id
      index :stop_name
      index :stop_lat
      index :stop_lon
      index :stop_category
      index :parent_station
      index :cluster_id
    end
  end
end
