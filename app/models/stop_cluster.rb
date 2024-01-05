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

      def search_id_by_name(s_name)
        where(name: s_name)
          .select_map(:id)
      end

      def search_location_by_name(s_name)
        where(name: s_name)
          .select_map(%i[lat lon])
      end
    end

    def self.give_all_stops_cluster
      all_stops_no_cluster
    end

    def self.search_id_in_cluster_by_name(name)
      search_id_by_name(name).first
    end

    def self.search_location_in_cluster_by_name(name)
      search_location_by_name(name).first
    end
  end
end
