# frozen_string_literal: true

Sequel.migration do
  change do
    drop_enum(:location_type_val, if_exists: true)
    # stop          -- 0 (or blank): Stop (or Platform). A location where passengers board or disembark from a transit vehicle. Is called a platform when defined within a parent_station.
    # station       -- 1 – Station. A physical structure or area that contains one or more platform.
    # entrance_exit -- 2 – Entrance/Exit. A location where passengers can enter or exit a station from the street. If an entrance/exit belongs to multiple stations, it can be linked by pathways to both, but the data provider must pick one of them as parent.
    # node          -- 3 – Generic Node. A location within a station, not matching any other location_type, which can be used to link together pathways define in pathways.txt.
    # boarding_area -- 4 – Boarding Area. A specific location on a platform, where passengers can board and/or alight vehicles.
    create_enum(:location_type_val, %w[stop station entrance_exit node boarding_area])

    # -- For parentless stops:
    # -- 0 or empty - No accessibility information for the stop.
    # -- 1          - Some vehicles at this stop can be boarded by a rider in a wheelchair.
    # -- 2          - Wheelchair boarding is not possible at this stop.

    # -- For child stops:
    # -- 0 or empty - Stop will inherit its wheelchair_boarding behavior from the parent station, if specified in the parent.
    # -- 1          - There exists some accessible path from outside the station to the specific stop/platform.
    # -- 2          - There exists no accessible path from outside the station to the specific stop/platform.

    # -- For station entrances/exits:
    # -- 0 or empty - Station entrance will inherit its wheelchair_boarding behavior from the parent station, if specified for the parent.
    # -- 1          - Station entrance is wheelchair accessible.
    # -- 2          - No accessible path from station entrance to stops/platforms.
    drop_enum(:wheelchair_boarding_val, if_exists: true)
    create_enum(:wheelchair_boarding_val, %w[no_info_or_inherit accessible not_accessible])

    create_table(:stops) do
      String                    :stop_id, primary_key: true
      String                    :stop_code
      String                    :stop_name
      String                    :stop_desc,           text: true
      column                    :stop_loc,            'geography(POINT, 4326)'
      String                    :zone_id
      String                    :stop_url
      location_type_val         :location_type
      String                    :parent_station
      String                    :stop_timezone
      wheelchair_boarding_val   :wheelchair_boarding

      check { Sequel.function(:is_timezone, :stop_timezone) }

      index :stop_id
      index :stop_name
      index :stop_loc, type: :gist
    end
  end
end
