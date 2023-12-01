# frozen_string_literal: true

module Jobs
  # Sas
  class ImportActv
    include Models

    def self.perform
      aut_gtfs_source = build_gtfs 'https://actv.avmspa.it/sites/default/files/attachments/opendata/automobilistico/actv_aut.zip'
      nav_gtfs_source = build_gtfs 'https://actv.avmspa.it/sites/default/files/attachments/opendata/navigazione/actv_nav.zip'

      Application['database'].transaction do
        puts 'Deleting Stops...'
        clean_data
        puts 'Done.'

        puts 'Adding Stops...'
        import_stops(aut_gtfs_source.stops, 'BUS')
        import_stops(nav_gtfs_source.stops, 'FERRY')
        puts 'Done.'
      end
    end

    def self.clean_data
      if Application['database'].table_exists? :stops
        Models::Stops.delete
      else
        Application['database'].create_table :stops do
          Integer                   :stop_id
          String                    :stop_code
          String                    :stop_name
          Float                     :stop_lat
          Float                     :stop_lon
          String                    :stop_category
          String                    :parent_station
        end
      end
    end

    def self.build_gtfs(url)
      GTFS::Source.build(url)
    end

    def self.import_stops(data, category)
      mapped_stops = data.flat_map do |stop|
        {
          stop_id: stop.id.to_i,
          stop_code: stop.code,
          stop_name: stop.name,
          stop_lat: stop.lat.to_f,
          stop_lon: stop.lon.to_f,
          stop_category: category,
          parent_station: stop.parent_station
        }
      end
      Models::Stop.multi_insert(mapped_stops)
    end
  end
end
