# Nocodb Library - Quick Reference

## Installation & Setup

The library is auto-loaded by Rails from `lib/nocodb/`.

## Core API

### Session Management
```ruby
Nocodb.session(base_url: "...", api_token: "...") do
  # Your code here
end

# Or with config object
Nocodb.session(user.nocodb_config) do
  # Your code here
end
```

### Base Operations
```ruby
# List all bases
Nocodb::Base.all
# => [#<Nocodb::Base>, ...]

# List bases in workspace
Nocodb::Base.all(workspace_id: "ws_123")

# Find by ID
Nocodb::Base.find("base_id")
# => #<Nocodb::Base @id="base_id" @title="...">

# Get full schema
Nocodb::Base.schema("base_id")
# => { base: #<Nocodb::Base>, tables: [...] }

# Get tables from instance
base.tables
# => [#<Nocodb::Table>, ...]
```

### Table Operations
```ruby
# List tables in base
Nocodb::Table.where(base_id: "base_id")
# => [#<Nocodb::Table>, ...]

# Find by ID
Nocodb::Table.find("table_id")
# => #<Nocodb::Table @id="table_id" @title="...">

# Get detailed schema
table.detailed_schema
# => { "id" => "...", "columns" => [...], ... }

# Get columns
table.columns
# => [{ "id" => "...", "title" => "...", "type" => "..." }, ...]
```

## Error Handling

### Exception Types
```ruby
Nocodb::Error                 # Base error
Nocodb::NoSessionError        # No active session
Nocodb::ConfigurationError    # Invalid config
Nocodb::ConnectionError       # Connection failed
Nocodb::APIError              # API returned error
  .status_code                # HTTP status code
  .details                    # Detailed error info
```

### Rescue Pattern
```ruby
begin
  Nocodb.session(config) do
    Nocodb::Base.all
  end
rescue Nocodb::APIError => e
  puts "API Error (#{e.status_code}): #{e.message}"
  puts "Details: #{e.details}"
rescue Nocodb::ConnectionError => e
  puts "Connection failed: #{e.message}"
rescue Nocodb::Error => e
  puts "Error: #{e.message}"
end
```

## Rails Integration

### Controller
```ruby
class MyController < ApplicationController
  def index
    @bases = nocodb_session do
      Nocodb::Base.all
    end
  end
  
  private
  
  def nocodb_session(&block)
    Nocodb.session(current_user.nocodb_config, &block)
  end
end
```

### Service
```ruby
class MyService
  def initialize(user)
    @user = user
  end
  
  def perform
    Nocodb.session(@user.nocodb_config) do
      # Your logic
    end
  end
end
```

### Background Job
```ruby
class MyJob < ApplicationJob
  def perform(user_id)
    user = User.find(user_id)
    
    Nocodb.session(user.nocodb_config) do
      # Your logic
    end
  end
end
```

## Model Attributes

### Nocodb::Base
```ruby
base.id        # String - Base ID
base.title     # String - Base title
base.type      # String - Base type
base.data      # Hash - Full data
base.to_h      # Hash - Convert to hash
base.tables    # Array<Nocodb::Table> - Get tables
```

### Nocodb::Table
```ruby
table.id              # String - Table ID
table.title           # String - Table title
table.table_name      # String - Table name in DB
table.type            # String - Table type
table.data            # Hash - Full data
table.to_h            # Hash - Convert to hash
table.detailed_schema # Hash - Full schema with columns
table.columns         # Array - Column definitions
```

## Backward Compatibility

The original `NocodbApiService` still works:

```ruby
service = NocodbApiService.new(user, config)

service.verify_connection
# => { success: true/false, message: "...", ... }

service.list_bases(workspace_id = nil)
# => { success: true, bases: [...] }

service.get_base(base_id)
# => { success: true, base: {...} }

service.list_tables(base_id)
# => { success: true, tables: [...] }

service.get_table(table_id)
# => { success: true, table: {...} }

service.get_database_schema(base_id)
# => { success: true, base: {...}, tables: [...] }
```

## Testing

### Run Test Suite
```bash
ruby lib/nocodb/test_nocodb.rb
```

### Mock in Tests
```ruby
# RSpec
allow(Nocodb).to receive(:session).and_yield
allow(Nocodb::Base).to receive(:all).and_return([mock_base])

# Minitest
Nocodb.stub :session, -> { yield } do
  # Test code
end
```

## Configuration Examples

### Hash
```ruby
config = {
  base_url: "https://nocodb.example.com",
  api_token: "your_token_here"
}
```

### Object (ActiveRecord Model)
```ruby
class NocodbConfig < ApplicationRecord
  belongs_to :user
  
  # Must respond to:
  # - base_url
  # - api_token
end

config = NocodbConfig.find(...)
Nocodb.session(config) { ... }
```

### From Environment
```ruby
config = {
  base_url: ENV['NOCODB_URL'],
  api_token: ENV['NOCODB_TOKEN']
}
```

## Common Patterns

### Safe Fetch
```ruby
def fetch_bases
  Nocodb.session(config) do
    Nocodb::Base.all
  end
rescue Nocodb::Error => e
  Rails.logger.error("NocoDB error: #{e.message}")
  []
end
```

### With Caching
```ruby
def cached_bases
  Rails.cache.fetch("nocodb/bases", expires_in: 5.minutes) do
    Nocodb.session(config) do
      Nocodb::Base.all.map(&:to_h)
    end
  end
end
```

### Verify Connection
```ruby
def connection_valid?
  Nocodb.session(config) do
    client = Nocodb.current_client
    result = client.verify_connection
    result[:success]
  end
rescue Nocodb::Error
  false
end
```

## File Structure

```
lib/
├── nocodb.rb                    # Main module
└── nocodb/
    ├── base.rb                  # Base model
    ├── client.rb                # HTTP client
    ├── error_handler.rb         # Error builder
    ├── errors.rb                # Exceptions
    ├── resource.rb              # Base class
    ├── response_handler.rb      # Response parser
    ├── table.rb                 # Table model
    └── version.rb               # Version constant
```

## Links

- [README.md](README.md) - Full documentation
- [EXAMPLES.md](EXAMPLES.md) - Usage examples
- [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - Technical details
- [test_nocodb.rb](test_nocodb.rb) - Test suite

---

**Ready for open source!** 🚀
