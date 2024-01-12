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
      when :stops
        all_stops
      when :departures
        departures_stops
      else
        all_stops
      end
    end

    private

    # Serializzazione di default.
    def all_stops
      format_stops { |stop| format_stop(stop) }
    end

    # Restituisce le fermate con tutti i dettagli.
    def departures_stops
      format_stops { |departure| format_departure_stop(departure) }
    end

    # Format Departure QUERY.
    def format_departure_stop(departure)
      # Formattazione di base
      {
        departure_stop_name: departure['from_stop'],
        departure_stop_lat: departure['from_lat'],
        departure_stop_lon: departure['from_lon'],
        first_departure_time: Helpers::TimeHelper.sec_til_mid(departure['scheduledArrival']),
        headsign: departure['headsign'],
        line: departure['trip']['routeShortName'],
        times: format_stop_times(departure['trip']['stoptimes']),
        geometries: departure['trip']['tripGeometry']['points']
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

    def format_stop_times(stop_times)
      stop_times.map do |stime|
        {
          t_departure: Helpers::TimeHelper.sec_til_mid(stime['scheduledDeparture']),
          stop_name: stime['stop']['name'],
          stop_lat: stime['stop']['lat'],
          stop_lon: stime['stop']['lon'],
          mode: stime['stop']['vehicleMode']
        }
      end
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
