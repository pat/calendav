# frozen_string_literal: true

require "nokogiri"

module Calendav
  module Requests
    class FreeBusyQuery
      def self.call(...)
        new(...).call
      end

      # @param from [Time, String YYYYMMDDTHHMMSSZ (ISO8601 w/o dashes/colons)]
      # @param to [Time, String YYYYMMDDTHHMMSSZ (ISO8601 w/o dashes/colons)]
      def initialize(from:, to:)
        @from = from.instance_of?(Time) ? from.utc.iso8601.delete(":-") : from
        @to = to.instance_of?(Time) ? to.utc.iso8601.delete(":-") : to
      end

      def call
        Nokogiri::XML::Builder.new do |xml|
          xml["c"].public_send(:"free-busy-query",
                               "xmlns:c" => "urn:ietf:params:xml:ns:caldav") do
            xml["c"].public_send(:"time-range", start: @from, end: @to)
          end
        end
      end
    end
  end
end
