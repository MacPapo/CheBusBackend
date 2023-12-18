# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:stop_clusters) do
      primary_key      :id

      String           :name,                              null: false
      Float            :lat,                               null: false
      Float            :lon,                               null: false
      
      foreign_key      :category,  :categories,            null: false
      
      index :id
      index :name
      index :lat
      index :lon
      index :category
    end
  end
end
