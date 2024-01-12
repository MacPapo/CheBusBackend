# frozen-string-literal: true

module Graphql::PlanQueries
  Plan = <<-'GRAPHQL'
query(
    $flat: Float!,
    $flon: Float!,
    $tlat: Float!,
    $tlon: Float!,
    $search_window: Long!,
    $date: String!,
    $time: String!,
    $is_arrival_time: Boolean
) {
    plan(
        from: { lat: $flat, lon: $flon }
        to: { lat: $tlat, lon: $tlon }
        arriveBy: $is_arrival_time
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
            duration
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
                agency {
                    id
                    gtfsId
                }
                route {
                    gtfsId
                    longName
                    shortName
                }
                trip {
                    id
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
