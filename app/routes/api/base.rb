# frozen_string_literal: true

module Routes::API::Base
  # Registers the base routes for the API.
  # @param app [Roda] The Roda application instance.
  def self.register(app)
    # Registers the root route for API version 1.
    app.hash_branch('v1') do |r|
      # Registers all hash branches under the v1 namespace.
      r.hash_branches(:v1)
    end

    # Registers the root route for API version 2.
    app.hash_branch('v2') do |r|
      # Registers all hash branches under the v2 namespace.
      r.hash_branches(:v2)
    end

    # Registers all routes defined for version 1 of the API.
    v1_routes.each { |route| route.register(app) }

    # Registers all routes defined for version 2 of the API.
    v2_routes.each { |route| route.register(app) }
  end

  # Retrieves and returns all registered routes for API version 1.
  # @return [Array] An array of routes in the v1 namespace.
  def self.v1_routes
    # Lists and returns all routes in v1.
    Routes::API::V1.constants.map { |c| Routes::API::V1.const_get(c) }.select { |c| c.respond_to?(:register) }
  end

  # Retrieves and returns all registered routes for API version 2.
  # @return [Array] An array of routes in the v2 namespace.
  def self.v2_routes
    # Lists and returns all routes in v2.
    Routes::API::V2.constants.map { |c| Routes::API::V2.const_get(c) }.select { |c| c.respond_to?(:register) }
  end
end
