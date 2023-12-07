# frozen_string_literal: true

require 'gtfs_stops_clustering'

module Jobs
  include Models

  # Clustering
  class ImportStopClusters
    FILE_CONFIG_NAME = 'app/config/stops_config.txt'
    GTFS_PATH = 'otp/current'

    def self.perform
      Application['database'].transaction do
        puts 'Deleting StopClusters...'
        clean_data
        puts 'Done.'
      end

      puts 'Adding StopClusters...'
      import_stop_clusters
      puts 'Done.'
    end

    def self.clean_data
      if (Application['database'].table_exists? :stops) && (Application['database'].table_exists? :stop_clusters)
        Application['database'][:stops].delete
        Application['database'][:stop_clusters].delete
      else
        unless Application['database'].table_exists?(:stop_clusters)
          Application['database'].create_table :stop_clusters do
            Integer :id, primary_key: true
            String :cluster_name
            Float :cluster_lat
            Float :cluster_lon
          end
        end

        unless Application['database'].table_exists?(:stops)
          Application['database'].create_table :stops do
            Integer :id, primary_key: true
            Integer :stop_id
            String :stop_code
            String :stop_name
            Float :stop_lat
            Float :stop_lon
            String :stop_category
            String :parent_station
            foreign_key :cluster_id, :stop_clusters, key: :id, null: true
          end
        end
      end
    end

    def self.import_stop_clusters
      zip_files = []
      stops = []

      Dir.glob(File.join(GTFS_PATH, '*.gtfs.zip')).each do |zip_file|
        stops << GTFS::Source.build(zip_file).stops.to_a
        zip_files << zip_file
      end

      clusters = GtfsStopsClustering.build(zip_files, 0.3, 1, 0.85, FILE_CONFIG_NAME)

      stops_list = []
      stop_clusters_list = []

      clusters.each do |cluster_id, cluster|
        next if cluster.first.nil? || cluster_id == -1

        stop_clusters_list.push(Models::StopCluster.new(
                                  cluster_name: cluster.first[:cluster_name],
                                  cluster_lat: cluster.first[:cluster_pos][0],
                                  cluster_lon: cluster.first[:cluster_pos][1]
                                ))
      end

      Application['database'].transaction do
        Models::StopCluster.multi_insert(stop_clusters_list)
      end

      clusters.first.each do |stops_array|
        next if stops_array == -1

        stops_array.each do |stop|
          stops_list.push(Models::Stop.new(
                            stop_id: stop[:stop_id],
                            stop_code: stop[:stop_code],
                            stop_name: stop[:stop_name],
                            stop_lat: stop[:stop_lat],
                            stop_lon: stop[:stop_lon],
                            stop_category: 'Test',
                            parent_station: stop[:parent_station],
                            cluster_id: nil
                          ))
        end
      end

      clusters.each do |cluster_id, cluster|
        next if cluster_id == -1

        cluster.each do |stop|
          stops_list.push(Models::Stop.new(
                            stop_id: stop[:stop_id].to_i,
                            stop_code: stop[:stop_code],
                            stop_name: stop[:stop_name],
                            stop_lat: stop[:stop_lat],
                            stop_lon: stop[:stop_lon],
                            stop_category: 'Test',
                            parent_station: stop[:parent_station],
                            cluster_id: Models::StopCluster.where(cluster_lat: stop[:cluster_pos][0], cluster_lon: stop[:cluster_pos][1]).first.id
                          ))
        end
      end

      Application['database'].transaction do
        Models::Stop.multi_insert(stops_list)
      end
    end
  end
end
