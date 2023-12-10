# frozen_string_literal: true

Application.register_provider(:graphql) do
  prepare do
    require 'graphql/client'
    require 'graphql/client/http'
  end

  start do
    http = GraphQL::Client::HTTP.new(ENV.delete('GRAPHQL_URL')) do
      def headers(_context)
        {
          'Content-Type': 'application/json',
          'OTPTimeout': '180000'
        }
      end
    end

    schema = GraphQL::Client.load_schema(http)

    client = GraphQL::Client.new(schema:, execute: http)
    register(:graphql, client)
  end
end
