# frozen-string-literal: true

module Graphql::StopsQueries
  AgencyIdByStop = <<-'GRAPHQL'
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

  DeparturesByStop = <<-'GRAPHQL'

# This is an example query for fetching all routes of your OTP deployment.
# Click on the documentation icon on the left to read about the available types
# or use autocomplete to explore the schema.
query (
    $ids: [String],
    $start_time: Long,
    $interval: Int
) {
  stops(ids: $ids) {
    name
    gtfsId
    stoptimesWithoutPatterns(timeRange: $interval, startTime: $start_time) {
      scheduledArrival
      trip {
        gtfsId
        tripHeadsign
        activeDates
        route {
          id
          shortName
          longName
          mode
        }
        arrivalStoptime {
          stopPosition
          scheduledArrival
          stop {
            id
            name
          }
        }
      }
    }
  }
}
  GRAPHQL

  StopTimesByTrip = <<-'GRAPHQL'
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
