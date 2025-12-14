# frozen_string_literal: true

module Nocodb
  class Resource
    class << self
      def client
        Nocodb.current_client
      end

      def extract_array_from(parsed, preferred_keys)
        ResponseHandler.extract_array_from(parsed, preferred_keys)
      end
    end

    def client
      self.class.client
    end
  end
end
