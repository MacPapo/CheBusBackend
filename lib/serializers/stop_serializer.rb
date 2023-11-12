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
        name: stop[:stop_name],
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

    # Formatta una singola fermata.
    def format_departure_stop(departure)
      # Formattazione di base
      {
        headsign: departure[:trip_headsign],
        sid: departure[:service_id],
        tid: departure[:trip_id],
        departure_time: departure[:t_departure],
        background_color: departure[:route_color],
        text_color: departure[:route_text_color],
        line_number: departure[:route_short_name]
      }
    end

    def format_stop(stop)
      # Formattazione di base
      {
        id: stop[:stop_id],
        name: stop[:stop_name],
        loc: stop[:stop_loc]
      }
    end

    def format_only_name(stop)
      # Formattazione di base
      {
        name: stop[:stop_name]
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
