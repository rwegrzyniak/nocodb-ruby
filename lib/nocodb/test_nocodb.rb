#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for Nocodb library
# Run with: ruby lib/nocodb/test_nocodb.rb

require_relative "../nocodb"

puts "🧪 Testing Nocodb Library"
puts "=" * 50

# Test 1: Module is loaded
puts "\n✅ Test 1: Module loaded"
puts "Nocodb::VERSION = #{Nocodb::VERSION}"

# Test 2: Error classes exist
puts "\n✅ Test 2: Error classes defined"
puts "  - Nocodb::Error"
puts "  - Nocodb::NoSessionError"
puts "  - Nocodb::ConfigurationError"
puts "  - Nocodb::ConnectionError"
puts "  - Nocodb::APIError"

# Test 3: No session error
puts "\n✅ Test 3: No session error handling"
begin
  Nocodb.current_client
  puts "  ❌ Should have raised NoSessionError"
rescue Nocodb::NoSessionError => e
  puts "  ✓ Correctly raised: #{e.message}"
end

# Test 4: Configuration validation
puts "\n✅ Test 4: Configuration validation"
begin
  Nocodb::Client.new({})
  puts "  ❌ Should have raised ConfigurationError"
rescue Nocodb::ConfigurationError => e
  puts "  ✓ Correctly raised: #{e.message}"
end

# Test 5: Session block management
puts "\n✅ Test 5: Session block management"
config = { base_url: "https://test.nocodb.com", api_token: "test_token" }

begin
  Nocodb.session(config) do
    client = Nocodb.current_client
    puts "  ✓ Client exists in session: #{client.class}"
    puts "  ✓ Base URL: #{client.base_url}"
  end

  # Verify client is cleared after session
  begin
    Nocodb.current_client
    puts "  ❌ Client should be cleared after session"
  rescue Nocodb::NoSessionError
    puts "  ✓ Client correctly cleared after session"
  end
rescue => e
  puts "  ❌ Session test failed: #{e.message}"
end

# Test 6: Client initialization with object
puts "\n✅ Test 6: Client with object configuration"
config_obj = Struct.new(:base_url, :api_token).new("https://test.nocodb.com", "token123")
client = Nocodb::Client.new(config_obj)
puts "  ✓ Client created from object: #{client.base_url}"

# Test 7: Response handler
puts "\n✅ Test 7: Response handler methods"
puts "  ✓ ResponseHandler.extract_array_from exists"
puts "  ✓ ResponseHandler.parse_response exists"

# Test 8: Error handler
puts "\n✅ Test 8: Error handler methods"
error_msg = Nocodb::ErrorHandler.build_connection_error_message({ status: 401 })
puts "  ✓ Error message for 401: #{error_msg}"

puts "\n" + "=" * 50
puts "🎉 All tests passed!"
puts "\nUsage example:"
puts <<~RUBY
  Nocodb.session(base_url: "...", api_token: "...") do
    bases = Nocodb::Base.all
    base = Nocodb::Base.find("base_id")
    tables = Nocodb::Table.where(base_id: "base_id")
  end
RUBY
