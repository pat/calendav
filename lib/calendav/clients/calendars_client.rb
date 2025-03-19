# frozen_string_literal: true

require "securerandom"
require "icalendar"

require_relative "../calendar"
require_relative "../components/freebusy"
require_relative "../parsers/sync_xml"
require_relative "../requests/calendar_home_set"
require_relative "../requests/list_calendars"
require_relative "../requests/make_calendar"
require_relative "../requests/sync_collection"
require_relative "../requests/update_calendar"
require_relative "../requests/free_busy_query"

module Calendav
  module Clients
    class CalendarsClient
      DEFAULT_ATTRIBUTES = %i[
        display_name resource_type etag ctag color components reports
      ].freeze

      def initialize(client, endpoint, credentials)
        @client = client
        @endpoint = endpoint
        @credentials = credentials
      end

      def home_url
        @home_url ||= begin
          request = Requests::CalendarHomeSet.call
          response = endpoint.propfind(request.to_xml, url: principal_url).first

          ContextualURL.call(
            credentials.host,
            response.xpath(".//caldav:calendar-home-set/dav:href").text
          )
        end
      end

      def create?
        options.include?("MKCOL") || options.include?("MKCALENDAR")
      end

      def create(identifier, attributes)
        request = Requests::MakeCalendar.call(attributes)
        url = merged_url(identifier)
        result = endpoint.mkcalendar(request.to_xml, url: url)

        result.headers["Location"] || url
      end

      def delete(url)
        endpoint.delete(url: url)
      end

      def find(url, attributes: DEFAULT_ATTRIBUTES, sync: false)
        attributes = (attributes.dup << :sync_token) if sync

        list(url, depth: 0, attributes: attributes).first
      end

      def list(url = home_url, depth: 1, attributes: DEFAULT_ATTRIBUTES)
        request = Requests::ListCalendars.call(attributes)
        calendar_xpath =
          "//d:response[d:propstat/d:prop/cal:supported-calendar-component-set]"

        endpoint
          .propfind(request.to_xml, url: url, depth: depth)
          .select { |node| node.xpath(calendar_xpath).any? }
          .collect { |node| Calendar.from_xml(url, node) }
      end

      def options
        endpoint
          .options(url: home_url)
          .headers["Allow"]
          .split(", ")
      end

      def sync(url, token)
        request = Requests::SyncCollection.call(token)

        Parsers::SyncXML.call(
          url, endpoint.report(request.to_xml, url: url, depth: nil)
        )
      end

      def update(url, attributes)
        request = Requests::UpdateCalendar.call(attributes)
        endpoint
          .proppatch(request.to_xml, url: url)
          .first
          .xpath(".//dav:status")
          .text["200 OK"] == "200 OK"
      end

      def freebusy(url, from:, to:)
        request = Requests::FreeBusyQuery.call(from: from, to: to)
        response = endpoint.report(request.to_xml, url: url, depth: 1)
        Components::Freebusy.from_http_response(response)
      end

      private

      attr_reader :client, :endpoint, :credentials

      def merged_url(identifier)
        "#{home_url.delete_suffix('/')}/#{identifier.delete_suffix('/')}/"
      end

      def principal_url
        client.principal_url
      end
    end
  end
end
