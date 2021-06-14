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
        update merged_url(calendar_url, event_identifier), ics
      end

      def delete(event_url)
        endpoint.delete(url: event_url)
      end

      def list(calendar_url, from: nil, to: nil)
        request = Requests::ListEvents.call(from: from, to: to)

        endpoint
          .report(request.to_xml, url: calendar_url, depth: 1)
          .xpath(".//dav:response")
          .reject { |node| node.xpath(".//caldav:calendar-data").text.empty? }
          .collect { |node| Event.from_xml(calendar_url, node) }
      end

      def update(event_url, ics)
        result = endpoint.put(ics, url: event_url, content_type: :ics)

        result.headers["Location"] || event_url
      end

      private

      attr_reader :client, :endpoint, :credentials

      def merged_url(calendar_url, event_identifier)
        "#{calendar_url.delete_suffix('/')}/#{event_identifier}"
      end
    end
  end
end
