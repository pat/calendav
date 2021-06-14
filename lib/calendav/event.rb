# frozen_string_literal: true

require_relative "./contextual_url"
require_relative "./parsers/event_xml"

module Calendav
  class Event
    attr_reader :url, :calendar_data, :etag

    def self.from_xml(host, node)
      new(
        ContextualURL.call(host, node.xpath("./dav:href").text),
        Parsers::EventXML.call(node)
      )
    end

    def initialize(url, attributes = {})
      @url = url
      @calendar_data = attributes[:calendar_data]
      @etag = attributes[:etag]
    end

    def summary
      inner_event.summary
    end

    private

    def inner_calendar
      Icalendar::Calendar.parse(calendar_data).first
    end

    def inner_event
      @inner_event = inner_calendar.events.first
    end
  end
end
