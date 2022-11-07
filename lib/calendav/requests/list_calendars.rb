# frozen_string_literal: true

require "nokogiri"

require_relative "../namespaces"

module Calendav
  module Requests
    class ListCalendars
      PROPERTIES = [
        { key: :display_name, namespace: "dav", name: "displayname" },
        { key: :resource_type, namespace: "dav", name: "resourcetype" },
        { key: :etag, namespace: "dav", name: "getetag" },
        { key: :ctag, namespace: "cs", name: "getctag" },
        { key: :color, namespace: "apple", name: "calendar-color" },
        { key: :sync_token, namespace: "dav", name: "sync-token" },
        { key: :reports, namespace: "dav", name: "supported-report-set" },
        {
          key: :components,
          namespace: "caldav",
          name: "supported-calendar-component-set"
        }
      ].freeze

      def self.call(attributes)
        new(attributes).call
      end

      def initialize(attributes)
        @attributes = attributes
      end

      def call
        Nokogiri::XML::Builder.new do |xml|
          xml["dav"].propfind(NAMESPACES) do
            xml["dav"].prop do
              properties.each do |hash|
                xml[hash[:namespace]].public_send(hash[:name].to_sym)
              end
            end
          end
        end
      end

      private

      attr_reader :attributes

      def properties
        PROPERTIES.select { |hash| attributes.include?(hash[:key]) }
      end
    end
  end
end
