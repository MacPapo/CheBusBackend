# frozen-string-literal: true

module Graphql::PlanQueries
  Plan = Application['graphql'].parse <<-'GRAPHQL'
query(
    $flat: Float!,
    $flon: Float!,
    $tlat: Float!,
    $tlon: Float!,
    $search_window: Long!,
    $date: String!,
    $time: String!,
) {
    plan(
        from: { lat: $flat, lon: $flon }
        to: { lat: $tlat, lon: $tlon }
        date: $date
        time: $time
        searchWindow: $search_window
        numItineraries: 50
        transferPenalty: 30
        walkReluctance: 60
        waitReluctance: 1.0
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
