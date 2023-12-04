# frozen_string_literal: true

module Models
  # Agencies table
  class Agency < Sequel::Model
    one_to_many :gtfs_status, key: :agency_id
  end
end
