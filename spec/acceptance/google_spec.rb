# frozen_string_literal: true

require "googleauth"
require "icalendar"
require "securerandom"
require "uri"

RSpec.describe "Google" do
  let(:provider) { :google }
  let(:username) { ENV.fetch("GOOGLE_USERNAME") }
  let(:access_token) { @access_token }
  let(:credentials) { Calendav.credentials(provider, username, access_token) }

  subject { Calendav.client(credentials) }

  before :context do
    @access_token = begin
      credentials = Google::Auth::UserRefreshCredentials.new(
        client_id: ENV.fetch("GOOGLE_CLIENT_ID"),
        scope: [],
        client_secret: ENV.fetch("GOOGLE_CLIENT_SECRET"),
        refresh_token: ENV.fetch("GOOGLE_REFRESH_TOKEN"),
        additional_parameters: { "access_type" => "offline" }
      )
      credentials.fetch_access_token!
      credentials.access_token
    end
  end

  it "determines the user's principal URL" do
    expect(subject.principal_url)
      .to eq("https://apidata.googleusercontent.com/caldav/v2/#{URI.encode_www_form_component(username)}/user")
  end

  it "determines the user's calendar URL" do
    expect(subject.calendars.home_url)
      .to eq("https://apidata.googleusercontent.com/caldav/v2/#{URI.encode_www_form_component(username)}/")
  end

  it "can create and delete calendars" do
    skip "Not supported by Google"
    url = subject.calendars.create(
      display_name: "Calendav Test"
    )

    subject.calendars.delete(url)
  end

  it "can find calendars" do
    calendars = subject.calendars.list

    expect(calendars.collect(&:display_name)).to include("Calendav Test")
  end

  context "with a calendar" do
    let(:calendars) { subject.calendars.list }
    let(:calendar_url) do
      calendars.detect { |cal| cal.display_name == "Calendav Test" }.url
    end
    let(:identifier) { "#{SecureRandom.uuid}.ics" }
    let(:start) { Time.new 2021, 6, 1, 10, 30 }
    let(:finish) { Time.new 2021, 6, 1, 12, 30 }

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
      expect(events.first.url).to start_with("https://")

      # Delete the event
      expect(subject.events.delete(event_url)).to eq(true)
    end
  end
end
