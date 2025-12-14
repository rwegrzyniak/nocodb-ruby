# Nocodb Library - Usage Examples

## Basic Usage

### List All Bases
```ruby
Nocodb.session(base_url: ENV['NOCODB_URL'], api_token: ENV['NOCODB_TOKEN']) do
  bases = Nocodb::Base.all
  
  bases.each do |base|
    puts "Base: #{base.title} (#{base.id})"
  end
end
```

### Get Base Details and Tables
```ruby
Nocodb.session(config) do
  base = Nocodb::Base.find("base_xyz")
  puts "Base: #{base.title}"
  
  tables = base.tables
  tables.each do |table|
    puts "  Table: #{table.title}"
  end
end
```

### Get Full Schema
```ruby
Nocodb.session(config) do
  schema = Nocodb::Base.schema("base_xyz")
  
  puts "Base: #{schema[:base].title}"
  puts "Tables:"
  
  schema[:tables].each do |table_schema|
    puts "  - #{table_schema['title']}"
    puts "    Columns: #{table_schema['columns'].count}"
  end
end
```

## Rails Integration Examples

### Controller Usage
```ruby
class NocodbBasesController < ApplicationController
  def index
    result = with_nocodb_session do
      Nocodb::Base.all
    end
    
    @bases = result
  end
  
  def show
    result = with_nocodb_session do
      base = Nocodb::Base.find(params[:id])
      { base: base, tables: base.tables }
    end
    
    @base = result[:base]
    @tables = result[:tables]
  rescue Nocodb::APIError => e
    flash[:error] = "Failed to load base: #{e.message}"
    redirect_to nocodb_bases_path
  end
  
  private
  
  def with_nocodb_session(&block)
    config = current_user.default_nocodb_config || current_user
    Nocodb.session(config, &block)
  end
end
```

### Service Object Pattern
```ruby
class NocodbSchemaImporter
  def initialize(user, base_id)
    @user = user
    @base_id = base_id
  end
  
  def import
    schema = fetch_schema
    save_schema(schema)
  end
  
  private
  
  def fetch_schema
    Nocodb.session(@user.nocodb_config) do
      Nocodb::Base.schema(@base_id)
    end
  end
  
  def save_schema(schema)
    # Save to your database
    ImportedBase.create!(
      user: @user,
      nocodb_base_id: @base_id,
      title: schema[:base].title,
      tables_count: schema[:tables].count
    )
    
    schema[:tables].each do |table_data|
      ImportedTable.create!(
        imported_base: imported_base,
        nocodb_table_id: table_data['id'],
        title: table_data['title'],
        columns: table_data['columns']
      )
    end
  end
end

# Usage
importer = NocodbSchemaImporter.new(current_user, "base_xyz")
importer.import
```

### Background Job
```ruby
class ImportNocodbSchemaJob < ApplicationJob
  queue_as :default
  
  def perform(user_id, base_id)
    user = User.find(user_id)
    
    schema = Nocodb.session(user.nocodb_config) do
      Nocodb::Base.schema(base_id)
    end
    
    process_schema(user, schema)
  rescue Nocodb::APIError => e
    # Log error or retry
    Rails.logger.error("NocoDB import failed: #{e.message} (#{e.status_code})")
    raise # Will retry the job
  end
  
  private
  
  def process_schema(user, schema)
    # Your import logic
  end
end
```

### Multi-tenant Helper
```ruby
module NocodbSessionHelper
  def with_nocodb(user = current_user, &block)
    config = if user.nocodb_configs.any?
      user.default_nocodb_config
    else
      {
        base_url: user.nocodb_integration_base_url,
        api_token: user.nocodb_integration_token
      }
    end
    
    Nocodb.session(config, &block)
  rescue Nocodb::ConfigurationError
    raise "Please configure NocoDB integration"
  end
end

# Usage in controller
class BasesController < ApplicationController
  include NocodbSessionHelper
  
  def index
    @bases = with_nocodb do
      Nocodb::Base.all
    end
  end
end
```

## Error Handling Patterns

### Graceful Degradation
```ruby
def fetch_bases_safely
  Nocodb.session(config) do
    Nocodb::Base.all
  end
rescue Nocodb::ConnectionError => e
  Rails.logger.warn("NocoDB unavailable: #{e.message}")
  [] # Return empty array
rescue Nocodb::APIError => e
  Rails.logger.error("NocoDB API error: #{e.message}")
  flash[:error] = "Failed to fetch bases"
  []
end
```

### Detailed Error Handling
```ruby
begin
  Nocodb.session(config) do
    Nocodb::Base.find("invalid_id")
  end
rescue Nocodb::APIError => e
  case e.status_code
  when 401
    # Token expired, refresh it
    refresh_nocodb_token
  when 404
    # Base not found
    flash[:error] = "Base not found"
  when 500..599
    # Server error, try again later
    flash[:error] = "NocoDB service temporarily unavailable"
  else
    # Unknown error
    flash[:error] = "An error occurred: #{e.message}"
  end
end
```

