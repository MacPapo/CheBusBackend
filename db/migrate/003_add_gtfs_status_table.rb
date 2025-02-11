# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :gtfs_statuses do
      primary_key      :id

      foreign_key      :agency_id, :agencies,              null: false
      foreign_key      :category,  :categories,            null: false

      String           :url,                               null: false
      String           :created_at,                        null: false
      String           :updated_at,                        null: false

      index :agency_id
      index :category
      index :url
      index :created_at
      index :updated_at
    end
  end
end
