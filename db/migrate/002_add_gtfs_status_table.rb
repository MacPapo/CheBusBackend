# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :gtfs_status do
      primary_key      :id

      foreign_key      :agency_id, :agencies,              null: false
      String           :url,                               null: false
      String           :category,                          null: false
      Timestamp        :created_at,                        null: false
      Timestamp        :updated_at,                        null: false

      check(category: %w[BUS FERRY])

      index :agency_id
      index :category
    end
  end
end
