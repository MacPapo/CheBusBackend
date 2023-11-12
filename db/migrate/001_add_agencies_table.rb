# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :agencies do
      String   :agency_id,       primary_key: true
      String   :agency_name,     null: false
      String   :agency_url,      null: false
      String   :agency_timezone, null: false
      String   :agency_lang
      String   :agency_phone
      String   :agency_fare_url
      String   :agency_email

      check { Sequel.function(:is_timezone, :agency_timezone) }
    end
  end
end
