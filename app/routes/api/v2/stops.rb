# frozen_string_literal: true

# Module for defining API endpoints related to bus stops.
# Provides RESTful routes for accessing stop information and departures.
module Routes::API::V2::Stops
  MAX_DEPARTURES = 200
  OMIT_NON_PICKUP = true
  OMIT_CANCELED = true
  USER_PARAMS = %w[latitude longitude].freeze
  DEPARTURES_PARAMS = %w[stopname datetime interval].freeze

  # Registers routes under the 'stops' namespace.
  # @param app [Roda] The Roda application to which the routes are registered.
  def self.register(app)
    app.hash_branch(:v2, 'stops') do |r|
      r.is do
        r.get(params: USER_PARAMS) do |lat, lon|
          Routes::API::V2::Stops.handle_all_stops_request(r, lat, lon)
        end
      end

      r.on 'departures' do
        r.get(params!: DEPARTURES_PARAMS) do |stopname, datetime, interval|
          Routes::API::V2::Stops.handle_departures_request(r, stopname, datetime, interval)
        end
      end
    end
  end

  def self.handle_all_stops_request(resp, lat, lon)
    contract = Validations::StopsValidation::StopsContract.new
    validation_result = contract.call(latitude: lat, longitude: lon)

    if validation_result.success?
      data = Helpers::RedisHelper.get_stops

      res = nil
      if data.empty?
        stops = Models::Stop.give_all_stops_no_cluster
        cluster = Models::StopCluster.give_all_stops_cluster

        data = (stops + cluster).map { |x| [x[0], x[1], x[2], x[3], 0] }
        res = Serializers::StopSerializer.new(data)
        Helpers::RedisHelper.geo_import_stops_if_needed(data)
        Helpers::RedisHelper.import_all_stops_if_needed(res.render)
        res = res.to_json
      else
        unless lat.to_f.zero? || lon.to_f.zero?
          ratings = Helpers::RedisHelper.geo_rating([lat.to_f, lon.to_f])

          unless ratings.empty?
            ratings.each do |rating|
              change = data.find { |stop| stop['name'] == rating[:name] }
              change['rating'] = rating[:rating]
            end
          end
        end

        res = data
      end

      APIResponse.success(resp.response, res)
    else
      APIResponse.error(resp.response, validation_result.errors.to_h, 400)
    end
  end

  def self.handle_departures_request(resp, stopname, datetime, interval)
    contract = Validations::StopsValidation::DepartureContract.new
    validation_result = contract.call(stopname:, datetime:, interval:)

    if validation_result.success?
      unix_timestamp = Helpers::TimeHelper.from_date_to_unix_str(datetime)
      interval_in_sec = Helpers::TimeHelper.min_in_sec(interval)

      c_id = Models::StopCluster.search_id_in_cluster_by_name(stopname)

      if c_id.nil?
        s_id = Models::Stop.search_stop_id_by_name(stopname)
        return APIResponse.error(resp.response, 'The stop name provided is incorrect!', 400) if s_id.nil?

        a_id = handle_agency_query(stopname)
        return APIResponse.error(resp.response, 'No Routes from here', 400) if a_id.nil?

        s_id = "#{a_id}:#{s_id}"
      else
        s_id = Models::Stop.search_stops_id_by_cid(c_id)

        a_id = handle_agency_query(stopname)
        return APIResponse.error(resp.response, 'No Routes from here', 400) if a_id.nil?

        s_id.map! { |x| "#{a_id}:#{x}" }
      end

      res = Application['graphql'].query(
        Graphql::StopsQueries::DEPARTURES_BY_STOP,
        variables: {
          ids: s_id,
          start_time: unix_timestamp,
          interval: interval_in_sec,
          num_departures: MAX_DEPARTURES,
          omit_non_pickup: OMIT_NON_PICKUP,
          omit_canceled: OMIT_CANCELED
        }
      )['data']['stops']

      APIResponse.success(
        resp.response,
        Serializers::StopSerializer.new(
          sort_departure_by_arrival_time(res),
          view: :departures
        ).to_json
      )
    else
      APIResponse.error(resp.response, validation_result.errors.to_h, 400)
    end
  end

  def self.handle_agency_query(name)
    res = Application['graphql'].query(
      Graphql::StopsQueries::AGENCY_ID_BY_STOP,
      variables: {
        stop_name: name
      }
    )['data']['stops'][0]['routes']
    return nil if res.nil? || res.empty?

    res[0]['agency']['gtfsId'].split(':').first
  end

  def self.purify_output(out)
    out.map do |x|
      x['stoptimesWithoutPatterns'].map do |y|
        y['from_stop'] = x['name']
        y['from_lat']  = x['lat']
        y['from_lon']  = x['lon']
        y['from_mode'] = x['vehicleMode']
      end

      x = x['stoptimesWithoutPatterns']
    end.flatten
  end

  def self.sort_departure_by_arrival_time(raw_departure)
    departure = purify_output(raw_departure)

    return departure if departure.nil? || departure.empty?

    departure.sort_by { |x| x['scheduledArrival'].to_i }
  end
end
