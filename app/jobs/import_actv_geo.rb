# frozen_string_literal: true

require 'down'
require 'tempfile'
require 'open4'

module Jobs
  # SAS
  class ImportActvGeo
    def self.perform
      # Inizia una transazione
      Application['database'].transaction do
        tables = %I[stop_times trips routes agency shapes shapes_geom calendar calendar_dates stops]

        tables.each do |table|
          print "Tring to drop table #{table}... "
          if Application['database'].table_exists?(table)
            Application['database'].drop_table(table, cascade: true)
            puts 'DONE'
          else
            puts 'NOT FOUND'
          end
        end
      end

      Application['database'].transaction do
        # URL del file zip da scaricare
        url = 'https://actv.avmspa.it/sites/default/files/attachments/opendata/automobilistico/actv_aut.zip'

        Tempfile.create(['tempfile', '.zip']) do |tempfile|
          # Scarica il file zip e scrivilo nel file temporaneo
          print 'Downloading latest version of the archive... '
          Down.download(url, destination: tempfile.path)
          puts 'DONE'

          # Costruisci il comando ogr2ogr con il percorso del file temporaneo
          puts 'Executing ogr2ogr... '
          ogr2ogr_command =
            "ogr2ogr -f \"PostgreSQL\" PG:\"dbname=#{ENV.fetch('DATABASE_NAME')} user=#{ENV.fetch('DATABASE_USER')}\" \"#{tempfile.path}\""

          # Esegui il comando ogr2ogr
          status = Open4::popen4(ogr2ogr_command) do |_pid, _stdin, stdout, stderr|
            puts "Output: #{stdout.read}"
            puts "Error: #{stderr.read}"
          end
          raise "Errore nell'esecuzione del comando ogr2ogr" if status.exitstatus != 0

          Application['database'].add_index :trips, :trip_id
          Application['database'].add_index :stop_times, :trip_id
          Application['database'].add_index :stop_times, :stop_sequence
          Application['database'].add_index :stops, :stop_id
          Application['database'].add_index :shapes, %i[shape_id wkb_geometry]
          Application['database'].add_index :shapes, :shape_pt_sequence
          Application['database'].add_index :routes, :route_id

          puts '===END OF IMPORT==='
        end
      end
    end
  end
end
