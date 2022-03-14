# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "calendav"
  spec.version       = "0.3.0"
  spec.authors       = ["Pat Allan"]
  spec.email         = ["pat@freelancing-gods.com"]

  spec.summary       = "CalDAV client"
  spec.homepage      = "https://github.com/pat/calendav"
  spec.license       = "Hippocratic-2.1"

  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] =
    "https://github.com/pat/calendav/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files         = Dir["lib/**/*"] + %w[LICENSE.md README.md CHANGELOG.md]
  spec.test_files    = Dir["spec/**/*"] -
                       Dir["spec/cassettes/**/*"] +
                       %w[.rspec Gemfile Rakefile]

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "http"
  spec.add_runtime_dependency "icalendar"
  spec.add_runtime_dependency "nokogiri"

  spec.add_development_dependency "dotenv"
  spec.add_development_dependency "google-api-client"
  spec.add_development_dependency "googleauth"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "tzinfo"
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "vcr_assistant"
  spec.add_development_dependency "webmock"
end
