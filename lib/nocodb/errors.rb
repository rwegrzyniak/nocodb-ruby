# frozen_string_literal: true

module Nocodb
  class Error < StandardError; end

  class NoSessionError < Error; end
  class ConfigurationError < Error; end
  class ConnectionError < Error; end

  class APIError < Error
    attr_reader :status_code, :details

    def initialize(message, status_code: nil, details: nil)
      super(message)
      @status_code = status_code
      @details = details
    end
  end
end
