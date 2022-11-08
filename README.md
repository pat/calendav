# in this FORK
3 dots as a method argument is not supported by ruby 2.6.6
1- all occurrences are replaced with proper arguments.
2- required ruby version is changed to >= 2.6.6

**To Test** 
add `gem 'calendav', git: 'https://github.com/petalmd/calendav', require: false` to gemfile
ensure you run ruby 2.6.6
open a ruby console and `require 'calendav'`. it should not raise any error
you may also want to test it by connecting to Caldav Server (if you have one running in ur machine)

````

credentials = Calendav::Credentials::Standard.new(host: " http://localhost:8080/remote.php/dav",username: username, password: password, authentication: :basic_auth)

client =  Calendav.client(credentials)
calendras = client.calendars.list
events = client.events.list(calendars.first.url)
````

# Calendav

A library for interacting with CalDAV servers via Ruby.

## Features

### Credentials and Accounts

Calendav has support for a few calendar providers built-in by default: Apple, FastMail, and Google.

```ruby
credentials = Calendav.credentials(
  :apple, "example@icloud.com", "app-specific-password"
)
```

Both Apple and FastMail expect app-specific passwords (rather than the account's main password). Google expects an OAuth 2 access token for the password instead.

You can also create credentials for other providers:

```ruby
credentials = Calendav::Credentials::Standard.new(
  host: "https://www.example.com/caldav",
  username: "example",
  password: "secret",
  authentication: :basic_auth # or :bearer_token
)
```

You can use credentials to create a new client instance. If required, you can confirm they're valid by checking if a principal URL for the account can be returned.

```ruby
client = Calendav.client(credentials)
puts client.principal_url
```

### Calendars

You can retrieve a list of all available calendars:

```ruby
calendars = client.calendars.list
calendars.each do |calendar|
  puts calendar.url
  puts calendar.display_name
end
```

All calendars returned will have a URL - and this is the primary and unique reference to the calendar, and will not change. They should also have a display name, description, etag, ctag, time zone and color - but not all providers support all of these properties.

If you already have the Calendar's URL, then you can request its information directly as well:

```ruby
calendar = client.calendars.find(calendar_url)
```

Some providers (though not Google) allow you to create calendars via the CalDAV protocol. You must supply the identifier of this calendar, which is the final part of its URL - and so must be unique for the account. Using a UUID could be a good option.

```ruby
require "securerandom"

identifier = SecureRandom.uuid

calendar_url = client.calendars.create(identifier, display_name: "My Calendar")
```

You can also edit calendar details, and delete them (if the provide allows such actions). The allowed attributes are `display_name`, `description`, `time_zone` and `color`.

```ruby
client.calendars.update(calendar_url, display_name: "Altered Calendar")
client.calendars.delete(calendar_url)
```

It is possible to check whether a calendar provider supports calendar creation/deletion:

```ruby
client.calendars.create? # => true/false
```

Also, if it's useful, you can access the account's calendar home path (the root directory for that account's calendars):

```ruby
client.calendars.home_url
```

### Events

Once you have a calendar's URL, you can retrieve events from it. Unless you are making a copy of the calendar for synchronisation purposes, it's recommended you limit the request to a specific timeframe (though the `from` and `to` arguments are optional).

```ruby
events = client.events.list(
  calendar_url, from: Time.new(2021, 1, 1), to: Time.new(2022, 1, 1)
)
events.each do |event|
  puts event.url
  puts event.summary
  puts event.calendar_data
end
```

The returned events have a unique URL (just like calendars), an `etag` (which changes when the event changes), and `calendar_data`, which is stored in the [iCalendar](https://datatracker.ietf.org/doc/html/rfc5545) format. The event objects returned currently parse the summary out of the calendar data, but nothing else - further attributes may be made visible, but for full control it's recommended you use the [icalendar](https://github.com/icalendar/icalendar) gem.

If you have an event's URL, you can fetch the details of just that event directly:

```ruby
event = client.events.find(event_url)
```

Creating events, just like creating calendars, requires a unique identifier. There are no hard requirements for the format from the perspective of CalDAV generally, but some providers require the identifier to have the extension `.ics`.

You will also need to generate the iCalendar data - again, the [icalendar](https://github.com/icalendar/icalendar) gem is very helpful for this.

```ruby
require "securerandom"
require "icalendar"

ics = Icalendar::Calendar.new
ics.event do |event|
# ...
end
ics.publish

identifier = "#{SecureRandom.uuid}.ics"
# The returned event has just the URL and the etag, no calendar data:
event_scaffold = client.events.create(calendar.url, identifier, ics.to_ical)
```

*Please note*: some providers (definitely Google, possibly others) will not keep your supplied event identifier, but generate a new one. So, if you need an ongoing reference to the event, save the returned URL (rather than combining the calendar URL and your identifier).

Updating events is done in a similar manner - with the event's URL and the updated iCalendar content:

```ruby
event_scaffold = client.events.update(event_url, ics.to_ical)
```

To ensure you're only changing a known version of an event, it's recommended you use that version's etag as a precondition check (the update call will return nil if the event on the server has a different etag value):

```ruby
event = client.events.find(event_scaffold.url)

# figure out the changes you want to make, generate the new ical data, and then:

client.events.update(event_scaffold.url, modified_ical, etag: event.etag)
```

Deletion of events is done via the event's URL as well - some providers (including Apple) support the etag precondition check for this, but others (including Google) do not. In the latter situation, the deletion will happen regardless of the server event's etag value.

```ruby
client.events.delete(event_url)

client.events.delete(event_url, etag: event.etag)
```

### Synchronising

If you are maintaining your own copy/history of events from a CalDAV server, then it's highly recommended you take advantage of the WebDAV-Sync protocol (should the calendar provider support it). Using Calendav, the suggested approach is:

* Get a token for a specific calendar
* Request all events for that calendar
* Then, to get just the changed/deleted events, use the token to request the delta.
* That request will return a new token, which you use in the _next_ delta request, and so forth.

These `sync_token` values are not returned by default, but can be requested on a per-calendar basis:

```ruby
token = subject.calendars.find(calendar_url, sync: true).sync_token
```

To retrieve all events for that calendar (when starting the initial synchronisation process):

```ruby
events = subject.events.list(calendar_url)
```

And then to retrieve the delta changes and a new `sync_token`:

```ruby
collection = subject.calendars.sync(calendar_url, token)
collection.changes.each { |change| puts change.url }
collection.deletions.each { |deletion_url| puts deletion_url }
token = collection.sync_token
```

The `deletions` array is the event URLs for any events that have been removed since your previous sync - no other details are available.

The `changes` array are Event objects - but some may not have their `calendar_data` populated, as not all calendar providers supply this as part of requesting the synchronisation delta. Apple does not return this information, but Google does. So, you may need to request the full event object if required:

```ruby
events = collection.changes.collect do |event|
  event.unloaded? ? client.events.find(event.url) : event
end
```

### Still to be implemented

While a lot of the core CalDAV functionality is covered and this gem is useful as it stands, the following features are on the roadmap:

* Further iCalendar parsing for Event objects.
* Automated tests against FastMail and possibly other providers (Apple and Google are already covered).
* Locking/unlocking of events as per the WebCAL RFC.
* Support for VTODO, VJOURNAL, VFREEBUSY and any other components beyond VEVENT.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'calendav'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install calendav

## API Design

I've thus far preferred separation between data objects (`Calendav::Event` and `Calendav::Calendar`), and the interaction layer (via `Calendav::Client`) - as opposed to, say, a more ActiveRecord-like manner of interactions from within data objects.

I've chosen the separated approach because it allows actions to occur on specific calendars or events without having a full data tree - this keeps requests to calendar providers to a minimum. You don't want to be loading everything from their servers every time you're reading/modifying one event!

One thing that will likely evolve is how identifiers are handled for new calendars and events - while allowing custom ones to be provided will remain, I'll be looking at autogeneration with UUIDs to ensure a simpler approach is possible.

Similarly, providing translation around event/calendar/time-zone details (via [icalendar](https://github.com/icalendar/icalendar)) is also a consideration.

## Thanks

The work done in previous Ruby CalDAV clients [RubyCaldav](https://github.com/digITpro/caldav_client) and [caldav](https://github.com/collectiveidea/caldav) has been very helpful, even though the codebases haven't seen updates in many years. I also found Sabre's documentation on [building a CalDAV client](https://sabre.io/dav/building-a-caldav-client/) to be extremely useful. Thank you to those teams for their hard work!

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Tests

The test suite currently only runs against Google and Apple accounts I've created especially for this purpose - and the credentials are not public. I realise this makes contributions more difficult, and I'm open to finding better ways to handle this. I did look into running a CalDAV server within the test suite, but couldn't find anything small and easy enough for that purpose. But also: testing against common CalDAV servers does help to ensure this gem is truly useful (and has knowledge of their idiosyncrasies).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pat/calendav. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/pat/calendav/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [Hippocratic License](https://firstdonoharm.dev).

## Code of Conduct

Everyone interacting in the Calendav project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/pat/calendav/blob/main/CODE_OF_CONDUCT.md).
