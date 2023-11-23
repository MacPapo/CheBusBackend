# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:routes) do
      add_foreign_key [:agency_id], :agencies, key: :agency_id
    end

    alter_table(:stop_times) do
      add_foreign_key [:stop_id],   :stops, key: :stop_id
      add_foreign_key [:trip_id],   :trips, key: :trip_id
    end

    alter_table(:trips) do
      add_foreign_key [:route_id],  :routes, key: :route_id
    end

    alter_table(:frequencies) do
      add_foreign_key [:trip_id],   :trips, key: :trip_id
    end

    create_view(
      :shapes_aggregated,
      self[:shapes]
        .select_group(:shape_id)
        .select_append do
          [
            array_agg(:shape_dist_traveled).order(:shape_pt_sequence).as(:distances_travelled),
            ST_MakeLine(array_agg(shape_pt_loc.cast(:geometry)).order(:shape_pt_sequence)).as(:shape)
          ]
        end
    )

    # MATERIALIZED VIEW SERVICE_DAYS
    run <<~SQL
      CREATE MATERIALIZED VIEW service_days AS
      SELECT
      	base_days.service_id,
      	base_days.date

      -- "base" service days
      FROM (
      	SELECT
      		service_id,
      		"date"
      	FROM (
      		SELECT
      			service_id,
      			"date",
      			extract(dow FROM "date") dow,
      			sunday,
      			monday,
      			tuesday,
      			wednesday,
      			thursday,
      			friday,
      			saturday
      		FROM (
      			SELECT
      				*,
      				generate_series (
      					start_date::TIMESTAMP,
      					end_date::TIMESTAMP,
      					'1 day'::INTERVAL
      				) "date"
      			FROM calendars
      		) all_days_raw
      	) all_days
      	WHERE (sunday = 'available' AND dow = 0)
      	OR (monday = 'available' AND dow = 1)
      	OR (tuesday = 'available' AND dow = 2)
      	OR (wednesday = 'available' AND dow = 3)
      	OR (thursday = 'available' AND dow = 4)
      	OR (friday = 'available' AND dow = 5)
      	OR (saturday = 'available' AND dow = 6)
      ) base_days

      -- "removed" exceptions
      LEFT JOIN (
      	SELECT *
      	FROM calendar_dates
      	WHERE exception_type = 'removed'
      ) removed
      ON base_days.service_id = removed.service_id
      AND base_days.date = removed.date
      WHERE removed.date IS NULL

      -- "added" exceptions
      UNION SELECT service_id, "date"
      FROM calendar_dates
      WHERE exception_type = 'added'

      ORDER BY service_id, "date";

      CREATE UNIQUE INDEX ON service_days (service_id, date);

      CREATE INDEX ON service_days (service_id);
      CREATE INDEX ON service_days (date);
      CREATE INDEX ON service_days (service_id, date);
    SQL

    run <<~SQL
CREATE MATERIALIZED VIEW bus_schedule AS
SELECT 
    r.route_id,
    r.route_long_name,
    s.stop_id,
    s.stop_name,
    sd.service_id as service_date,
    (sd.date + st.arrival_time) as arrival_timestamp,
    (sd.date + st.departure_time) as departure_timestamp
FROM
    routes r
JOIN
    trips t ON r.route_id = t.route_id
JOIN
    stop_times st ON t.trip_id = st.trip_id
JOIN
    stops s ON st.stop_id = s.stop_id
JOIN
    service_days sd ON t.service_id = sd.service_id
ORDER BY
    r.route_id, s.stop_id, st.arrival_time, sd.date;

