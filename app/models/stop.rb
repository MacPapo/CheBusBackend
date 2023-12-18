# frozen_string_literal: true

module Models
  # Stops Table
  class Stop < Sequel::Model
    many_to_one :stop_clusters, key: :cluster_id
    many_to_one :categories,    key: :category

    ALL_STOPS_NO_CLUSTER =
      select(:name, :lat, :lon, :category).
      where(cluster_id: nil).
      prepare(:all, :give_all_stops_no_cluster)

    def self.give_all_stops_no_cluster()
      ALL_STOPS_NO_CLUSTER.call
    end
  end
end
