# frozen_string_literal: true

require "nokogiri"

require_relative "../namespaces"

module Calendav
  module Requests
    class ListCalendars
      def self.call(...)
        new(...).call
      end

      def call
        Nokogiri::XML::Builder.new do |xml|
          xml["dav"].propfind(NAMESPACES) do
            xml["dav"].prop do
              xml["dav"].displayname
              xml["dav"].resourcetype
              xml["dav"].getetag
              xml["cs"].getctag
              xml["apple"].public_send(:"calendar-color")
            end
          end
        end
      end
    end
  end
end
