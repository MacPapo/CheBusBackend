# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:stops) do
      primary_key      :id

      Integer          :stop_id,                              null: false
      String           :stop_code
      String           :name,                                 null: false
      Float            :lat,                                  null: false
      Float            :lon,                                  null: false
      String           :parent_station

      foreign_key      :category,   :categories,              null: false
      foreign_key      :cluster_id, :stop_clusters, key: :id

      index :stop_id
      index :name
      index :lat
      index :lon
      index :category
      index :parent_station
      index :cluster_id
    end
  end
end
