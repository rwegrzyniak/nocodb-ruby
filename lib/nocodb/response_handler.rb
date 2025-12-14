# frozen_string_literal: true

module Nocodb
  class ResponseHandler
    def self.handle(response)
      parsed = parse_response(response)

      if response.success?
        parsed
      else
        error_info = build_error_payload(response, parsed)
        raise APIError.new(
          error_info[:message],
          status_code: response.code,
          details: error_info[:details]
        )
      end
    end

    def self.parse_response(response)
      response.respond_to?(:parsed_response) ? response.parsed_response : nil
    rescue StandardError
      nil
    end

    def self.extract_array_from(parsed, preferred_keys)
      return parsed if parsed.is_a?(Array)
      return [] unless parsed.is_a?(Hash)

      preferred_keys.each do |key|
        # Try both string and symbol versions of the key
        value = parsed[key] || parsed[key.to_s] || parsed[key.to_sym]
        return value if value.is_a?(Array)
      end

      []
    end

    private_class_method def self.build_error_payload(response, parsed)
      status = response.respond_to?(:code) ? response.code : nil
      message = status ? "API request failed (HTTP #{status})" : "API request failed"

      detail = extract_detail(parsed, response)

      { message: message, details: detail&.to_s&.strip }
    end

    private_class_method def self.extract_detail(parsed, response)
      if parsed.is_a?(Hash)
        parsed["detail"] || parsed["details"] || parsed["message"] ||
        parsed["error"] || parsed["msg"]
      elsif parsed.present?
        parsed.to_s
      elsif response.respond_to?(:body)
        response.body.to_s
      end
    end
  end
end
