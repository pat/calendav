# frozen_string_literal: true

require_relative "contextual_url"
require_relative "parsers/todo_xml"

module Calendav
  class Todo
    ATTRIBUTES = %i[url calendar_data etag].freeze

    def self.from_xml(host, node)
      new(
        {
          url: ContextualURL.call(host, node.xpath("./dav:href").text)
        }.merge(
          Parsers::TodoXML.call(node)
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
      inner_todo.summary
    end

    def due
      inner_todo.due
    end

    def status
      inner_todo.status
    end

    def unloaded?
      calendar_data.nil?
    end

    private

    attr_reader :attributes

    def inner_calendar
      Icalendar::Calendar.parse(calendar_data).first
    end

    def inner_todo
      @inner_todo = inner_calendar.todos.first
    end
  end
end
