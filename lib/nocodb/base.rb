# frozen_string_literal: true

module Nocodb
  class Base < Resource
    attr_reader :id, :title, :type, :data

    def initialize(data)
      @data = data
      @id = data["id"]
      @title = data["title"]
      @type = data["type"]
    end

    class << self
      # List all bases
      # Nocodb::Base.all
      # Nocodb::Base.all(workspace_id: "ws_123")
      def all(workspace_id: nil)
        path = if workspace_id
          "/api/v2/workspaces/#{workspace_id}/bases"
        else
          "/api/v2/meta/bases"
        end

        response = client.get(path)
        bases_data = extract_array_from(response, %w[list bases data])
        bases_data.map { |base_data| new(base_data) }
      end

      # Find a specific base by ID
      # Nocodb::Base.find("base_id")
      def find(base_id)
        path = "/api/v2/meta/bases/#{base_id}"
        response = client.get(path)
        new(response)
      end

      # Get full schema for a base (including tables)
      # Nocodb::Base.schema("base_id")
      def schema(base_id)
        base = find(base_id)
        tables = Table.where(base_id: base_id)

        {
          base: base,
          tables: tables.map(&:detailed_schema)
        }
      end
    end

    # Instance methods
    def tables
      Table.where(base_id: @id)
    end

    def to_h
      @data
    end
  end
end
