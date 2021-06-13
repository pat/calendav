# frozen_string_literal: true

require "icalendar"
require "icalendar/tzinfo"
require "securerandom"
require "uri"

RSpec.describe "Apple" do
  let(:provider) { :apple }
  let(:username) { ENV.fetch("APPLE_USERNAME") }
  let(:password) { ENV.fetch("APPLE_PASSWORD") }
  let(:credentials) { Calendav.credentials(provider, username, password) }

  subject { Calendav.client(credentials) }

  it "determines the user's principal URL" do
    expect(subject.principal_url)
      .to eq_encoded_url("https://caldav.icloud.com/20264203208/principal/")
  end

  it "determines the user's calendar URL" do
    expect(subject.calendars.home_url)
      .to eq_encoded_url("https://p49-caldav.icloud.com/20264203208/calendars/")
  end

  it "can create, find and delete calendars" do
    identifier = SecureRandom.uuid
    time_zone = TZInfo::Timezone.get "UTC"
    ical_time_zone = time_zone.ical_timezone Time.now.utc

    url = subject.calendars.create(
      identifier,
      display_name: "Calendav Test",
      description: "For test purposes only",
      color: "#00FF00",
      time_zone: ical_time_zone.to_ical
    )
    expect(url).to include(URI.decode_www_form_component(identifier))
    expect(url).to start_with("https://")

    calendars = subject.calendars.list
    expect(calendars.collect(&:display_name)).to include("Calendav Test")

    subject.calendars.delete(url)
  end

  context "with a calendar" do
    let(:calendar_url) do
      subject.calendars.create(SecureRandom.uuid, display_name: "Calendav Test")
    end
    let(:identifier) { "#{SecureRandom.uuid}.ics" }
    let(:start) { Time.new 2021, 6, 1, 10, 30 }
    let(:finish) { Time.new 2021, 6, 1, 12, 30 }

    after :each do
      subject.calendars.delete(calendar_url)
    end

    it "can create, find and delete events" do
      ics = Icalendar::Calendar.new
      ics.event do |event|
        event.dtstart = start.utc
        event.dtend = finish.utc
        event.summary = "Brunch"
      end
      ics.publish

      # Create an event
      event_url = subject.events.create(calendar_url, identifier, ics.to_ical)
      expect(event_url).to include(URI.decode_www_form_component(calendar_url))

      # Search for the event
      events = subject.events.list(
        calendar_url, from: Time.new(2021, 6, 1), to: Time.new(2021, 6, 2)
      )
      expect(events.length).to eq(1)
      expect(events.first.summary).to eq("Brunch")
      expect(events.first.url).to eq_encoded_url(event_url)

      # Update the event
      ics.events.first.dtstart = Time.new(2021, 7, 1, 10, 30).utc
      ics.events.first.dtend = Time.new(2021, 7, 1, 12, 30).utc
      subject.events.update(event_url, ics.to_ical)

      # Search again
      events = subject.events.list(
        calendar_url, from: Time.new(2021, 7, 1), to: Time.new(2021, 7, 2)
      )
      expect(events.length).to eq(1)
      expect(events.first.summary).to eq("Brunch")
      expect(events.first.url).to eq_encoded_url(event_url)

      # Delete the event
      expect(subject.events.delete(event_url)).to eq(true)
    end
  end
end
