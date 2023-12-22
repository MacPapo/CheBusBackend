# frozen_string_literal: true

require 'gtfs_stops_clustering'

include GtfsStopsClustering

module Jobs
  include Models

  # Clustering
  class ImportStopClusters
    FILE_CONFIG_NAME = 'stops_config.txt'
    FILE_DUPLICATED_STOPS_NAME = 'duplicated_stops.txt'
    GTFS_PATH = 'otp/current'

    def self.perform
      fprint = ->(str) { printf('%-40s', str) }
      Application['database'].transaction do
        fprint.call('Deleting StopClusters')
        clean_data
        puts 'DONE'
      end

      fprint.call('Adding StopClusters')
      import_stop_clusters
      puts 'DONE'
    end

    def self.clean_data
      return unless (Application['database'].table_exists? :stops) && (Application['database'].table_exists? :stop_clusters)

      Application['database'][:stops].delete
      Application['database'][:stop_clusters].delete
    end

    def self.import_duplicated_stops
      duplicated_stops = []
      CSV.foreach(FILE_DUPLICATED_STOPS_NAME, headers: true) do |row|
        stop_id = row['stop_id']
        duplicated_stops << { stop_id: }
      end

      duplicated_stops
    end

    def self.import_zip
      stops_data = []
      zip_files  = []

      Dir.glob(File.join(GTFS_PATH, '*.gtfs.zip')).each do |zip_file|
        category = File.basename(zip_file).split('_').first.to_s
        stops_data << GTFS::Source.build(zip_file).stops.to_a.map do |stop|
          {
            stop_id: stop.id,
            stop_code: stop.code,
            stop_name: stop.name,
            stop_lat: stop.lat,
            stop_lon: stop.lon,
            category: Models::Category.find_id_by_name(category.upcase),
            parent_station: stop.parent_station
          }
        end
        zip_files << zip_file
      end

      [stops_data.flatten, zip_files]
    end

    def self.import_stop_clusters
      stops_data, zip_files = self.import_zip

      clusters = build_clusters(zip_files, 0.3, 1, 0.85, FILE_CONFIG_NAME)

      stop_clusters_list = []
      stops_list = []

      find_by_stop_id = ->(id) { stops_data.find { |stop| stop[:stop_id] == id }[:category] }

      duplicated_stops = import_duplicated_stops
      duplicated_stops.each do |duplicated_stop|
        clusters.first[1].reject! { |stop| stop[:stop_id] == duplicated_stop[:stop_id] }
      end

      # Creazione degli oggetti StopCluster
      clusters.each do |cluster_id, cluster|
        next if cluster_id == -1 || cluster.first.nil?

        stop_clusters_list.push(
          Models::StopCluster.new(
            name: cluster.first[:cluster_name],
            lat: cluster.first[:cluster_pos][0],
            lon: cluster.first[:cluster_pos][1],
            category: find_by_stop_id.call(cluster.first[:stop_id])
          )
        )
      end

      Application['database'].transaction do
        Models::StopCluster.multi_insert(stop_clusters_list)
      end

      find_cluster_id = ->(lat, lon) { Models::StopCluster.where(lat:, lon:).first.id }

      clusters.first.each do |stops_array|
        next if stops_array == -1

        stops_array.each do |stop|
          stops_list.push(
            Models::Stop.new(
              stop_id: stop[:stop_id],
              stop_code: stop[:stop_code],
              name: stop[:stop_name],
              lat: stop[:stop_lat],
              lon: stop[:stop_lon],
              category: find_by_stop_id.call(stop[:stop_id]),
              parent_station: stop[:parent_station],
              cluster_id: nil
            )
          )
        end
      end

      clusters.each do |cluster_id, cluster|
        next if cluster_id == -1
        
        cluster.each do |stop|
          stops_list.push(
            Models::Stop.new(
              stop_id: stop[:stop_id].to_i,
              stop_code: stop[:stop_code],
              name: stop[:stop_name],
              lat: stop[:stop_lat],
              lon: stop[:stop_lon],
              category: find_by_stop_id.call(stop[:stop_id]),
              parent_station: stop[:parent_station],
              cluster_id: find_cluster_id.call(stop[:cluster_pos][0], stop[:cluster_pos][1])
            )
          )
        end
      end

      Application['database'].transaction do
        Models::Stop.multi_insert(stops_list)
      end
    end
  end
end
