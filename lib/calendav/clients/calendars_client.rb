# frozen_string_literal: true

require "securerandom"

require_relative "../calendar"
require_relative "../requests/calendar_home_set"
require_relative "../requests/list_calendars"
require_relative "../requests/make_calendar"

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

          ContextualURL.call(
            credentials,
            endpoint
              .propfind(request.to_xml, url: client.principal_url)
              .xpath(".//caldav:calendar-home-set/dav:href")
              .text
          )
        end
      end

      def create(attributes)
        request = Requests::MakeCalendar.call(attributes)

        id = SecureRandom.uuid
        id = "/#{id}" unless home_url.end_with?("/")
        url = home_url + id

        endpoint.mkcalendar(request.to_xml, url: url)

        url
      end

      def delete(url)
        endpoint.delete(url: url)
      end

      def list
        request = Requests::ListCalendars.call
        calendar_xpath = ".//dav:resourcetype/caldav:calendar"

        endpoint
          .propfind(request.to_xml, url: home_url, depth: 1)
          .xpath(".//dav:response")
          .select { |node| node.xpath(calendar_xpath).any? }
          .collect { |node| Calendar.from_xml(node) }
      end

      private

      attr_reader :client, :endpoint, :credentials
    end
  end
end
