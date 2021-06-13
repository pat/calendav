# frozen_string_literal: true

require "uri"

module Calendav
  module Credentials
    class Standard
      attr_reader :host, :username, :password, :authentication

      def initialize(host:, username:, password:, authentication: :basic_auth)
        @host = URI(host)
        @username = username
        @password = password
        @authentication = authentication
      end
    end
  end
end
