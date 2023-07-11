# frozen_string_literal: true

require "http"
require "uri"

require_relative "standard"

module Calendav
  module Credentials
    class FastMail < Standard
      def initialize(username:, password:)
        super(
          host: "https://caldav.fastmail.com/dav/",
          username: username,
          password: password
        )
      end
    end
  end
end