### Retry Pattern
```ruby
def fetch_with_retry(max_attempts: 3)
  attempts = 0
  
  begin
    attempts += 1
    
    Nocodb.session(config) do
      yield
    end
  rescue Nocodb::ConnectionError, Timeout::Error => e
    if attempts < max_attempts
      sleep(2 ** attempts) # Exponential backoff
      retry
    else
      raise
    end
  end
end

# Usage
bases = fetch_with_retry do
  Nocodb::Base.all
end
```

## Testing Examples

### RSpec Example
```ruby
RSpec.describe NocodbSchemaImporter do
  let(:user) { create(:user) }
  let(:base_id) { "base_xyz" }
  let(:config) { { base_url: "https://test.nocodb.com", api_token: "token" } }
  
  before do
    allow(user).to receive(:nocodb_config).and_return(config)
  end
  
  describe '#import' do
    it 'imports schema successfully' do
      # Mock the session
      allow(Nocodb).to receive(:session).and_yield
      
      # Mock the API calls
      mock_base = instance_double(Nocodb::Base, title: "Test Base", to_h: { id: base_id })
      allow(Nocodb::Base).to receive(:schema).and_return({
        base: mock_base,
        tables: [{ 'id' => 'table1', 'title' => 'Table 1', 'columns' => [] }]
      })
      
      importer = described_class.new(user, base_id)
      expect { importer.import }.to change(ImportedBase, :count).by(1)
    end
    
    it 'handles API errors gracefully' do
      allow(Nocodb).to receive(:session).and_raise(
        Nocodb::APIError.new("Not found", status_code: 404)
      )
      
      importer = described_class.new(user, base_id)
      expect { importer.import }.to raise_error(Nocodb::APIError)
    end
  end
end
```

### Controller Test Example
```ruby
RSpec.describe NocodbBasesController, type: :controller do
  let(:user) { create(:user, :with_nocodb_config) }
  
  before { sign_in user }
  
  describe 'GET #index' do
    it 'lists all bases' do
      mock_bases = [
        instance_double(Nocodb::Base, id: '1', title: 'Base 1', to_h: { id: '1' }),
        instance_double(Nocodb::Base, id: '2', title: 'Base 2', to_h: { id: '2' })
      ]
      
      allow(Nocodb).to receive(:session).and_yield
      allow(Nocodb::Base).to receive(:all).and_return(mock_bases)
      
      get :index
      
      expect(response).to be_successful
      expect(assigns(:bases)).to eq(mock_bases)
    end
  end
end
```

## Advanced Patterns

### Caching Pattern
```ruby
class CachedNocodbService
  def initialize(user)
    @user = user
  end
  
  def bases
    Rails.cache.fetch("nocodb/#{@user.id}/bases", expires_in: 5.minutes) do
      Nocodb.session(@user.nocodb_config) do
        Nocodb::Base.all.map(&:to_h)
      end
    end
  end
  
  def base_schema(base_id)
    Rails.cache.fetch("nocodb/#{@user.id}/base/#{base_id}", expires_in: 10.minutes) do
      Nocodb.session(@user.nocodb_config) do
        Nocodb::Base.schema(base_id)
      end
    end
  end
end
```

### Parallel Processing
```ruby
def import_multiple_bases(user, base_ids)
  results = Parallel.map(base_ids, in_threads: 5) do |base_id|
    Nocodb.session(user.nocodb_config) do
      {
        base_id: base_id,
        schema: Nocodb::Base.schema(base_id)
      }
    end
  rescue Nocodb::Error => e
    {
      base_id: base_id,
      error: e.message
    }
  end
  
  results
end
```

### Rate Limiting
```ruby
class RateLimitedNocodbClient
  RATE_LIMIT = 100 # requests per minute
  
  def initialize(user)
    @user = user
    @limiter = Redis::RateLimiter.new("nocodb:#{user.id}", limit: RATE_LIMIT)
  end
  
  def fetch_bases
    @limiter.within_limit do
      Nocodb.session(@user.nocodb_config) do
        Nocodb::Base.all
      end
    end
  rescue Redis::RateLimiter::LimitExceeded
    raise "Rate limit exceeded. Please try again later."
  end
end
```

## Migration from Old Service

### Before (Old Service)
```ruby
service = NocodbApiService.new(user)
result = service.list_bases

if result[:success]
  bases = result[:bases]
else
  error = result[:error]
end
```

### After (New Library)
```ruby
begin
  bases = Nocodb.session(user.nocodb_config) do
    Nocodb::Base.all.map(&:to_h)
  end
rescue Nocodb::Error => e
  error = e.message
end
```

### Or Keep Using Service (Backward Compatible)
```ruby
service = NocodbApiService.new(user)
result = service.list_bases # Still works!

if result[:success]
  bases = result[:bases]
end
```
