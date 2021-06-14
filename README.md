# Calendav

A library for interacting with CalDAV servers via Ruby.

At the time of writing, this gem is definitely not ready for production, nor is it anywhere close to supporting a decent set of features. Currently it covers the following:

* Determining the principal URL.
* Determining the calendar home path.
* Listing available calendars.
* Find details of a single calendar at a URL.
* Creating events on a calendar.
* List all events on a calendar.
* Listing events on a calendar within a given timespan.
* Find a single event at a URL.
* Updating an event (with optional etag check).
* Deleting events on a calendar (with optional etag check).
* Create new calendars.
* Update calendars.
* Delete calendars.

Other features on the roadmap, in a rough order of priority:

* Use WebDAV-Sync to get changes since last sync.
* Enable locking/unlocking when making changes.
* Allow requesting only certain properties for calendars/events.

Also, the plan is to have a test suite that covers multiple CalDAV server implementations.

## Usage

```ruby
credentials = Calendav.credentials(
  :google, username: "example@gmail.com", password: "oauth-access-token"
)
# Also supported are FastMail and Apple, where the passwords should be
# app-specific, with authentication via Basic Auth. Google uses a Bearer Token
# for authentication (supplied as the password).
#
# Otherwise, to compose a more custom set of credentials:
credentials = Calendav::Credentials::Standard.new(
  host: "https://www.example.com/caldav",
  username: "example",
  password: "secret",
  authentication: :basic_auth # or :bearer_token
)

client = Calendav.client credentials
puts client.principal_url

puts client.calendars.home_url
calendars = client.calendars.list
calendars.each { |calendar| puts calendar.url, calendar.display_name }

# Not all CalDAV servers allow you to create new calendars. So, you can check:
client.calendars.create?
# Apple allows creation, but Google doesn't.

calendar_url = client.calendars.create(display_name: "New Calendar")
client.calendars.update(calendar_url, display_name: "Updated Calendar")
client.calendars.delete(calendar_url)

events = client.events.list(
  calendar.path, from: Time.new(2021, 1, 1), to: Time.new(2022, 1, 1)
)

# use the icalendar gem to generate ICS strings
ics = Icalendar::Calendar.new
ics.event do |event|
# ...
end
ics.publish

# You need to provide the expected filename for the event:
identifier = "#{SecureRandom.uuid}.ics"
# … but the server may change it on you, so the new, full URL is returned:
event_url = client.events.create(calendar.url, identifier, ics.to_ical)

ics.events.first.summary = "Updated Details"

event = client.events.find(event_url)

# Use the etag keyword argument to avoid overwriting other updates.
# Will return false if the update failed due to the etag constraint.
client.events.update(event_url, ics.to_ical, etag: event.etag)

# If you exclude that argument, then the update will happen no matter what.
client.events.update(event_url, ics.to_ical)

# Deletions also accept the etag option - but not all CalDAV providers respect
# it. Apple does, Google doesn't.
client.events.delete(event_url, etag: event.etag)
# Or, a guaranteed deletion:
client.events.delete(event_url)
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'calendav'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install calendav

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pat/calendav. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/pat/calendav/blob/main/CODE_OF_CONDUCT.md).

The test suite currently only runs against a Google account I've created especially for this purpose - and the credentials are not public. I realise this makes contributions more difficult, and I'm open to finding better ways to handle this. I did look into running a CalDAV server within the test suite, but couldn't find anything small and easy enough for that purpose. But also: testing against common CalDAV servers does help to ensure this gem is truly useful (and has knowledge of their idiosyncrasies).

## License

The gem is available as open source under the terms of the [Hippocratic License](https://firstdonoharm.dev).

## Code of Conduct

Everyone interacting in the Calendav project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/pat/calendav/blob/main/CODE_OF_CONDUCT.md).
