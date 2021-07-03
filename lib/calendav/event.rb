# frozen_string_literal: true

require_relative "./contextual_url"
require_relative "./parsers/event_xml"

module Calendav
  class Event
    ATTRIBUTES = %i[url calendar_data etag].freeze

    def self.from_xml(host, node)
      new(
        {
          url: ContextualURL.call(host, node.xpath("./dav:href").text)
        }.merge(
          Parsers::EventXML.call(node)
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

    def summary
      inner_event.summary
    end

    def dtstart
      inner_event.dtstart
    end

    def dtend
      inner_event.dtend
    end

    def unloaded?
      calendar_data.nil?
    end

    private

    attr_reader :attributes

    def inner_calendar
      Icalendar::Calendar.parse(calendar_data).first
    end

    def inner_event
      @inner_event = inner_calendar.events.first
    end
  end
end
