# frozen_string_literal: true

require "securerandom"

require_relative "./shared"

RSpec.describe "Apple", :vcr do
  let(:provider) { :apple }
  let(:username) { ENV.fetch("APPLE_USERNAME") }
  let(:password) { ENV.fetch("APPLE_PASSWORD") }
  let(:credentials) { Calendav.credentials(provider, username, password) }
  let(:host) { "https://p49-caldav.icloud.com/20264203208/calendars/" }

  subject { Calendav.client(credentials) }

  it "determines the user's principal URL" do
    expect(subject.principal_url)
      .to eq_encoded_url("https://caldav.icloud.com/20264203208/principal/")
  end

  it "determines the user's calendar URL" do
    expect(subject.calendars.home_url)
      .to eq_encoded_url("https://p49-caldav.icloud.com/20264203208/calendars/")
  end

  it_behaves_like "supporting calendar management"

  context "with a calendar" do
    let(:calendar_url) do
      subject.calendars.create(@name, display_name: "Calendav Test")
    end
    let(:calendar) { subject.calendars.find(calendar_url) }

    before :each do |example|
      @name = Digest::MD5.hexdigest(example.metadata[:full_description])
    end

    after :each do
      subject.calendars.delete(calendar.url)
    end

    it_behaves_like "supporting event management"
    it_behaves_like "supporting event deletion with etags"
  end
end
