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

      def search_by_name_no_cluster(s_name)
        where(name: s_name, cluster_id: nil)
          .select_map(:stop_id)
      end

      def search_stops_id_by_cluster_id(cid)
        where(cluster_id: cid)
          .select_map(:stop_id)
      end

      def search_location_by_name(s_name)
        where(name: s_name)
          .select_map(%i[lat lon])
      end
    end

    def self.give_all_stops_no_cluster
      all_stops_no_cluster
    end

    def self.search_stop_id_by_name(name)
      search_by_name_no_cluster(name).first
    end

    def self.search_stops_id_by_cid(cid)
      search_stops_id_by_cluster_id(cid).to_a
    end

    def self.search_location_in_stops_by_name(name)
      search_location_by_name(name).first
    end
  end
end
