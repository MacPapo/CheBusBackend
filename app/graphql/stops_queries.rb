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
    $omit_non_pickup: Boolean,
    $omit_canceled: Boolean
) {
  stops(
    ids: $ids
  ) {
    name
    lat
    lon
    vehicleMode
    stoptimesWithoutPatterns(
      timeRange: $interval,
      startTime: $start_time,
      numberOfDepartures: $num_departures,
      omitNonPickups: $omit_non_pickup,
      omitCanceled: $omit_canceled
    ) {
      scheduledArrival
      headsign
      trip {
        route {
          shortName
          color
          textColor
        }
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
end
