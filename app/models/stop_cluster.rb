# frozen_string_literal: true

module Models
  # Stops Cluster Table
  class StopCluster < Sequel::Model
    one_to_many :stops, key: :id
    many_to_one :categories, key: :category

    dataset_module do
      def all_stops_no_cluster
        join(:categories, id: :category)
          .select_map([Sequel[:stop_clusters][:name], :lat, :lon, Sequel[:categories][:name].as(:category)])
      end

      def search_by_name(s_name)
        where(name: s_name)
          .select_map(:id)
      end
    end

    def self.give_all_stops_cluster
      all_stops_no_cluster
    end

    def self.search_in_cluster_by_name(name)
      search_by_name(name).first
    end
  end
end
