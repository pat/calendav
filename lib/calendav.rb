# frozen_string_literal: true

require_relative "calendav/credentials/apple"
require_relative "calendav/credentials/fastmail"
require_relative "calendav/credentials/google"
require_relative "calendav/client"

module Calendav
  PROVIDERS = {
    apple: Credentials::Apple,
    fastmail: Credentials::FastMail,
    google: Credentials::Google
  }.freeze

  def self.credentials(provider, username, password)
    PROVIDERS.fetch(provider).new(username: username, password: password)
  end

  def self.client(credentials, timeout: nil)
    Client.new(credentials, timeout: timeout)
  end
end
