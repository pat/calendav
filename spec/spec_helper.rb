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
