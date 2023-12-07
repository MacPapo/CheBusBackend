# frozen_string_literal: true

module Models
  # Stops Table
  class StopCluster < Sequel::Model
    one_to_many :stops, key: :id

    ALL_STOPS_CLUSTER =
      select(:cluster_name, :cluster_lat, :cluster_lon).
      prepare(:all, :give_all_stops_cluster)

    def self.give_all_stops_cluster()
      ALL_STOPS_CLUSTER.call
    end
  end
end
