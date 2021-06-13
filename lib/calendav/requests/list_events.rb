# frozen_string_literal: true

require "nokogiri"

require_relative "../xml_processor"

module Calendav
  module Requests
    class ListEvents
      def self.call(...)
        new(...).call
      end

      def initialize(from:, to:)
        @from = from
        @to = to
      end

      def call
        Nokogiri::XML::Builder.new do |xml|
          xml["caldav"].public_send(
            "calendar-query", XMLProcessor::NAMESPACES
          ) do
            xml["dav"].prop do
              xml["dav"].getetag
              xml["caldav"].public_send(:"calendar-data")
            end
            xml["caldav"].filter do
              xml["caldav"].public_send(:"comp-filter", name: "VCALENDAR") do
                xml["caldav"].public_send(:"comp-filter", name: "VEVENT") do
                  xml["caldav"].public_send(
                    :"time-range",
                    start: from.utc.iso8601.delete(":-"),
                    end: to.utc.iso8601.delete(":-")
                  )
                end
              end
            end
          end
        end
      end

      private

      attr_reader :from, :to
    end
  end
end
