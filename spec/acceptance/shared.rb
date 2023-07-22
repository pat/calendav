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
    identifier = "calendav-test"
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
    event_result = subject.events.create(
      calendar.url, "calendav-event-1.ics", ical_event("Brunch", 10, 30)
    )
    expect(event_result.url)
      .to include(URI.decode_www_form_component(calendar.url))
    event = subject.events.find(event_result.url)

    # Search for the event
    events = subject.events.list(
      calendar.url, from: time_at(0, 0), to: time_at(23, 59)
    )
    expect(events.length).to eq(1)
    expect(events.first.summary).to eq("Brunch")
    expect(events.first.dtstart.to_time).to eq(time_at(10, 30))
    expect(events.first.url).to eq_encoded_url(event_result.url)

    # Update the event
    subject.events.update(event_result.url, update_summary(event, "Coffee"))

    # Search again
    events = subject.events.list(
      calendar.url, from: time_at(0, 0), to: time_at(23, 59)
    )
    expect(events.length).to eq(1)
    expect(events.first.summary).to eq("Coffee")
    expect(events.first.dtstart.to_time).to eq(time_at(10, 30))
    expect(events.first.url).to eq_encoded_url(event_result.url)

    # Create another event
    another_result = subject.events.create(
      calendar.url, "calendav-event-2.ics", ical_event("Brunch", 10, 30)
    )

    # Search for all events
    events = subject.events.list(calendar.url)
    expect(events.length).to eq(2)

    # Delete the events
    expect(subject.events.delete(event_result.url)).to eq(true)
    expect(subject.events.delete(another_result.url)).to eq(true)
  end

  it "respects etag conditions with updates" do
    event_result = subject.events.create(
      calendar.url, "calendav-event.ics", ical_event("Brunch", 10, 30)
    )
    event = subject.events.find(event_result.url)

    expect(
      subject.events.update(
        event_result.url, update_summary(event, "Coffee"), etag: event.etag
      )
    ).not_to be_nil

    expect(subject.events.find(event_result.url).summary).to eq("Coffee")

    # Wait for server to catch up
    sleep 1

    # Updating with the old etag should fail
    expect(
      subject.events.update(
        event_result.url, update_summary(event, "Brunch"), etag: event.etag
      )
    ).to be_nil

    expect(subject.events.find(event_result.url).summary).to eq("Coffee")

    expect(subject.events.delete(event_result.url)).to eq(true)
  end

  it "handles synchronisation requests" do
    first_result = subject.events.create(
      calendar.url, "calendav-event-1.ics", ical_event("Brunch", 10, 30)
    )
    first = subject.events.find(first_result.url)
    token = subject.calendars.find(calendar.url, sync: true).sync_token

    events = subject.events.list(calendar.url)
    expect(events.length).to eq(1)

    second_result = subject.events.create(
      calendar.url, "calendav-event-2.ics", ical_event("Brunch Again", 11, 30)
    )

    subject.events.update(first_result.url, update_summary(first, "Coffee"))
    first = subject.events.find(first_result.url)

    collection = subject.calendars.sync(calendar.url, token)
    expect(collection.changes.collect(&:url))
      .to match_encoded_urls([first_result.url, second_result.url])

    expect(collection.deletions).to be_empty
    expect(collection.more?).to eq(false)

    subject.events.update(first_result.url, update_summary(first, "Brunch"))
    subject.events.delete(second_result.url)

    collection = subject.calendars.sync(calendar.url, collection.sync_token)
    urls = collection.changes.collect(&:url)
    expect(urls.length).to eq(1)
    expect(urls[0]).to eq_encoded_url(first_result.url)

    expect(collection.deletions.length).to eq(1)
    expect(collection.deletions.first).to eq_encoded_url(second_result.url)
    expect(collection.more?).to eq(false)

    subject.events.delete(first_result.url)
  end
end

