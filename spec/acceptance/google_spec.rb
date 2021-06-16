# frozen_string_literal: true

require "googleauth"
require "icalendar"
require "securerandom"
require "uri"

require_relative "./shared"

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
    expect(subject.principal_url).to eq_encoded_url(
      "https://apidata.googleusercontent.com/caldav/v2/#{username}/user"
    )
  end

  it "determines the user's calendar URL" do
    expect(subject.calendars.home_url).to eq_encoded_url(
      "https://apidata.googleusercontent.com/caldav/v2/#{username}/"
    )
  end

  it "cannot create calendars" do
    expect(subject.calendars.create?).to eq(false)
  end

  it "can find and update calendars" do
    calendars = subject.calendars.list
    calendar = calendars.detect { |cal| cal.display_name == "Calendav Test" }

    expect(calendar).to_not be_nil

    subject.calendars.update(calendar.url, display_name: "Calendav Update")

    calendars = subject.calendars.list
    calendar = calendars.detect { |cal| cal.display_name == "Calendav Update" }

    subject.calendars.update(calendar.url, display_name: "Calendav Test")
  end

  context "with a calendar" do
    let(:calendars) { subject.calendars.list }
    let(:calendar) do
      calendars.detect { |cal| cal.display_name == "Calendav Test" }
    end

    after :each do
      subject
        .events
        .list(calendar.url)
        .each { |event| subject.events.delete(event.url) }
    end

    it_behaves_like "supporting event management"

    it "does not respect etag conditions for deletions" do
      event_url = subject.events.create(
        calendar.url, event_identifier, ical_event("Brunch", 10, 30)
      )
      event = subject.events.find(event_url)

      expect(
        subject.events.update(
          event_url, update_summary(event, "Coffee"), etag: event.etag
        )
      ).to eq(true)

      # Google doesn't care about the If-Match header on DELETE requests :(
      expect(subject.events.delete(event_url, etag: event.etag)).to eq(true)
    end
  end
end
