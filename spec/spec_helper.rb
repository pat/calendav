# frozen_string_literal: true

require "calendav"
require "dotenv"

Dotenv.load

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

RSpec::Matchers.define :eq_encoded_url do |expected|
  match do |actual|
    encoded = URI(expected).tap do |uri|
      uri.path = uri.path.split("/").collect do |piece|
        URI.encode_www_form_component(piece)
      end.join("/")

      uri.path += "/" if expected.end_with?("/")
    end

    actual == encoded.to_s
  end
end
