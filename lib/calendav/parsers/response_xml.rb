# frozen_string_literal: true

require_relative "../errors"
require_relative "../multi_response"
require_relative "../namespaces"

module Calendav
  module Parsers
    class ResponseXML
      def self.call(...)
        new(...).call
      end

      def initialize(raw, namespaces = NAMESPACES)
        @raw = raw
        @namespaces = namespaces
      end

      def call
        return document if document.xpath("/dav:multistatus").empty?

        MultiResponse.new(document)
      end

      private

      attr_reader :raw, :namespaces

      def document
        @document ||= begin
          initial = parse(raw)

          namespaces.each do |key, value|
            initial.root[key] = value unless initial.namespaces[key]
          end

          parse(initial.to_xml)
        end
      end

      def parse(string)
        Nokogiri::XML(string) { |config| config.strict.noblanks }
      rescue Nokogiri::XML::SyntaxError => error
        raise ParsingXMLError.new(string, error)
      end
    end
  end
end
