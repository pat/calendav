# frozen_string_literal: true

require_relative "./contextual_url"
require_relative "./parsers/calendar_xml"

module Calendav
  class Calendar
    attr_reader :url, :display_name, :description, :ctag, :etag, :time_zone,
                :color

    def self.from_xml(host, node)
      new(
        ContextualURL.call(host, node.xpath("./dav:href").text),
        Parsers::CalendarXML.call(node)
      )
    end

    def initialize(url, attributes = {})
      @url = url
      @display_name = attributes[:display_name]
      @description = attributes[:description]
      @ctag = attributes[:ctag]
      @etag = attributes[:etag]
      @time_zone = attributes[:time_zone]
      @color = attributes[:color]
    end
  end
end
