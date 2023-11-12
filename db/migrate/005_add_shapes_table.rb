# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:shapes) do
      primary_key :id
      String      :shape_id
      Integer     :shape_pt_sequence
      column      :shape_pt_loc, 'geography(POINT, 4326)'
      Float       :shape_dist_traveled

      index :shape_id
      index %i[shape_id shape_pt_sequence]
    end
  end
end