CREATE INDEX idx_bus_schedule_route ON bus_schedule(route_id);
CREATE INDEX idx_bus_schedule_stop ON bus_schedule(stop_id);
CREATE INDEX idx_bus_schedule_arrival ON bus_schedule(arrival_timestamp);
CREATE INDEX idx_bus_schedule_departure ON bus_schedule(departure_timestamp);
CREATE INDEX idx_bus_schedule_service_date ON bus_schedule(service_date);
SQL

    # --------------------

    # FUNCTION LARGEST_DEPARTURE_TIME
    run <<~SQL
      CREATE OR REPLACE FUNCTION largest_departure_time ()
      RETURNS interval AS $$
      	SELECT departure_time
      	FROM stop_times
      	WHERE EXISTS (
      		SELECT *
      		FROM trips
      		JOIN service_days ON service_days.service_id = trips.service_id
      		WHERE trips.trip_id = stop_times.trip_id
      	)
      	ORDER BY departure_time DESC
      	LIMIT 1;
      $$ LANGUAGE SQL IMMUTABLE;
    SQL

    # FUNCTION LARGEST_ARRIVAL_TIME
    run <<~SQL
      CREATE OR REPLACE FUNCTION largest_arrival_time ()
      RETURNS interval AS $$
      	SELECT arrival_time
      	FROM stop_times
      	WHERE EXISTS (
      		SELECT *
      		FROM trips
      		JOIN service_days ON service_days.service_id = trips.service_id
      		WHERE trips.trip_id = stop_times.trip_id
      	)
      	ORDER BY arrival_time DESC
      	LIMIT 1;
      $$ LANGUAGE SQL IMMUTABLE;
    SQL

    # FUNCTION DATES_FILTER_MIN
    run <<~SQL
      CREATE OR REPLACE FUNCTION dates_filter_min (
      	_timestamp TIMESTAMP WITH TIME ZONE
      )
      RETURNS date AS $$
      	SELECT date_trunc(
      		'day',
      		_timestamp
      		- GREATEST(
      			largest_arrival_time(),
      			largest_departure_time()
      		)
      		-- we assume the DST <-> standard time shift is always <= 1h
      		- '1 hour 1 second'::interval
      	);
      $$ LANGUAGE SQL IMMUTABLE;
    SQL

    # FUNCTION DATES_FILTER_MAX
    run <<~SQL
      CREATE OR REPLACE FUNCTION dates_filter_max (
      	_timestamp TIMESTAMP WITH TIME ZONE
      )
      RETURNS date AS $$
      	SELECT date_trunc('day', _timestamp);
      $$ LANGUAGE SQL IMMUTABLE;
    SQL

    # VIEW ARRIVALS_DEPARTURES
    run <<~SQL
      CREATE OR REPLACE VIEW arrivals_departures AS
      WITH stop_times_based AS NOT MATERIALIZED (
      	SELECT
      		agencies.agency_id,
      		trips.route_id,
      		route_short_name,
      		route_long_name,
                      route_color,
                      route_text_color,
      		route_type,
      		s.trip_id,
      		trips.direction_id,
      		trips.trip_headsign,
      		service_days.service_id,
      		trips.shape_id,
      		"date",
      		stop_sequence,
      		stop_sequence_consec,
      		stop_headsign,
      		pickup_type,
      		drop_off_type,
      		shape_dist_traveled,
      		timepoint,
      		agencies.agency_timezone as tz,
      		arrival_time,
      		(
      			make_timestamptz(
      				date_part('year', "date")::int,
      				date_part('month', "date")::int,
      				date_part('day', "date")::int,
      				12, 0, 0,
      				agencies.agency_timezone
      			)
      			- INTERVAL '12 hours'
      			+ arrival_time
      		) t_arrival,
      		departure_time,
      		(
      			make_timestamptz(
      				date_part('year', "date")::int,
      				date_part('month', "date")::int,
      				date_part('day', "date")::int,
      				12, 0, 0,
      				agencies.agency_timezone
      			)
      			- INTERVAL '12 hours'
      			+ departure_time
      		) t_departure,
      		s.stop_id, stops.stop_name,
      		stations.stop_id station_id, stations.stop_name station_name
      	FROM (
      		stop_times s
      		JOIN stops ON s.stop_id = stops.stop_id
      		LEFT JOIN stops stations ON stops.parent_station = stations.stop_id
      		JOIN trips ON s.trip_id = trips.trip_id
      		JOIN routes ON trips.route_id = routes.route_id
      		LEFT JOIN agencies ON (
      			-- The GTFS spec allows routes.agency_id to be NULL if there is exactly one agency in the feed.
      			-- Note: We implicitly rely on other parts of the code base to validate that agency has just one row!
      			-- It seems that GTFS has allowed this at least since 2016:
      			-- https://github.com/google/transit/blame/217e9bf/gtfs/spec/en/reference.md#L544-L554
      			routes.agency_id IS NULL -- match first (and only) agency
      			OR routes.agency_id = agencies.agency_id -- match by ID
      		)
      		JOIN service_days ON trips.service_id = service_days.service_id
      	)
      	-- todo: this slows down slightly
      	-- ORDER BY route_id, s.trip_id, "date", stop_sequence
      )
      -- stop_times-based arrivals/departures
      SELECT
      	(
      		encode(trip_id::bytea, 'base64')
      		|| ':' || encode((
      			extract(ISOYEAR FROM "date")
      			|| '-' || lpad(extract(MONTH FROM "date")::text, 2, '0')
      			|| '-' || lpad(extract(DAY FROM "date")::text, 2, '0')
      		)::bytea, 'base64')
      		|| ':' || encode((stop_sequence::text)::bytea, 'base64')
      		-- frequencies_row
      		|| ':' || encode('-1'::bytea, 'base64')
      		-- frequencies_it
      		|| ':' || encode('-1'::bytea, 'base64')
      	) as arrival_departure_id,

      	stop_times_based.*,
      	-- todo: expose local arrival/departure "wall clock time"?

      	-1 AS frequencies_row,
      	-1 AS frequencies_it
      FROM stop_times_based
      UNION ALL
      -- frequencies-based arrivals/departures
      SELECT
      	(
      		encode(trip_id::bytea, 'base64')
      		|| ':' || encode((
      			extract(ISOYEAR FROM "date")
      			|| '-' || lpad(extract(MONTH FROM "date")::text, 2, '0')
      			|| '-' || lpad(extract(DAY FROM "date")::text, 2, '0')
      		)::bytea, 'base64')
      		|| ':' || encode((stop_sequence::text)::bytea, 'base64')
      		|| ':' || encode((frequencies_row::text)::bytea, 'base64')
      		|| ':' || encode((frequencies_it::text)::bytea, 'base64')
      	) as arrival_departure_id,

      	-- stop_times_based.* except t_arrival & t_departure, duh
      	-- todo: find a way to use all columns without explicitly enumerating them here
      	agency_id,
      	route_id, route_short_name, route_long_name, route_color, route_text_color, route_type,
      	trip_id, direction_id, trip_headsign,
      	service_id,
      	shape_id,
      	"date",
      	stop_sequence, stop_sequence_consec,
      	stop_headsign, pickup_type, drop_off_type, shape_dist_traveled, timepoint,
      	tz,
      	arrival_time, -- todo [breaking]: this is misleading, remove it
      	generate_series(
      		t_arrival - stop_times_offset + start_time,
      		t_arrival - stop_times_offset + end_time,
      		INTERVAL '1 second' * headway_secs
      	) as t_arrival,
      	departure_time, -- todo [breaking]: this is misleading, remove it
      	generate_series(
      		t_departure - stop_times_offset + start_time,
      		t_departure - stop_times_offset + end_time,
      		INTERVAL '1 second' * headway_secs
      	) as t_departure,
      	stop_id, stop_name,
      	station_id, station_name,
      	frequencies_row, frequencies_it
      FROM (
      	SELECT
      		stop_times_based.*,
      		frequencies.start_time,
      		frequencies.end_time,
      		frequencies.headway_secs,
      		-- todo: is frequencies.txt relative to 1st arrival_time or departure_time?
      		coalesce(
      			first_value(departure_time) OVER (PARTITION BY stop_times_based.trip_id, "date" ORDER BY stop_sequence),
      			first_value(arrival_time) OVER (PARTITION BY stop_times_based.trip_id, "date" ORDER BY stop_sequence)
      		) as stop_times_offset,
      		frequencies_row,
      		(row_number() OVER (PARTITION BY stop_times_based.trip_id, "date", frequencies_row ORDER BY stop_sequence))::integer as frequencies_it
      	FROM stop_times_based
      	JOIN (
      		SELECT
      			*,
      			(row_number() OVER (PARTITION BY trip_id, exact_times))::integer as frequencies_row
      		FROM frequencies
      		WHERE frequencies.exact_times = 'schedule_based' -- todo: is this correct?
      	) frequencies ON frequencies.trip_id = stop_times_based.trip_id
      ) frequencies_based;
    SQL

    # FUNCTION ARRIVAL_DEPARTURE_BY_ARRIVAL_DEPARTURE_ID(ID TEXT)
    run <<~SQL
      CREATE OR REPLACE FUNCTION arrival_departure_by_arrival_departure_id(id TEXT)
      RETURNS arrivals_departures
      AS $$
      	SELECT *
      	FROM arrivals_departures
      	WHERE trip_id = convert_from(decode(split_part(id, ':', 1), 'base64'), 'UTF-8')::text
      	AND "date" = (convert_from(decode(split_part(id, ':', 2), 'base64'), 'UTF-8')::text)::timestamp
      	AND stop_sequence = (convert_from(decode(split_part(id, ':', 3), 'base64'), 'UTF-8')::text)::integer
      	AND (convert_from(decode(split_part(id, ':', 4), 'base64'), 'UTF-8')::text)::integer = frequencies_row
      	AND (convert_from(decode(split_part(id, ':', 5), 'base64'), 'UTF-8')::text)::integer = frequencies_it
      	-- todo: what if there are >1 rows?
      	LIMIT 1;
      $$ LANGUAGE SQL STABLE STRICT;
    SQL

    # sas
    run <<~SQL
      CREATE OR REPLACE VIEW connections AS
      WITH stop_times_based AS NOT MATERIALIZED (
      	SELECT
      		route_id,
      		route_short_name,
      		route_long_name,
      		route_type,
      		trip_id,
      		trips.service_id,
      		trips.direction_id,
      		trips.trip_headsign,

      		from_stop_id,
      		from_stop_name,
      		from_station_id,
      		from_station_name,

      		from_stop_headsign,
      		from_pickup_type,
      		make_timestamptz(
      			date_part('year'::text, "date")::integer,
      			date_part('month'::text, "date")::integer,
      			date_part('day'::text, "date")::integer,
      			12, 0, 0::double precision,
      			agency_timezone
      		) - '12:00:00'::interval + departure_time AS t_departure,
      		departure_time,
      		from_stop_sequence,
      		from_stop_sequence_consec,
      		from_timepoint,
      		"date",
      		to_timepoint,
      		to_stop_sequence,
      		to_stop_sequence_consec,
      		make_timestamptz(
      			date_part('year'::text, "date")::integer,
      			date_part('month'::text, "date")::integer,
      			date_part('day'::text, "date")::integer,
      			12, 0, 0::double precision,
      			agency_timezone
      		) - '12:00:00'::interval + arrival_time AS t_arrival,
      		arrival_time,
      		to_drop_off_type,
      		to_stop_headsign,

      		to_stop_id,
      		to_stop_name,
      		to_station_id,
      		to_station_name
      	FROM (
      		SELECT
      			trips.route_id,
      			route_short_name,
      			route_long_name,
      			route_type,
      			stop_times.trip_id, -- not using trips.trip_id here for the query optimizer
      			trips.service_id,
      			trips.direction_id,
      			trips.trip_headsign,
      			agencies.agency_timezone,

      			from_stops.stop_id as from_stop_id,
      			from_stops.stop_name as from_stop_name,
      			from_stations.stop_id as from_station_id,
      			from_stations.stop_name as from_station_name,
      			stop_times.stop_headsign as from_stop_headsign,
      			stop_times.pickup_type as from_pickup_type,
      			stop_times.departure_time as departure_time,
      			stop_times.stop_sequence as from_stop_sequence,
      			stop_times.stop_sequence_consec as from_stop_sequence_consec,
      			stop_times.timepoint as from_timepoint,

      			to_stop_times.timepoint as to_timepoint,
      			to_stop_times.stop_sequence as to_stop_sequence,
      			to_stop_times.stop_sequence_consec as to_stop_sequence_consec,
      			to_stop_times.arrival_time as arrival_time,
      			to_stop_times.drop_off_type as to_drop_off_type,
      			to_stop_times.stop_headsign as to_stop_headsign,
      			to_stop_times.stop_id as to_stop_id,
      			to_stops.stop_name as to_stop_name,
      			to_stations.stop_id as to_station_id,
      			to_stations.stop_name as to_station_name
      		FROM trips
      		LEFT JOIN routes ON trips.route_id = routes.route_id
      		LEFT JOIN agencies ON (
      			-- The GTFS spec allows routes.agency_id to be NULL if there is exactly one agency in the feed.
      			-- Note: We implicitly rely on other parts of the code base to validate that agency has just one row!
      			-- It seems that GTFS has allowed this at least since 2016:
      			-- https://github.com/google/transit/blame/217e9bf/gtfs/spec/en/reference.md#L544-L554
      			routes.agency_id IS NULL -- match first (and only) agency
      			OR routes.agency_id = agencies.agency_id -- match by ID
      		)
      		LEFT JOIN stop_times ON trips.trip_id = stop_times.trip_id
      		LEFT JOIN stops from_stops ON stop_times.stop_id = from_stops.stop_id
      		LEFT JOIN stops from_stations ON from_stops.parent_station = from_stations.stop_id
      		INNER JOIN stop_times to_stop_times ON stop_times.trip_id = to_stop_times.trip_id AND stop_times.stop_sequence_consec + 1 = to_stop_times.stop_sequence_consec
      		INNER JOIN stops to_stops ON to_stop_times.stop_id = to_stops.stop_id
      		LEFT JOIN stops to_stations ON to_stops.parent_station = to_stations.stop_id
      	) trips
      	JOIN (
      		SELECT *
      		FROM service_days
      		ORDER BY service_id, "date"
      	) service_days ON trips.service_id = service_days.service_id
      )
      -- stop_times-based connections
      SELECT
      	(
      		encode(trip_id::bytea, 'base64')
      		|| ':' || encode((
      			extract(ISOYEAR FROM "date")
      			|| '-' || lpad(extract(MONTH FROM "date")::text, 2, '0')
      			|| '-' || lpad(extract(DAY FROM "date")::text, 2, '0')
      		)::bytea, 'base64')
      		|| ':' || encode((from_stop_sequence::text)::bytea, 'base64')
      		-- frequencies_row
      		|| ':' || encode('-1'::bytea, 'base64')
      		-- frequencies_it
      		|| ':' || encode('-1'::bytea, 'base64')
      	) as connection_id,

      	stop_times_based.*,

      	-1 AS frequencies_row,
      	-1 AS frequencies_it
      FROM stop_times_based
      UNION ALL
      -- frequencies-based connections
      SELECT
      	(
      		encode(trip_id::bytea, 'base64')
      		|| ':' || encode((
      			extract(ISOYEAR FROM "date")
      			|| '-' || lpad(extract(MONTH FROM "date")::text, 2, '0')
      			|| '-' || lpad(extract(DAY FROM "date")::text, 2, '0')
      		)::bytea, 'base64')
      		|| ':' || encode((from_stop_sequence::text)::bytea, 'base64')
      		|| ':' || encode((frequencies_row::text)::bytea, 'base64')
      		|| ':' || encode((frequencies_it::text)::bytea, 'base64')
      	) as connection_id,

      	-- stop_times_based.* except t_arrival & t_departure, duh
      	-- todo: find a way to use all columns without explicitly enumerating them here
      	route_id, route_short_name, route_long_name, route_type,
      	trip_id,
      	service_id,
      	direction_id,
      	trip_headsign,

      	from_stop_id,
      	from_stop_name,
      	from_station_id,
      	from_station_name,

      	from_stop_headsign,
      	from_pickup_type,
      	generate_series(
      		t_departure - stop_times_offset + start_time,
      		t_departure - stop_times_offset + end_time,
      		INTERVAL '1 second' * headway_secs
      	) as t_departure,
      	departure_time, -- todo [breaking]: this is misleading, remove it
      	from_stop_sequence,
      	from_stop_sequence_consec,
      	from_timepoint,

      	"date",

      	to_timepoint,
      	to_stop_sequence,
      	to_stop_sequence_consec,
      	generate_series(
      		t_arrival - stop_times_offset + start_time,
      		t_arrival - stop_times_offset + end_time,
      		INTERVAL '1 second' * headway_secs
      	) as t_arrival,
      	arrival_time, -- todo [breaking]: this is misleading, remove it
      	to_drop_off_type,
      	to_stop_headsign,

      	to_stop_id,
      	to_stop_name,
      	to_station_id,
      	to_station_name,

      	frequencies_row,
      	frequencies_it
      FROM (
      	SELECT
      		stop_times_based.*,
      		frequencies.start_time,
      		frequencies.end_time,
      		frequencies.headway_secs,
      		first_value(departure_time) OVER (PARTITION BY stop_times_based.trip_id, "date" ORDER BY from_stop_sequence) as stop_times_offset,
      		frequencies_row,
      		(row_number() OVER (PARTITION BY stop_times_based.trip_id, "date", frequencies_row ORDER BY from_stop_sequence))::integer as frequencies_it
      	FROM stop_times_based
      	JOIN (
      		SELECT
      			*,
      			(row_number() OVER (PARTITION BY trip_id, exact_times))::integer as frequencies_row
      		FROM frequencies
      		WHERE frequencies.exact_times = 'schedule_based' -- todo: is this correct?
      	) frequencies ON frequencies.trip_id = stop_times_based.trip_id
      ) frequencies_based;
    SQL

    # FUNCTION CONNECTION_BY_CONNECTION_ID(ID TEXT)
    run <<~SQL
      CREATE OR REPLACE FUNCTION connection_by_connection_id(id TEXT)
      RETURNS connections
      AS $$
      	SELECT *
      	FROM connections
      	WHERE trip_id = convert_from(decode(split_part(id, ':', 1), 'base64'), 'UTF-8')::text
      	AND "date" = (convert_from(decode(split_part(id, ':', 2), 'base64'), 'UTF-8')::text)::timestamp
      	AND from_stop_sequence = (convert_from(decode(split_part(id, ':', 3), 'base64'), 'UTF-8')::text)::integer
      	AND (convert_from(decode(split_part(id, ':', 4), 'base64'), 'UTF-8')::text)::integer = frequencies_row
      	AND (convert_from(decode(split_part(id, ':', 5), 'base64'), 'UTF-8')::text)::integer = frequencies_it
      	-- todo: what if there are >1 rows?
      	LIMIT 1;
      $$ LANGUAGE SQL STABLE STRICT;
    SQL
  end

  down do
    # Reverse the operations above if necessary, for example:
    drop_view(:shapes_aggregated)

    alter_table(:trips) do
      drop_foreign_key [:route_id]
    end

    alter_table(:stop_times) do
      drop_foreign_key [:stop_id]
      drop_foreign_key [:trip_id]
    end

    alter_table(:routes) do
      drop_foreign_key [:agency_id]
    end
  end
end
