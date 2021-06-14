# frozen_string_literal: true

require_relative "./namespaces"

module Calendav
  class XMLProcessor
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
