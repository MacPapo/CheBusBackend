# frozen_string_literal: true

module Jobs
  class ImportPgrouting

    def self.perform
      Application['database'][:edge_table].delete if Application['database'].table_exists?(:edge_table)

      trip_map = Application["database"][:trips]
                   .where(trip_id: '173')
                   .select_map([:trip_id, :shape_id])
      trip_map.each do |trip_id, shape_id|
        stop_times = Application["database"][:stop_times].where(trip_id: trip_id).order(:stop_sequence).select_map([:stop_id, :stop_sequence])

        stop_times.each_cons(2) do |a, b|
          stop_a = Application["database"][:stops].select(:stop_id, :stop_lat, :stop_lon).where(stop_id: a[0]).first
          stop_b = Application["database"][:stops].select(:stop_id, :stop_lat, :stop_lon).where(stop_id: b[0]).first

          shape_a_pt_sequence = Application["database"][:shapes]
                      .select(:shape_pt_sequence, :shape_dist_traveled)
                      .where(shape_id: shape_id, shape_pt_lat: stop_a[:stop_lat], shape_pt_lon: stop_a[:stop_lon]).first
          shape_b_pt_sequence = Application["database"][:shapes]
                      .select(:shape_pt_sequence, :shape_dist_traveled)
                      .where(shape_id: shape_id, shape_pt_lat: stop_b[:stop_lat], shape_pt_lon: stop_b[:stop_lon]).first

          Application["database"][:edge_table].insert(
            source: stop_a[:stop_id],
            target: stop_b[:stop_id],
            cost: shape_b_pt_sequence[:shape_dist_traveled] - shape_a_pt_sequence[:shape_dist_traveled],
            reverse_cost: shape_b_pt_sequence[:shape_dist_traveled] - shape_a_pt_sequence[:shape_dist_traveled],
            x1: stop_a[:stop_lon],
            y1: stop_a[:stop_lat],
            x2: stop_b[:stop_lon],
            y2: stop_b[:stop_lat]
          )
          # shape_map = Application["database"][:shapes]
          #               .where(shape_id: shape_id, shape_pt_sequence: shape_a_pt_sequence[:shape_pt_sequence]..shape_b_pt_sequence[:shape_pt_sequence])
          #               .order(:shape_pt_sequence)
          #               .select_map([:shape_pt_lat, :shape_pt_lon, :shape_pt_sequence, :shape_dist_traveled])
          # puts "shape_map: #{shape_map}"
        end
      end
    end
  end
end
