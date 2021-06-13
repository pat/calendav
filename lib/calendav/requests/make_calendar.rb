# frozen_string_literal: true

require "nokogiri"

require_relative "../xml_processor"

module Calendav
  module Requests
    class MakeCalendar
      def self.call(...)
        new(...).call
      end

      def initialize(attributes)
        @attributes = attributes
      end

      def call
        Nokogiri::XML::Builder.new do |xml|
          xml["caldav"].propfind(XMLProcessor::NAMESPACES) do
            xml["dav"].set do
              xml["dav"].prop do
                xml["dav"].displayname display_name

                if description
                  xml["caldav"].public_send(
                    :"calendar-description", description
                  )
                end

                if time_zone
                  xml["caldav"].public_send(:"calendar-timezone", time_zone)
                end

                xml["caldav"].public_send(
                  :"supported-calendar-component-set"
                ) do
                  xml["caldav"].comp name: "VEVENT"
                end
              end
            end
          end
        end
      end

      private

      attr_reader :attributes

      def display_name
        attributes[:display_name]
      end

      def description
        attributes[:description]
      end

      def time_zone
        attributes[:time_zone]
      end
    end
  end
end
