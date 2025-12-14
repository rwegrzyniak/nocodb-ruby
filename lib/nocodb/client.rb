# frozen_string_literal: true

require "httparty"

module Nocodb
  class Client
    include HTTParty

    attr_reader :base_url, :api_token

    def initialize(config)
      @base_url = extract_base_url(config)
      @api_token = extract_api_token(config)

      raise ConfigurationError, "base_url is required" if @base_url.nil? || @base_url.empty?
      raise ConfigurationError, "api_token is required" if @api_token.nil? || @api_token.empty?

      @base_url = normalize_url(@base_url)
    end

    # Verify connection to NocoDB
    def verify_connection
      url = "#{@base_url}/api/v2/meta/bases"

      attempts = [
        { header: "xc-token", value: @api_token },
        { header: "Authorization", value: "Bearer #{@api_token}" },
        { header: "xc-auth", value: @api_token },
        { header: "X-Auth-Token", value: @api_token }
      ]

      last_error = nil

      attempts.each do |attempt|
        begin
          response = self.class.get(
            url,
            headers: build_headers(attempt[:header], attempt[:value]),
            timeout: 10,
            verify: false
          )

          if response.success? || response.code == 200
            return { success: true, message: "Connected successfully", auth_method: attempt[:header] }
          end

          last_error = { header: attempt[:header], status: response.code, body: response.body }
        rescue Timeout::Error => e
          last_error = { header: attempt[:header], error: "Timeout: #{e.message}" }
        rescue StandardError => e
          last_error = { header: attempt[:header], error: e.message }
        end
      end

      {
        success: false,
        error: ErrorHandler.build_connection_error_message(last_error),
        last_error: last_error
      }
    end

    # Generic GET request
    def get(path, params: {})
      url = "#{@base_url}#{path}"
      response = self.class.get(url, headers: default_headers, query: params, timeout: 10, verify: false)

      ResponseHandler.handle(response)
    end

    # Generic POST request
    def post(path, body: {})
      url = "#{@base_url}#{path}"
      response = self.class.post(url, headers: default_headers, body: body.to_json, timeout: 10, verify: false)

      ResponseHandler.handle(response)
    end

    # Generic PUT request
    def put(path, body: {})
      url = "#{@base_url}#{path}"
      response = self.class.put(url, headers: default_headers, body: body.to_json, timeout: 10, verify: false)

      ResponseHandler.handle(response)
    end

    # Generic DELETE request
    def delete(path)
      url = "#{@base_url}#{path}"
      response = self.class.delete(url, headers: default_headers, timeout: 10, verify: false)

      ResponseHandler.handle(response)
    end

    private

    def extract_base_url(config)
      if config.respond_to?(:base_url)
        config.base_url
      elsif config.is_a?(Hash)
        config[:base_url] || config["base_url"]
      end
    end

    def extract_api_token(config)
      if config.respond_to?(:api_token)
        config.api_token
      elsif config.is_a?(Hash)
        config[:api_token] || config["api_token"]
      end
    end

    def normalize_url(url)
      url.end_with?("/") ? url[0..-2] : url
    end

    def default_headers
      {
        "xc-token" => @api_token,
        "Content-Type" => "application/json"
      }
    end

    def build_headers(auth_header, auth_value)
      {
        auth_header => auth_value,
        "Content-Type" => "application/json"
      }
    end
  end
end
