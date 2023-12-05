# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:stop_clusters) do
      primary_key      :id

      Integer          :cluster_name,        null: false
      Float            :cluster_lat,       null: false
      Float            :cluster_lon,       null: false

      index :id
      index :cluster_name
      index :cluster_lat
      index :cluster_lon
    end
  end
end
