# frozen_string_literal: true

module Calendav
  class XMLProcessor
    NAMESPACES = {
      "xmlns:dav" => "DAV:",
      "xmlns:caldav" => "urn:ietf:params:xml:ns:caldav",
      "xmlns:cs" => "http://calendarserver.org/ns/",
      "xmlns:apple" => "http://apple.com/ns/ical/"
    }.freeze

    def self.call(...)
      new(...).call
    end

    def initialize(raw, namespaces = NAMESPACES)
      @raw = raw
      @namespaces = namespaces
    end

    def call
      document = parse(raw)

      namespaces.each do |key, value|
        document.root[key] = value unless document.namespaces[key]
      end

      parse(document.to_xml)
    end

    private

    attr_reader :raw, :namespaces

    def parse(string)
      Nokogiri::XML(string) { |config| config.strict.noblanks }
    rescue Nokogiri::XML::SyntaxError
      puts string
      raise
    end
  end
end
