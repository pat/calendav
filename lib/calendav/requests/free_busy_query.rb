# frozen_string_literal: true

require "nokogiri"

module Calendav
  module Requests
    class FreeBusyQuery
      def self.call(...)
        new(...).call
      end

      # @param from [Time, DateTime, String YYYYMMDDTHHMMSSZ (ISO8601 w/o dashes/colons)]
      # @param to [Time, DateTime, String YYYYMMDDTHHMMSSZ (ISO8601 w/o dashes/colons)]
      def initialize(from:, to:)
        @from = time_to_formatted_string(from)
        @to = time_to_formatted_string(to)
      end

      def call
        Nokogiri::XML::Builder.new do |xml|
          xml["c"].public_send(:"free-busy-query",
                               "xmlns:c" => "urn:ietf:params:xml:ns:caldav") do
            xml["c"].public_send(:"time-range", start: @from, end: @to)
          end
        end
      end

      private

      def time_to_formatted_string(time_obj)
        return time_obj unless time_obj.respond_to?(:utc)

        time_obj.utc.iso8601.delete(":-")
      end
    end
  end
end
