# frozen_string_literal: true

module Calendav
  module Parsers
    class TodoXML
      def self.call(...)
        new(...).call
      end

      def initialize(element)
        @element = element
      end

      def call
        {
          calendar_data: value(".//caldav:calendar-data"),
          etag: value(".//dav:getetag")
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
