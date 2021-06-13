# frozen_string_literal: true

require "nokogiri"

require_relative "../xml_processor"

module Calendav
  module Requests
    class CalendarHomeSet
      def self.call(...)
        new(...).call
      end

      def call
        Nokogiri::XML::Builder.new do |xml|
          xml["dav"].propfind(XMLProcessor::NAMESPACES) do
            xml["dav"].prop do
              xml["caldav"].public_send(:"calendar-home-set")
            end
          end
        end
      end
    end
  end
end
