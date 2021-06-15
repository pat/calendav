# frozen_string_literal: true

require "icalendar"
require "icalendar/tzinfo"
require "securerandom"
require "uri"

RSpec.describe "Radicale" do
  let(:provider) { :radicale }
  let(:username) { ENV.fetch("RADICALE_USERNAME") }
  let(:password) { ENV.fetch("RADICALE_PASSWORD") }
  let(:host) { ENV.fetch("RADICALE_HOST") }
  let(:credentials) do
    Calendav::Credentials::Standard.new(
      host: host,
      username: username,
      password: password,
      authentication: :basic_auth
    )
  end

  subject { Calendav.client(credentials) }

  it "determines the user's principal URL" do
    expect(subject.principal_url)
      .to eq_encoded_url("#{host}/test/")
  end

  it "determines the user's calendar URL" do
    expect(subject.calendars.home_url)
      .to eq_encoded_url("#{host}/test/")
  end

  it "supports calendar creation" do
    expect(subject.calendars.create?).to eq(true)
  end

  it "can create, find, update and delete calendars" do
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
    expect(url).to start_with("#{host}/test/")

    calendars = subject.calendars.list
    expect(calendars.collect(&:display_name)).to include("Calendav Test")

    expect(
      subject.calendars.update(url, display_name: "Calendav Update")
    ).to eq(true)

    calendars = subject.calendars.list
    expect(calendars.collect(&:display_name)).to include("Calendav Update")

    subject.calendars.delete(url)
  end

  context "with a calendar" do
    let(:calendar_url) do
      subject.calendars.create(SecureRandom.uuid, display_name: "Calendav Test")
    end
    let(:calendar) { subject.calendars.find(calendar_url) }
    let(:identifier) { "#{SecureRandom.uuid}.ics" }
    let(:start) { Time.new 2021, 6, 1, 10, 30 }
    let(:finish) { Time.new 2021, 6, 1, 12, 30 }

    after :each do
      subject.calendars.delete(calendar_url)
    end

    it "supports events" do
      expect(calendar.components).to include("VEVENT")
    end

    it "supports WebDAV-Sync" do
      expect(calendar.reports).to include("sync-collection")
    end

    it "can create, find, update and delete events" do
      ics = Icalendar::Calendar.new
      ics.event do |event|
        event.dtstart = start.utc
        event.dtend = finish.utc
        event.summary = "Brunch"
      end
      ics.publish

      # Create an event
      event_url = subject.events.create(calendar.url, identifier, ics.to_ical)
      expect(event_url).to include(URI.decode_www_form_component(calendar.url))

      # Search for the event
      events = subject.events.list(
        calendar.url, from: Time.new(2021, 6, 1), to: Time.new(2021, 6, 2)
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
        calendar.url, from: Time.new(2021, 7, 1), to: Time.new(2021, 7, 2)
      )
      expect(events.length).to eq(1)
      expect(events.first.summary).to eq("Brunch")
      expect(events.first.url).to eq_encoded_url(event_url)

      # Create another event
      ics = Icalendar::Calendar.new
      ics.event do |event|
        event.dtstart = start.utc
        event.dtend = finish.utc
        event.summary = "Brunch"
      end
      ics.publish

      another_url = subject.events.create(
        calendar.url, "#{SecureRandom.uuid}.ics", ics.to_ical
      )

      # Search for all events
      events = subject.events.list(calendar.url)
      expect(events.length).to eq(2)

      # Delete the events
      expect(subject.events.delete(event_url)).to eq(true)
      expect(subject.events.delete(another_url)).to eq(true)
    end

    it "respects etag conditions with updates and deletions" do
      ics = Icalendar::Calendar.new
      ics.event do |event|
        event.dtstart = start.utc
        event.dtend = finish.utc
        event.summary = "Brunch"
      end
      ics.publish

      event_url = subject.events.create(calendar.url, identifier, ics.to_ical)
      event = subject.events.find(event_url)

      ics.events.first.summary = "Coffee"
      expect(
        subject.events.update(event_url, ics.to_ical, etag: event.etag)
      ).to eq(true)

      expect(subject.events.find(event_url).summary).to eq("Coffee")

      # Updating with the old etag should fail
      ics.events.first.summary = "Brunch"
      expect(
        subject.events.update(event_url, ics.to_ical, etag: event.etag)
      ).to eq(false)

      expect(subject.events.find(event_url).summary).to eq("Coffee")

      expect(subject.events.delete(event_url, etag: event.etag)).to eq(false)
      expect(subject.events.delete(event_url)).to eq(true)
    end

    it "handles synchronisation requests" do
      first = Icalendar::Calendar.new
      first.event do |event|
        event.dtstart = start.utc
        event.dtend = finish.utc
        event.summary = "Brunch"
      end
      first.publish

      first_url = subject.events.create(calendar.url, identifier, first.to_ical)
      token = subject.calendars.find(calendar.url, sync: true).sync_token

      events = subject.events.list(calendar.url)
      expect(events.length).to eq(1)

      second = Icalendar::Calendar.new
      second.event do |event|
        event.dtstart = start.utc
        event.dtend = finish.utc
        event.summary = "Brunch Again"
      end
      second.publish
      second_url = subject.events.create(
        calendar.url, "#{SecureRandom.uuid}.ics", second.to_ical
      )

      first.events.first.summary = "Coffee"
      subject.events.update(first_url, first.to_ical)

      collection = subject.calendars.sync(calendar.url, token)
      expect(collection.changes.collect(&:url))
        .to match_encoded_urls([first_url, second_url])

      expect(collection.deletions).to be_empty

      first.events.first.summary = "Brunch"
      subject.events.update(first_url, first.to_ical)

      subject.events.delete(second_url)

      collection = subject.calendars.sync(calendar.url, collection.sync_token)
      urls = collection.changes.collect(&:url)
      expect(urls.length).to eq(1)
      expect(urls[0]).to eq_encoded_url(first_url)

      expect(collection.deletions.length).to eq(1)
      expect(collection.deletions.first).to eq_encoded_url(second_url)

      subject.events.delete(first_url)
    end
  end
end
