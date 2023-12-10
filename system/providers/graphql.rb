# frozen_string_literal: true

Application.register_provider(:graphql) do
  prepare do
    require 'graphql/client'
    require 'graphql/client/http'
  end

  start do
    # Endpoint del servizio GraphQL esterno
    http = GraphQL::Client::HTTP.new(ENV.delete('GRAPHQL_URL')) do
      def headers(_context)
        # Optionally set any HTTP headers
        {
          'Content-Type': 'application/json',
          'OTPTimeout': '180000'
        }
      end
    end

    # Carica lo schema GraphQL
    schema = GraphQL::Client.load_schema(http)

    # Crea e restituisce il client GraphQL
    client = GraphQL::Client.new(schema:, execute: http)
    register(:graphql, client)
  end
end
