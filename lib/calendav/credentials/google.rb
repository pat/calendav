# frozen_string_literal: true

require "http"
require "uri"

require_relative "./standard"

module Calendav
  module Credentials
    class Google < Standard
      def initialize(username:, password:)
        super(
          host: "https://apidata.googleusercontent.com/caldav/v2/",
          username: username,
          password: password,
          authentication: :bearer_token
        )
      end
    end
  end
end
