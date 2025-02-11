# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:categories) do
      primary_key      :id

      String           :name,       null: false

      index :id
      index :name
    end
  end
end
