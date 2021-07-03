# frozen_string_literal: true

require_relative "./contextual_url"
require_relative "./parsers/calendar_xml"

module Calendav
  class Calendar
    ATTRIBUTES = %i[
      url display_name description ctag etag time_zone color components reports
      sync_token
    ].freeze

    def self.from_xml(host, node)
      new(
        {
          url: ContextualURL.call(host, node.xpath("./dav:href").text)
        }.merge(
          Parsers::CalendarXML.call(node)
        )
      )
    end

    def initialize(attributes = {})
      @attributes = attributes
    end

    ATTRIBUTES.each do |attribute|
      define_method(attribute) { attributes[attribute] }
    end

    def to_h
      attributes.dup
    end

    private

    attr_reader :attributes
  end
end
