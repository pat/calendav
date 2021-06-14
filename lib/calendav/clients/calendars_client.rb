# frozen_string_literal: true

require "securerandom"

require_relative "../calendar"
require_relative "../requests/calendar_home_set"
require_relative "../requests/list_calendars"
require_relative "../requests/make_calendar"
require_relative "../requests/update_calendar"

module Calendav
  module Clients
    class CalendarsClient
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

      def find(url)
        list(url, depth: 0).first
      end

      def list(url = home_url, depth: 1)
        request = Requests::ListCalendars.call
        calendar_xpath = ".//dav:resourcetype/caldav:calendar"

        endpoint
          .propfind(request.to_xml, url: url, depth: depth)
          .select { |node| node.xpath(calendar_xpath).any? }
          .collect { |node| Calendar.from_xml(home_url, node) }
      end

      def options
        endpoint
          .options(url: home_url)
          .headers["Allow"]
          .split(", ")
      end

      def update(url, attributes)
        request = Requests::UpdateCalendar.call(attributes)
        endpoint
          .proppatch(request.to_xml, url: url)
          .first
          .xpath(".//dav:status")
          .text["200 OK"] == "200 OK"
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
