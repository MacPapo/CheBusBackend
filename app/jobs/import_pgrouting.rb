# frozen_string_literal: true

module Jobs
  class ImportPgrouting
    def self.perform
      Application['database'][:edge_table].delete if Application['database'].table_exists?(:edge_table)

      trip_map = Application['database'][:trips].select_map(%i[trip_id shape_id])

      trip_map.each do |trip_id, shape_id|
        stop_times = Application['database'][:stop_times]
                       .where(trip_id: trip_id)
                       .order(:stop_sequence)
                       .select_map([:stop_id, :stop_sequence])

        stop_times.each_cons(2) do |a, b|
          stop_a = Application['database'][:stops].select(:stop_lat, :stop_lon, :wkb_geometry).where(stop_id: a[0]).first
          stop_b = Application['database'][:stops].select(:stop_lat, :stop_lon, :wkb_geometry).where(stop_id: b[0]).first

          shape_a_pt_sequence = Application['database'][:shapes]
                      .select(:shape_pt_sequence, :shape_dist_traveled)
                      .where(shape_id: shape_id, wkb_geometry: stop_a[:wkb_geometry]).first
          shape_b_pt_sequence = Application['database'][:shapes]
                      .select(:shape_pt_sequence, :shape_dist_traveled)
                      .where(shape_id: shape_id, wkb_geometry: stop_b[:wkb_geometry]).first

          shape_map = Application['database'][:shapes]
                        .where(
                          shape_id: shape_id,
                          shape_pt_sequence: shape_a_pt_sequence[:shape_pt_sequence]..shape_b_pt_sequence[:shape_pt_sequence]
                        ).order(:shape_pt_sequence)
                        .select_map(%i[shape_pt_sequence shape_dist_traveled])

          if shape_map.any?
            distance = shape_map.last[1] - shape_map.first[1]
            buses = Application['database'][:trips]
                      .join(:routes, route_id: :route_id)
                      .where(trip_id: trip_id)
                      .select(:route_short_name)
                      .distinct
            formatted_buses = "{#{buses.join(',')}}"
            line_geometry = Sequel.lit("ST_MakeLine(ST_SetSRID(ST_MakePoint(#{stop_a[:stop_lon]}, #{stop_a[:stop_lat]}), 4326), ST_SetSRID(ST_MakePoint(#{stop_b[:stop_lon]}, #{stop_b[:stop_lat]}), 4326))")

            Application['database'][:edge_table].insert(
              source: a[0],
              target: b[0],
              cost: distance,
              reverse_cost: distance,
              x1: stop_a[:stop_lon],
              y1: stop_a[:stop_lat],
              x2: stop_b[:stop_lon],
              y2: stop_b[:stop_lat],
              buses: formatted_buses,
              the_geom: line_geometry
            )
          else
            puts "Nessun punto shape trovato tra A:#{a[0]} e B:#{b[0]}"
          end
        end
      end

      Application['database'].add_index :edge_table, :source
      Application['database'].add_index :edge_table, :target

      puts '=== FINISHED ==='
    end
  end
end
