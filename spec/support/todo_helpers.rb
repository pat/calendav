# frozen_string_literal: true

# require "active_support"
require "icalendar"
require "securerandom"

module TodoHelpers
  def ical_todo(summary)
    ics = Icalendar::Calendar.new

    ics.todo do |todo|
      todo.uid = SecureRandom.uuid
      todo.dtstamp = Time.now.utc
      todo.summary = summary
    end

    ics.tap(&:publish).to_ical
  end

  def update_todo_summary(todo, summary)
    ics = Icalendar::Calendar.parse(todo.calendar_data).first

    ics.todos.first.summary = summary

    ics.to_ical
  end
end

RSpec.configure do |config|
  config.include TodoHelpers
end
