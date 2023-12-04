# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:agencies) do
      primary_key      :id

      String           :agency_id,       null: false
      String           :agency_name,     null: false

      index :agency_id
      index :agency_name
    end
  end
end
