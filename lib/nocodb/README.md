# Nocodb Ruby Library

A Ruby library for interacting with NocoDB API with an ActiveRecord-like interface and session-based connection management.

## Features

- **Session-based API**: Thread-safe connection management using `Nocodb.session`
- **ActiveRecord-like Interface**: Familiar methods like `.all`, `.find`, `.where`
- **Separate Error & Response Handlers**: Clean separation of concerns
- **Custom Exceptions**: Specific error types for better error handling
- **Multi-tenant Support**: Each session is isolated, perfect for Rails multi-tenant apps

## Installation

The library is located in `lib/nocodb/` and is auto-loaded by Rails.

## Usage

### Basic Session Usage

```ruby
# Wrap all NocoDB operations in a session block
Nocodb.session(base_url: "https://nocodb.example.com", api_token: "your-token") do
  # All operations here use the same connection
  bases = Nocodb::Base.all
  puts bases.map(&:title)
end
```

### Working with Bases

```ruby
Nocodb.session(config) do
  # List all bases
  bases = Nocodb::Base.all
  
  # List bases in a specific workspace
  bases = Nocodb::Base.all(workspace_id: "ws_123")
  
  # Find a specific base
  base = Nocodb::Base.find("base_id")
  puts base.title
  puts base.type
  
  # Get full schema (base + tables)
  schema = Nocodb::Base.schema("base_id")
  puts schema[:base].title
  puts schema[:tables].count
  
  # Get tables from a base instance
  tables = base.tables
end
```

### Working with Tables

```ruby
Nocodb.session(config) do
  # List tables in a base
  tables = Nocodb::Table.where(base_id: "base_id")
  
  # Find a specific table
  table = Nocodb::Table.find("table_id")
  puts table.title
  puts table.table_name
  
  # Get detailed schema with columns
  schema = table.detailed_schema
  puts schema["columns"]
  
  # Get columns
  columns = table.columns
end
```

### Configuration Options

The session accepts:

1. **Hash configuration:**
```ruby
Nocodb.session(base_url: "...", api_token: "...") { }
```

2. **Object configuration (responds to `base_url` and `api_token`):**
```ruby
config = NocodbConfig.find(...)
Nocodb.session(config) { }
```

### Error Handling

The library provides specific exception types:

```ruby
begin
  Nocodb.session(config) do
    base = Nocodb::Base.find("invalid_id")
  end
rescue Nocodb::APIError => e
  # API returned an error response
  puts "Error: #{e.message}"
  puts "Status: #{e.status_code}"
  puts "Details: #{e.details}"
rescue Nocodb::ConnectionError => e
  # Connection failed
  puts "Connection error: #{e.message}"
rescue Nocodb::NoSessionError => e
  # Tried to use API outside of session block
  puts "No active session: #{e.message}"
rescue Nocodb::ConfigurationError => e
  # Invalid configuration
  puts "Config error: #{e.message}"
end
```

### Integration with Rails Service

The `NocodbApiService` wraps the library for backward compatibility:

```ruby
service = NocodbApiService.new(user, config)

# All methods return hash with :success key
result = service.verify_connection
# => { success: true, message: "Connected successfully", auth_method: "xc-token" }

result = service.list_bases
# => { success: true, bases: [...] }

result = service.get_base("base_id")
# => { success: true, base: {...} }
```

## Architecture

### Core Components

- **`Nocodb`**: Main module with session management
- **`Nocodb::Client`**: HTTP client handling requests
- **`Nocodb::Resource`**: Base class for models
- **`Nocodb::Base`**: Model for NocoDB bases
- **`Nocodb::Table`**: Model for NocoDB tables
- **`Nocodb::ResponseHandler`**: Parses and validates responses
- **`Nocodb::ErrorHandler`**: Builds error messages
- **`Nocodb::Error`** family: Custom exceptions

### Thread Safety

The library uses `Thread.current` to store the active client, ensuring:
- Each thread has its own isolated connection
- Perfect for multi-tenant Rails apps
- Works with Puma, Sidekiq, and other concurrent environments

## Examples

### Multi-tenant Usage

```ruby
# In a controller or service
def show
  config = current_user.nocodb_config
  
  Nocodb.session(config) do
    @bases = Nocodb::Base.all
    @tables = Nocodb::Table.where(base_id: params[:base_id])
  end
end
```

### Background Jobs

```ruby
class ImportNocodbSchemaJob < ApplicationJob
  def perform(user_id, base_id)
    user = User.find(user_id)
    config = { base_url: user.nocodb_url, api_token: user.nocodb_token }
    
    Nocodb.session(config) do
      schema = Nocodb::Base.schema(base_id)
      # Process schema...
    end
  end
end
```

## Future Enhancements

- Add CRUD operations for records
- Support for views and filters
- Webhook management
- Batch operations
- Query builder for complex filters
- Gem extraction for open-source release

## License

Part of the NotionForge SaaS application.
