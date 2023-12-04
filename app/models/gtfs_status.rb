# frozen_string_literal: true

module Models
  # Gtfs_status Table
  class GtfsStatus < Sequel::Model
    plugin :timestamps, create: :created_at, update: :updated_at

    many_to_one :agencies, key: :agency_id
  end
end
