# frozen_string_literal: true

require_relative "../event"
require_relative "../requests/list_events"

module Calendav
  module Clients
    class EventsClient
      def initialize(client, endpoint, credentials)
        @client = client
        @endpoint = endpoint
        @credentials = credentials
      end

      def create(calendar_url, event_identifier, ics)
        url = merged_url(calendar_url, event_identifier)
        result = endpoint.put(ics, url: url, content_type: :ics)

        result.headers["Location"]
      end

      def delete(event_url)
        endpoint.delete(url: event_url)
      end

      def list(calendar_url, from:, to:)
        request = Requests::ListEvents.call(from: from, to: to)

        endpoint
          .report(request.to_xml, url: calendar_url, depth: 1)
          .xpath(".//dav:response")
          .collect { |node| Event.from_xml(node) }
      end

      private

      attr_reader :client, :endpoint, :credentials

      def merged_url(calendar_url, event_identifier)
        if calendar_url.end_with?("/")
          "#{calendar_url}#{event_identifier}"
        else
          "#{calendar_url}/#{event_identifier}"
        end
      end
    end
  end
end
