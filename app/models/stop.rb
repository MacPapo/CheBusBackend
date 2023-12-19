# frozen_string_literal: true

module Models
  # Stops Table
  class Stop < Sequel::Model
    many_to_one :stop_clusters, key: :cluster_id
    many_to_one :categories,    key: :category

    dataset_module do
      def all_stops_no_cluster
          join(:categories, id: :category)
          .where(cluster_id: nil)
          .select_map([Sequel[:stops][:name], :lat, :lon, Sequel[:categories][:name].as(:category)])
      end
    end

    def self.give_all_stops_no_cluster
      all_stops_no_cluster
    end
  end
end
