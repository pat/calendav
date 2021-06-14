# frozen_string_literal: true

require "nokogiri"

require_relative "../namespaces"

module Calendav
  module Requests
    class SyncCollection
      def self.call(...)
        new(...).call
      end

      def initialize(token)
        @token = token
      end

      def call
        Nokogiri::XML::Builder.new do |xml|
          xml["dav"].public_send(:"sync-collection", NAMESPACES) do
            xml["dav"].public_send(:"sync-token", token)
            xml["dav"].public_send(:"sync-level", 1)
            xml["dav"].prop do
              xml["dav"].getetag
              xml["caldav"].public_send(:"calendar-data")
            end
          end
        end
      end

      private

      attr_reader :token
    end
  end
end
