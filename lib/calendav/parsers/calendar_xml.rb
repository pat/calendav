# frozen_string_literal: true

module Calendav
  module Parsers
    class CalendarXML
      def self.call(...)
        new(...).call
      end

      def initialize(element)
        @element = element
      end

      def call
        {
          display_name: value(".//dav:displayname"),
          description: value(".//caldav:calendar-description"),
          ctag: value(".//cs:getctag"),
          etag: value(".//dav:getetag"),
          time_zone: value(".//caldav:calendar-timezone"),
          color: value(".//apple:calendar-color")
        }
      end

      private

      attr_reader :element

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
