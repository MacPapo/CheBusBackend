# frozen_string_literal: true

module Serializers
  # {APIResponseSerializer} is a class that serializes API responses into JSON format.
  class APIResponseSerializer < ApplicationSerializer
    # Serializes the response object to JSON.
    #
    # @return [Hash] the serialized response data.
    def to_json(*_args)
      if @object[:status] == 'success'
        {
          status: 'success',
          message: @object[:message],
          data: @object[:data]
        }
      elsif @object[:status] == 'error'
        {
          status: 'error',
          message: @object[:message],
          code: @object[:code]
        }
      else
        raise 'Unknown response type'
      end
    end
  end
end
