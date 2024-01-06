# frozen_string_literal: true

module Models
  # Category table
  class Category < Sequel::Model
    one_to_many :gtfs_status, key: :category

    def self.find_id_by_name(name)
      res = Category.where(name:).select(:id).first
      res.nil? ? nil : res[:id]
    end
  end
end
