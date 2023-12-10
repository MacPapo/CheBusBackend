# frozen-string-literal: true

module Graphql::PlanQueries
  Plan = Application['graphql'].parse <<-'GRAPHQL'
query($flat: Float!, $flon: Float!, $tlat: Float!, $tlon: Float!, $date: String!, $time: String!) {
    plan(
        from: { lat: $flat, lon: $flon }
        to: { lat: $tlat, lon: $tlon }
        date: $date,
        time: $time,
        transportModes: [
            {
                mode: TRANSIT
            },
        ]) {
        itineraries {
            startTime
            endTime
            legs {
                mode
                startTime
                endTime
                from {
                    name
                    lat
                    lon
                    departureTime
                    arrivalTime
                }
                to {
                    name
                    lat
                    lon
                    departureTime
                    arrivalTime
                }
                route {
                    gtfsId
                    longName
                    shortName
                }
                legGeometry {
                    points
                }
            }
        }
    }
}
  GRAPHQL
end
