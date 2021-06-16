# frozen_string_literal: true

require "securerandom"

require_relative "./shared"

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

  it_behaves_like "supporting calendar management"

  context "with a calendar" do
    let(:calendar_url) do
      subject.calendars.create(SecureRandom.uuid, display_name: "Calendav Test")
    end
    let(:calendar) { subject.calendars.find(calendar_url) }

    after :each do
      subject.calendars.delete(calendar.url)
    end

    it_behaves_like "supporting event management"
    it_behaves_like "supporting event deletion with etags"
  end
end
