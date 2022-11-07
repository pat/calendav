# frozen_string_literal: true

require "nokogiri"

require_relative "../namespaces"

module Calendav
  module Requests
    class ListEvents
      def self.call(from:, to:)
        new(from: from, to: to).call
      end

      def initialize(from:, to:)
        @from = from
        @to = to
      end

      def call
        Nokogiri::XML::Builder.new do |xml|
          xml["caldav"].public_send("calendar-query", NAMESPACES) do
            xml["dav"].prop do
              xml["dav"].getetag
              xml["caldav"].public_send(:"calendar-data")
            end
            xml["caldav"].filter do
              xml["caldav"].public_send(:"comp-filter", name: "VCALENDAR") do
                xml["caldav"].public_send(:"comp-filter", name: "VEVENT") do
                  if range?
                    xml["caldav"].public_send(
                      :"time-range", start: from, end: to
                    )
                  end
                end
              end
            end
          end
        end
      end

      private

      def from
        return nil if @from.nil?

        @from.utc.iso8601.delete(":-")
      end

      def to
        return nil if @to.nil?

        @to.utc.iso8601.delete(":-")
      end

      def range?
        to || from
      end
    end
  end
end
