# frozen_string_literal: true

module Calendav
  module Parsers
    class CalendarXML
      XPATHS = {
        display_name: ".//dav:displayname",
        description: ".//caldav:calendar-description",
        ctag: ".//cs:getctag",
        etag: ".//dav:getetag",
        time_zone: ".//caldav:calendar-timezone",
        color: ".//apple:calendar-color",
        sync_token: ".//dav:sync-token"
      }.freeze

      def self.call(element)
        new(element).call
      end

      def initialize(element)
        @element = element
      end

      def call
        XPATHS
          .transform_values { |xpath| value(xpath) }
          .merge(components: components, reports: reports)
      end

      private

      attr_reader :element

      def components
        element.xpath(
          ".//caldav:supported-calendar-component-set/caldav:comp"
        ).collect { |node| node["name"] }
      end

      def reports
        element.xpath(
          ".//dav:supported-report-set/dav:supported-report/dav:report/*"
        ).collect(&:name)
      end

      def value(xpath)
        node = element.xpath(xpath)
        return nil if node.children.empty?

        if node.children.any?(&:element?)
          node.children.select(&:element?).collect(&:to_xml).join
        else
          node.children.text
        end
      end
    end
  end
end
