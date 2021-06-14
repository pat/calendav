# frozen_string_literal: true

require "uri"

require_relative "../sync_collection"

module Calendav
  module Parsers
    class SyncXML
      def self.call(...)
        new(...).call
      end

      def initialize(calendar_url, multi_response)
        @calendar_url = calendar_url
        @multi_response = multi_response
      end

      def call
        SyncCollection.new(events, deleted_urls, token)
      end

      private

      attr_reader :calendar_url, :multi_response

      def deleted_urls
        individual_responses
          .select { |node| node.xpath("./dav:status").text["404 Not Found"] }
          .collect { |node| response_url(node) }
      end

      def events
        individual_responses
          .reject { |node| node.xpath("./dav:status").text["404 Not Found"] }
          .collect { |node| Event.from_xml(calendar_url, node) }
      end

      def calendar_path
        @calendar_path ||= URI(calendar_url).path
      end

      def individual_responses
        multi_response
          .reject { |node| node.xpath("./dav:href").text == calendar_path }
      end

      def token
        multi_response.xpath("/dav:multistatus/dav:sync-token").text
      end

      def response_url(response)
        ContextualURL.call(calendar_url, response.xpath("./dav:href").text)
      end
    end
  end
end
