# frozen_string_literal: true

Application.register_provider(:graphql) do
  prepare do
    require 'net/http'
    require_relative '../../lib/graphql_client'
  end

  start do
    client = GraphqlClient::Client.new
    register(:graphql, client)
  end
end
