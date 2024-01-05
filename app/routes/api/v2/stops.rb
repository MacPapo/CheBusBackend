# frozen_string_literal: true

# Module for defining API endpoints related to bus stops.
# Provides RESTful routes for accessing stop information and departures.
module Routes::API::V2::Stops
  MAX_DEPARTURES = 50
  USER_PARAMS = %w[latitude longitude].freeze
  DEPARTURES_PARAMS = %w[stopname datetime interval].freeze
  TRIPS_PARAMS = %w[trip_id datetime].freeze

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

      r.on 'trips' do
        r.get(params!: TRIPS_PARAMS) do |trip_id, datetime|
          Routes::API::V2::Stops.handle_trips_request(r, trip_id, datetime)
        end
      end

      r.on 'graphql' do
        r.get do
          res = Application['graphql'].query(
            Graphql::PlanQueries::Plan,
            variables: {
              flat: 45.42551,
              flon: 12.36083,
              tlat: 45.42902,
              tlon: 12.35616,
              date: '2024-01-04',
              time: '17:20',
              search_window: 3600
            }
          )

          APIResponse.success(
            r.response,
            Serializers::PlanSerializer.new(res['data']['plan']['itineraries']).to_json
          )
        end
      end
    end
  end

  # Handles requests for all bus stops.
  # @param _r [Roda::RodaRequest] The Roda request object.
  # @return [String] Serialized JSON response containing all stops.
  def self.handle_all_stops_request(r, lat, lon)
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
      unless lat.empty? || lon.empty?
        ratings = Helpers::RedisHelper.geo_rating([lat.to_f, lon.to_f])

        unless ratings.empty?
          ratings.each do |rating|
            change = data.find { |stop| stop['name'] == rating[:name]}
            change['rating'] = rating[:rating]
          end
        end
      end

      res = data
    end

    APIResponse.success(r.response, res)
  end

  # Handles requests for departures from a specific stop within a given time interval.
  # @param _r [Roda::RodaRequest] The Roda request object.
  # @param stopname [String] The name of the stop.
  # @param datetime [String] The starting datetime for departures.
  # @param interval [String] The time interval in minutes.
  # @return [String] Serialized JSON response of departures.
  def self.handle_departures_request(r, stopname, datetime, interval)
    contract = Validations::StopsValidation::StopContract.new
    validation_result = contract.call(stopname:, datetime:, interval:)

    if validation_result.success?
      unix_timestamp = Helpers::TimeHelper.from_date_to_unix_str(datetime)
      interval_in_sec = Helpers::TimeHelper.min_in_sec(interval)

      a_id = self.handle_agency_query(stopname)
      c_id = Models::StopCluster.search_id_in_cluster_by_name(stopname)

      if c_id.nil?
        s_id = Models::Stop.search_stop_id_by_name(stopname)
        return APIResponse.error(r.response, 'The stop name provided is incorrect!', 400) if s_id.nil?

        s_id = "#{a_id}:#{s_id}"
      else
        s_id = Models::Stop.search_stops_id_by_cid(c_id)
        s_id.map! { |x| "#{a_id}:#{x}" }
      end

      res = Application['graphql'].query(
        Graphql::StopsQueries::DeparturesByStop,
        variables: {
          ids: s_id,
          interval: interval_in_sec,
          start_time: unix_timestamp,
        }
      )

      APIResponse.success(r.response, Serializers::StopSerializer.new(res['data']['stops'], view: :departures).to_json)
    else
      APIResponse.error(r.response, validation_result.errors.to_h, 400)
    end
  end

  def self.handle_trips_request(r, trip_id, datetime)
    contract = Validations::TripsValidation::TripContract.new
    validation_result = contract.call(trip_id:, datetime:)

    if validation_result.success?

      res = Application['graphql'].query(
        Graphql::StopsQueries::StopTimesByTrip,
        variables: {
          trip_id: trip_id,
          service_date: Helpers::TimeHelper.format_service_date(datetime)
        }
      )

      APIResponse.success(r.response, "Successfull")
    else
      APIResponse.error(r.response, validation_result.errors.to_h, 400)
    end
  end

  def self.handle_agency_query(name)
    res = Application['graphql'].query(
      Graphql::StopsQueries::AgencyIdByStop,
      variables: {
        stop_name: name
      }
    )['data']['stops']

    res[0]['routes'][0]['agency']['gtfsId'].split(':').first
  end
end
