# frozen_string_literal: true

module Serializers
  # {ApplicationSerializer} is base class that contains configuration that is used
  # across all serializers for rendering JSON using Oj serializer.
  class ApplicationSerializer
    def initialize(object)
      @object = object
    end

    # It generates JSON using Oj serializer dump method.
    #
    # @return [String] which is compliant with the JSON standard.
    def render
      Oj.dump(to_json)
    end

    def to_json(*_args)
      raise NotImplementedError, 'You must implement the to_json method in the subclass'
    end
  end
end
