# frozen_string_literal: true

require "nokogiri"

require_relative "../namespaces"

module Calendav
  module Requests
    class ListEvents
      def self.call(...)
        new(...).call
      end

      def initialize(from:, to:, expand_recurrences:)
        @from = from
        @to = to
        @expand_recurrences = expand_recurrences
      end

      def call
        Nokogiri::XML::Builder.new do |xml|
          xml["caldav"].public_send("calendar-query", NAMESPACES) do
            xml["dav"].prop do
              xml["dav"].getetag
              if @expand_recurrences && range?
                xml["caldav"].public_send(:"calendar-data") do
                  xml["caldav"].public_send(:"expand", start: from, end: to)
                end
              else
                xml["caldav"].public_send(:"calendar-data")
              end
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
