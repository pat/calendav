# frozen_string_literal: true

require "icalendar"
require "securerandom"

module EventHelpers
  def event_identifier
    "#{SecureRandom.uuid}.ics"
  end

  def ical_event(summary, hour, minute)
    start = time_at(hour, minute)

    ics = Icalendar::Calendar.new

    ics.event do |event|
      event.dtstart = start
      event.dtend = start + 3600
      event.summary = summary
    end

    ics.tap(&:publish).to_ical
  end

  def time_at(hour, minute = 0)
    now = Time.now

    Time.utc(now.year, now.month, now.day, hour, minute)
  end

  def update_summary(event, summary)
    ics = Icalendar::Calendar.parse(event.calendar_data).first

    ics.events.first.summary = summary

    ics.to_ical
  end
end

RSpec.configure do |config|
  config.include EventHelpers
end
