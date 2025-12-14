# frozen_string_literal: true

require_relative "lib/nocodb/version"

Gem::Specification.new do |spec|
  spec.name = "nocodb"
  spec.version = Nocodb::VERSION
  spec.authors = [ "NotionForge Team" ]
  spec.email = [ "team@notionforge.com" ]

  spec.summary = "Ruby ORM-like interface for NocoDB API"
  spec.description = "A Ruby library providing an elegant, ActiveRecord-inspired interface for interacting with NocoDB databases. Features session-based API, thread-safe operations, and comprehensive error handling."
  spec.homepage = "https://github.com/rwegrzyniak/nocodb-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/rwegrzyniak/nocodb-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/rwegrzyniak/nocodb-ruby/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir[
    "lib/**/*",
    "LICENSE",
    "README.md",
    "CHANGELOG.md"
  ]
  spec.require_paths = [ "lib" ]

  # Runtime dependencies
  spec.add_dependency "httparty", "~> 0.21"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "factory_bot", "~> 6.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
end
