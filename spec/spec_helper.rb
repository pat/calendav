# frozen_string_literal: true

require "calendav"
require "dotenv"

Dotenv.load

require_relative "support/encoded_matchers"
require_relative "support/event_helpers"

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
