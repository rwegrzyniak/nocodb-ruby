# frozen_string_literal: true

module Nocodb
  class Table < Resource
    attr_reader :id, :title, :table_name, :type, :data

    def initialize(data)
      @data = data
      @id = data["id"]
      @title = data["title"]
      @table_name = data["table_name"]
      @type = data["type"]
    end

    class << self
      # List tables in a base
      # Nocodb::Table.where(base_id: "base_id")
      def where(base_id:)
        path = "/api/v2/meta/bases/#{base_id}/tables"
        response = client.get(path)
        tables_data = extract_array_from(response, %w[list tables data])
        tables_data.map { |table_data| new(table_data) }
      end

      # Find a specific table by ID
      # Nocodb::Table.find("table_id")
      def find(table_id)
        path = "/api/v2/meta/tables/#{table_id}"
        response = client.get(path)
        new(response)
      end
    end

    # Get detailed schema including columns
    def detailed_schema
      path = "/api/v2/meta/tables/#{@id}"
      client.get(path)
    end

    def columns
      schema = detailed_schema
      schema["columns"] || []
    end

    def to_h
      @data
    end
  end
end
