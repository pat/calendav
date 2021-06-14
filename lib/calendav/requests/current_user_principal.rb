# frozen_string_literal: true

require "nokogiri"

require_relative "../namespaces"

module Calendav
  module Requests
    class CurrentUserPrincipal
      def self.call(...)
        new(...).call
      end

      def call
        Nokogiri::XML::Builder.new do |xml|
          xml["dav"].propfind(NAMESPACES) do
            xml["dav"].prop do
              xml["dav"].public_send(:"current-user-principal")
            end
          end
        end
      end
    end
  end
end
