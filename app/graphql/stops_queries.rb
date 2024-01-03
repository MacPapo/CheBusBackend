# frozen-string-literal: true

module Graphql::StopsQueries
  AgencyIdByStop = Application['graphql'].parse <<-'GRAPHQL'
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

  DeparturesByStop = Application['graphql'].parse <<-'GRAPHQL'
query ($ids: [String!], $interval: Int!, $startTime: Long!) {
  stops(ids: $ids) {
    id
    name
    gtfsId
    stoptimesForPatterns(timeRange: $interval, startTime: $startTime) {
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

  StopTimesByDeparture = Application['graphql'].parse <<-'GRAPHQL'
query ($id: String!, $interval: Int!, $startTime: Long!) {
  stops(id: $id) {
    id
    gtfsId
    name
    stoptimesForPatterns(timeRange: $interval, startTime: $startTime) {
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
          stoptimesForDate(serviceDate: "20231221") {
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

  GeometryByTrip = Application['graphql'].parse <<-'GRAPHQL'
query ($id: String!) {
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
end
