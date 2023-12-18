# frozen_string_literal: true

module Models
  # Stops Cluster Table
  class StopCluster < Sequel::Model
    one_to_many :stops, key: :id
    many_to_one :categories, key: :category

    ALL_STOPS_CLUSTER =
      select(:name, :lat, :lon, :category).
      prepare(:all, :give_all_stops_cluster)

    def self.give_all_stops_cluster()
      ALL_STOPS_CLUSTER.call
    end
  end
end