RSpec.shared_examples "supporting event deletion with etags" do
  it "respects etag conditions with deletions" do
    event_result = subject.events.create(
      calendar.url, "calendav-event.ics", ical_event("Brunch", 10, 30)
    )
    event = subject.events.find(event_result.url)

    expect(
      subject.events.update(
        event_result.url, update_summary(event, "Coffee"), etag: event.etag
      )
    ).not_to be_nil
    expect(subject.events.find(event_result.url).summary).to eq("Coffee")

    expect(
      subject.events.delete(event_result.url, etag: event.etag)
    ).to eq(false)
    expect(subject.events.delete(event_result.url)).to eq(true)
  end
end

RSpec.shared_examples "supporting todo management" do
  it "supports events" do
    expect(calendar.components).to include("VTODO")
  end

  it "can create, find, update and delete todos" do
    # Create an event
    todo_result = subject.todos.create(
      calendar.url, "calendav-todo-1.ics", ical_todo("Todo 1")
    )
    expect(todo_result.url)
      .to include(URI.decode_www_form_component(calendar.url))
    todo = subject.todos.find(todo_result.url)

    # Search for the todo
    todos = subject.todos.list(calendar.url)
    expect(todos.length).to eq(1)
    expect(todos.first.summary).to eq("Todo 1")
    expect(todos.first.url).to eq_encoded_url(todo_result.url)

    # Update the event
    subject.events.update(todo_result.url,
                          update_todo_summary(todo, "Todo 2"))

    # Search again
    todos = subject.todos.list(calendar.url)
    expect(todos.length).to eq(1)
    expect(todos.first.summary).to eq("Todo 2")
    expect(todos.first.url).to eq_encoded_url(todo_result.url)

    # Create another event
    another_result = subject.todos.create(
      calendar.url, "calendav-todo-2.ics", ical_todo("Todo 3")
    )

    # Search for all events
    todos = subject.todos.list(calendar.url)
    expect(todos.length).to eq(2)

    # Delete the events
    expect(subject.todos.delete(todo_result.url)).to eq(true)
    expect(subject.todos.delete(another_result.url)).to eq(true)
  end

  it "respects etag conditions with updates" do
    todo_result = subject.todos.create(
      calendar.url, "calendav-todo.ics", ical_todo("Todo 1")
    )
    todo = subject.todos.find(todo_result.url)

    expect(
      subject.todos.update(
        todo_result.url, update_todo_summary(todo, "Todo 2"), etag: todo.etag
      )
    ).not_to be_nil

    expect(subject.todos.find(todo_result.url).summary).to eq("Todo 2")

    # Wait for server to catch up
    sleep 1

    # Updating with the old etag should fail
    expect(
      subject.todos.update(
        todo_result.url, update_todo_summary(todo, "Todo 1"), etag: todo.etag
      )
    ).to be_nil

    expect(subject.todos.find(todo_result.url).summary).to eq("Todo 2")

    expect(subject.todos.delete(todo_result.url)).to eq(true)
  end

  it "handles synchronisation requests" do
    first_result = subject.todos.create(
      calendar.url, "calendav-todo-1.ics", ical_todo("Todo 1")
    )
    first = subject.todos.find(first_result.url)
    token = subject.calendars.find(calendar.url, sync: true).sync_token

    todos = subject.todos.list(calendar.url)
    expect(todos.length).to eq(1)

    second_result = subject.todos.create(
      calendar.url, "calendav-event-2.ics", ical_todo("Todo 2")
    )

    subject.todos.update(first_result.url, update_todo_summary(first, "Todo 3"))
    first = subject.todos.find(first_result.url)

    collection = subject.calendars.sync(calendar.url, token)
    expect(collection.changes.collect(&:url))
      .to match_encoded_urls([first_result.url, second_result.url])

    expect(collection.deletions).to be_empty
    expect(collection.more?).to eq(false)

    subject.todos.update(first_result.url, update_todo_summary(first, "Todo 1"))
    subject.todos.delete(second_result.url)

    collection = subject.calendars.sync(calendar.url, collection.sync_token)
    urls = collection.changes.collect(&:url)
    expect(urls.length).to eq(1)
    expect(urls[0]).to eq_encoded_url(first_result.url)

    expect(collection.deletions.length).to eq(1)
    expect(collection.deletions.first).to eq_encoded_url(second_result.url)
    expect(collection.more?).to eq(false)

    subject.todos.delete(first_result.url)
  end
end
