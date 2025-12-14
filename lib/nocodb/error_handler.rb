# frozen_string_literal: true

module Nocodb
  class ErrorHandler
    def self.build_connection_error_message(last_error)
      if last_error&.dig(:status)
        build_status_error_message(last_error[:status])
      elsif last_error&.dig(:error)
        build_generic_error_message(last_error[:error])
      else
        "Connection failed - All authentication methods failed"
      end
    end

    private_class_method def self.build_status_error_message(status)
      case status
      when 401
        "Unauthorized (401) - API token is invalid or expired"
      when 403
        "Forbidden (403) - Your account doesn't have permission to access this resource"
      when 404
        "Not Found (404) - Resource not found or base URL is incorrect"
      when 500..599
        "Server Error (#{status}) - NocoDB instance returned an error"
      else
        "Connection failed - HTTP #{status}"
      end
    end

    private_class_method def self.build_generic_error_message(error)
      if error.include?("Timeout")
        "Connection Timeout - NocoDB instance is not responding"
      elsif error.include?("Network")
        "Network Error - Cannot reach NocoDB instance"
      else
        "Connection Error: #{error}"
      end
    end
  end
end
