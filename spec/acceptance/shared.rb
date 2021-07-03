# frozen_string_literal: true

require "icalendar"
require "icalendar/tzinfo"
require "securerandom"
require "uri"

RSpec.shared_examples "supporting calendar management" do
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
    expect(url).to start_with(host)

    calendars = subject.calendars.list
    expect(calendars.collect(&:display_name)).to include("Calendav Test")

    expect(
      subject.calendars.update(url, display_name: "Calendav Update")
    ).to eq(true)

    calendars = subject.calendars.list
    expect(calendars.collect(&:display_name)).to include("Calendav Update")

    subject.calendars.delete(url)
  end
end

RSpec.shared_examples "supporting event management" do
  it "supports events" do
    expect(calendar.components).to include("VEVENT")
  end

  it "supports WebDAV-Sync" do
    expect(calendar.reports).to include("sync-collection")
  end

  it "can create, find, update and delete events" do
    # Create an event
    event_url = subject.events.create(
      calendar.url, event_identifier, ical_event("Brunch", 10, 30)
    )
    expect(event_url).to include(URI.decode_www_form_component(calendar.url))
    event = subject.events.find(event_url)

    # Search for the event
    events = subject.events.list(
      calendar.url, from: time_at(0, 0), to: time_at(23, 59)
    )
    expect(events.length).to eq(1)
    expect(events.first.summary).to eq("Brunch")
    expect(events.first.dtstart.to_time).to eq(time_at(10, 30))
    expect(events.first.url).to eq_encoded_url(event_url)

    # Update the event
    subject.events.update(event_url, update_summary(event, "Coffee"))

    # Search again
    events = subject.events.list(
      calendar.url, from: time_at(0, 0), to: time_at(23, 59)
    )
    expect(events.length).to eq(1)
    expect(events.first.summary).to eq("Coffee")
    expect(events.first.dtstart.to_time).to eq(time_at(10, 30))
    expect(events.first.url).to eq_encoded_url(event_url)

    # Create another event
    another_url = subject.events.create(
      calendar.url, event_identifier, ical_event("Brunch", 10, 30)
    )

    # Search for all events
    events = subject.events.list(calendar.url)
    expect(events.length).to eq(2)

    # Delete the events
    expect(subject.events.delete(event_url)).to eq(true)
    expect(subject.events.delete(another_url)).to eq(true)
  end

  it "respects etag conditions with updates" do
    event_url = subject.events.create(
      calendar.url, event_identifier, ical_event("Brunch", 10, 30)
    )
    event = subject.events.find(event_url)

    expect(
      subject.events.update(
        event_url, update_summary(event, "Coffee"), etag: event.etag
      )
    ).to eq(true)

    expect(subject.events.find(event_url).summary).to eq("Coffee")

    # Wait for server to catch up
    sleep 1

    # Updating with the old etag should fail
    expect(
      subject.events.update(
        event_url, update_summary(event, "Brunch"), etag: event.etag
      )
    ).to eq(false)

    expect(subject.events.find(event_url).summary).to eq("Coffee")

    expect(subject.events.delete(event_url)).to eq(true)
  end

  it "handles synchronisation requests" do
    first_url = subject.events.create(
      calendar.url, event_identifier, ical_event("Brunch", 10, 30)
    )
    first = subject.events.find(first_url)
    token = subject.calendars.find(calendar.url, sync: true).sync_token

    events = subject.events.list(calendar.url)
    expect(events.length).to eq(1)

    second_url = subject.events.create(
      calendar.url, event_identifier, ical_event("Brunch Again", 11, 30)
    )

    subject.events.update(first_url, update_summary(first, "Coffee"))
    first = subject.events.find(first_url)

    collection = subject.calendars.sync(calendar.url, token)
    expect(collection.changes.collect(&:url))
      .to match_encoded_urls([first_url, second_url])

    expect(collection.deletions).to be_empty

    subject.events.update(first_url, update_summary(first, "Brunch"))
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

RSpec.shared_examples "supporting event deletion with etags" do
  it "respects etag conditions with deletions" do
    event_url = subject.events.create(
      calendar.url, event_identifier, ical_event("Brunch", 10, 30)
    )
    event = subject.events.find(event_url)

    expect(
      subject.events.update(
        event_url, update_summary(event, "Coffee"), etag: event.etag
      )
    ).to eq(true)
    expect(subject.events.find(event_url).summary).to eq("Coffee")

    expect(subject.events.delete(event_url, etag: event.etag)).to eq(false)
    expect(subject.events.delete(event_url)).to eq(true)
  end
end
