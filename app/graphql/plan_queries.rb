# frozen_string_literal: true

module Graphql::PlanQueries
  PLAN = <<-'GRAPHQL'
query (
    $flat: Float!,
    $flon: Float!,
    $tlat: Float!,
    $tlon: Float!,
    $num_itineraries: Int,
    $search_window: Long,
    $date: String,
    $time: String,
    $is_arrival_time: Boolean,
    $transfer_penalty: Int,
    $walk_reluctance: Float,
    $wait_reluctance: Float,
    $walk_board_cost: Int
) {
    plan(
        from: { lat: $flat, lon: $flon }
        to: { lat: $tlat, lon: $tlon }
        arriveBy: $is_arrival_time
        date: $date
        time: $time
        searchWindow: $search_window
        numItineraries: $num_itineraries
        transferPenalty: $transfer_penalty
        walkReluctance: $walk_reluctance
        waitReluctance: $wait_reluctance
      	walkBoardCost: $walk_board_cost
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
                duration
                distance
                from {
                  name
                  lat
                  lon
                  departureTime
                  stop {
                    vehicleMode
                  }
                }
                to {
                  name
                  lat
                  lon
                  departureTime
                  stop {
                    vehicleMode
                  }
                }
                intermediatePlaces {
                    name
                  lat
                  lon
                  departureTime
                  stop {
                    vehicleMode
                  }
                }
                route {
                    shortName
                    color
                  	textColor
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
