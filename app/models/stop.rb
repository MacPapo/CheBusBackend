# frozen_string_literal: true

module Models
  # Stops Table
  class Stop < Sequel::Model
    many_to_one :stop_clusters, key: :cluster_id

    ALL_STOPS_NO_CLUSTER =
      select(:stop_name, :stop_lat, :stop_lon).
      where(cluster_id: nil).
      prepare(:all, :give_all_stops_no_cluster)

    def self.give_all_stops_no_cluster()
      ALL_STOPS_NO_CLUSTER.call
    end
  end
end
