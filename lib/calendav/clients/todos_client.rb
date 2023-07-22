# frozen_string_literal: true

require_relative "../errors"
require_relative "../todo"
require_relative "../requests/list_todos"

module Calendav
  module Clients
    class TodosClient
      def initialize(client, endpoint, credentials)
        @client = client
        @endpoint = endpoint
        @credentials = credentials
      end

      def create(calendar_url, todo_identifier, ics)
        todo_url = merged_url(calendar_url, todo_identifier)
        result = endpoint.put(ics, url: todo_url, content_type: :ics)

        Todo.new(
          url: result.headers["Location"] || todo_url,
          etag: result.headers["ETag"]
        )
      end

      def delete(todo_url, etag: nil)
        endpoint.delete(url: todo_url, etag: etag)
      rescue PreconditionError
        false
      end

      def find(todo_url)
        response = endpoint.get(url: todo_url)

        Todo.new(
          url: todo_url,
          calendar_data: response.body.to_s,
          etag: response.headers["ETag"]
        )
      end

      def list(calendar_url)
        request = Requests::ListTodos.call

        endpoint
          .report(request.to_xml, url: calendar_url, depth: 1)
          .reject { |node| node.xpath(".//caldav:calendar-data").text.empty? }
          .collect { |node| Todo.from_xml(calendar_url, node) }
      end

      def update(todo_url, ics, etag: nil)
        result = endpoint.put(
          ics, url: todo_url, content_type: :ics, etag: etag
        )

        Todo.new(
          url: todo_url,
          etag: result.headers["ETag"]
        )
      rescue PreconditionError
        nil
      end

      private

      attr_reader :client, :endpoint, :credentials

      def merged_url(calendar_url, todo_identifier)
        "#{calendar_url.delete_suffix('/')}/#{todo_identifier}"
      end
    end
  end
end
