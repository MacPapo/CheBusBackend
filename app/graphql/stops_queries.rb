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
query (
    $ids: [String],
    $start_time: Long,
    $interval: Int
) {
  stops(ids: $ids) {
    id
    name
    gtfsId
    stoptimesForPatterns(timeRange: $interval, startTime: $start_time) {
      stoptimes {
        scheduledArrival
        trip {
          id
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
              desc
            }
          }
        }
      }
    }
  }
}
  GRAPHQL

  StopTimesByDeparture = <<-'GRAPHQL'
query (
    $id: String!,
    $interval: Int!,
    $start_time: Long!,
    $service_date: String!
) {
  stops(id: $id) {
    id
    gtfsId
    name
    stoptimesForPatterns(timeRange: $interval, startTime: $start_time) {
      stoptimes {
        scheduledArrival
        trip {
          id
          gtfsId
          tripHeadsign
          activeDates
          route {
            id
            shortName
            longName
            mode
          }
          stoptimesForDate(serviceDate: $service_date) {
            stopPosition
            scheduledArrival
            stop {
              id
              name
              desc
            }
          }
        }
      }
    }
  }
}
  GRAPHQL

  GeometryByTrip = <<-'GRAPHQL'
query (
    $id: String!
) {
  trip(id: $id) {
    id
    tripHeadsign
    routeShortName
    tripGeometry {
      length
      points
    }
  }
}
GRAPHQL
end
