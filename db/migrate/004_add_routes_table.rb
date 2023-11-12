# frozen_string_literal: true

Sequel.migration do
  change do
    drop_enum(:route_type_val, if_exists: true)

    # -- basic types
    # 0  –  Tram, Streetcar, Light rail. Any light rail or street level system within a metropolitan area.
    # 1  –  Subway, Metro. Any underground rail system within a metropolitan area.
    # 2  –  Rail. Used for intercity or long-distance travel.
    # 3  –  Bus. Used for short- and long-distance bus routes.
    # 4  –  Ferry. Used for short- and long-distance boat service.
    # 5  –  Cable tram. Used for street-level rail cars where the cable runs beneath the vehicle, e.g., cable car in San Francisco.
    # 6  –  Aerial lift, suspended cable car (e.g., gondola lift, aerial tramway). Cable transport where cabins, cars, gondolas or open chairs are suspended by means of one or more cables.
    # 7  –  Funicular. Any rail system designed for steep inclines.
    # 11 –  Trolleybus. Electric buses that draw power from overhead wires using poles.
    # 12 –  Monorail. Railway in which the track consists of a single rail or a beam.
    create_enum(:route_type_val, %w[0 1 2 3 4 5 6 7 11 12])

    create_table(:routes) do
      String             :route_id,            primary_key: true
      String             :agency_id,           null: false
      String             :route_short_name
      String             :route_long_name
      String             :route_desc
      route_type_val     :route_type, null: false
      String             :route_url
      String             :route_color,         size: 6, default: 'FFFFFF'
      String             :route_text_color,    size: 6, default: '000000'
      Integer            :route_sort_order

      index :agency_id
      index :route_short_name
    end
  end
end
