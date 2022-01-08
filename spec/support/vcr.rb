# frozen_string_literal: true

require "timecop"
require "webmock/rspec"
require "vcr"
require "vcr_assistant/rspec"

VCR.configure do |config|
  config.cassette_library_dir = File.expand_path(
    File.join(__dir__, "../cassettes")
  )
  config.hook_into :webmock
  config.ignore_hosts "127.0.0.1"
end

RSpec.configure do |config|
  config.around(:each, :vcr) do |example|
    assisted_cassette(example) do |_assistant|
      Timecop.freeze(Time.gm(2022))

      example.run

      Timecop.return
    end
  end
end
