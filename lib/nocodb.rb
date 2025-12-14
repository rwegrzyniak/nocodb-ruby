# frozen_string_literal: true

require_relative "nocodb/version"
require_relative "nocodb/errors"
require_relative "nocodb/error_handler"
require_relative "nocodb/response_handler"
require_relative "nocodb/client"
require_relative "nocodb/resource"
require_relative "nocodb/base"
require_relative "nocodb/table"

module Nocodb
  class << self
    # Session-based API usage:
    # Nocodb.session(base_url: "...", api_token: "...") do
    #   bases = Nocodb::Base.all
    #   base = Nocodb::Base.find("base_id")
    #   tables = Nocodb::Table.where(base_id: "base_id")
    # end
    def session(config)
      raise ArgumentError, "Block required for Nocodb.session" unless block_given?

      client = Client.new(config)
      Thread.current[:nocodb_client] = client

      yield
    ensure
      Thread.current[:nocodb_client] = nil
    end

    # Get the current thread-local client
    def current_client
      Thread.current[:nocodb_client] || raise(Nocodb::NoSessionError, "No active Nocodb session. Wrap your code in Nocodb.session { ... }")
    end
  end
end
