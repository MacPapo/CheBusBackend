# frozen_string_literal: true

module Serializers
  class StopSerializer < ApplicationSerializer
    # Inizializza il serializzatore con un oggetto e opzioni.
    # @param object [Hash, Array<Hash>] Un singolo oggetto fermata o un array di oggetti fermata.
    # @param opts [Hash] Opzioni per personalizzare la serializzazione.
    def initialize(object, opts = {})
      super(object) # Chiama il costruttore della classe genitore.
      @opts = opts
    end

    # Metodo principale per serializzare l'output.
    def to_json(*_args)
      case @opts[:view]
      when :detailed
        detailed_stops
      when :stop_only_name
        stops_only_name
      when :departures
        departures_stops
      else
        default_stops
      end
    end

    private

    # Serializzazione di default.
    def default_stops
      format_stops { |stop| format_stop(stop) }
    end

    def stops_only_name
      format_stops { |stop| format_only_name(stop) }
    end

    # Restituisce le fermate con tutti i dettagli.
    def detailed_stops
      format_stops { |stop| format_full_stop(stop) }
    end

    # Restituisce le fermate con tutti i dettagli.
    def departures_stops
      format_stops { |departure| format_departure_stop(departure) }
    end

    # Formatta una singola fermata.
    def format_full_stop(stop)
      # Formattazione di base
      {
        id: stop[:stop_id],
        code: stop[:stop_code],
        name: stop[:name],
        desc: stop[:stop_desc],
        loc: stop[:stop_loc],
        zone_id: stop[:zone_id],
        url: stop[:stop_url],
        location_type: stop[:location_type],
        parent_station: stop[:parent_station],
        timezone: stop[:stop_timezone],
        wheelchair_boarding: stop[:wheelchair_boarding]
      }
    end

    # Format Departure QUERY.
    def format_departure_stop(departure)
      # Formattazione di base
      {
        id: departure['gtfsId'],
        name: departure['name'],
        stops: format_stoptimes_patterns(departure['stoptimesForPatterns'])
      }
    end

    def format_stop(stop)
      # Formattazione di base
      {
        name: stop[0],
        lat: stop[1],
        lon: stop[2],
        category: stop[3],
        rating: stop[4]
      }
    end

    def format_only_name(stop)
      # Formattazione di base
      {
        name: stop[:name]
      }
    end

    def format_stoptimes_patterns(spatterns)
      spatterns.map do |pattern|
        pattern['stoptimes'].map do |stime|
          {
            t_arrival: Helpers::TimeHelper.sec_til_mid(stime['scheduledArrival']),
            trip: format_trip(stime['trip'])
          }
        end
      end
    end

    def format_trip(trip)
      {
        id: trip['gtfsId'],
        headsign: trip['tripHeadsign'],
        route: format_route(trip['route']),
        arrival_stop_time: format_arrival_stop_time(trip['arrivalStoptime'])
      }
    end

    def format_route(route)
      {
        id: route['id'],
        short_name: route['shortName'],
        long_name: route['longName'],
        mode: route['mode']
      }
    end

    def format_arrival_stop_time(arrival_stoptime)
      {
        scheduled_arrival: Helpers::TimeHelper.sec_til_mid(arrival_stoptime['scheduledArrival']),
        stop: format_single_stop(arrival_stoptime['stop'])
      }
    end

    def format_single_stop(stop)
      {
        name: stop['name']
      }
    end

    # Metodo helper per formattare un array di fermate.
    def format_stops(&block)
      if @object.is_a?(Array)
        @object.map(&block)
      else
        yield(@object)
      end
    end
  end
end
