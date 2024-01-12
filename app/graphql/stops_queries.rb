# frozen_string_literal: true

module Graphql::StopsQueries
  AGENCY_ID_BY_STOP = <<-'GRAPHQL'
query(
    $stop_name: String!
) {
  stops(name: $stop_name) {
    routes{
      agency{
        gtfsId
      }
    }
  }
}
  GRAPHQL

  DEPARTURES_BY_STOP = <<-'GRAPHQL'
query (
    $ids: [String],
    $start_time: Long,
    $interval: Int,
    $num_departures: Int,
    $omit_non_pickup: Boolean
) {
  stops(
    ids: $ids
  ) {
    name
    lat
    lon
    stoptimesWithoutPatterns(
      timeRange: $interval,
      startTime: $start_time,
      numberOfDepartures: $num_departures
      omitNonPickups: $omit_non_pickup
    ) {
      scheduledArrival
      headsign
      trip {
        routeShortName
        stoptimes {
          scheduledDeparture
          stop {
            name
            lat
            lon
            vehicleMode
          }
        }
        tripGeometry {
          points
        }
      }
    }
  }
}
  GRAPHQL

  STOP_TIMES_BY_TRIP = <<-'GRAPHQL'
query (
    $trip_id: String!,
    $service_date: String!
) {
  trip(id: $trip_id) {
    gtfsId
    tripHeadsign
    routeShortName
    activeDates
    stoptimesForDate(serviceDate: $service_date) {
      stopPosition
      scheduledArrival
      stop {
        gtfsId
        name
      }
    }
    tripGeometry{
      length
      points
    }
  }
}
  GRAPHQL
end
