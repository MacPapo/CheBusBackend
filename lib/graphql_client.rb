# frozen_string_literal: true

module GraphqlClient
  # Graphql Client
  class Client
    def initialize
      @uri = URI(ENV.delete('GRAPHQL_URL'))
      @type = { 'Content-Type' => 'application/json' }
    end

    def query(query, variables: {})
      request = Net::HTTP::Post.new(@uri, @type)

      request.body = Oj.dump(
        {
          query:,
          variables:
        }
      )

      response = Net::HTTP.start(@uri.hostname, @uri.port) { |http| http.request(request) }
      Oj.load(response.body)
    end
  end
end
