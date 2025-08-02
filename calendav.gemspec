# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "calendav"
  spec.version       = "0.5.0"
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

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "http"
  spec.add_dependency "icalendar"
  spec.add_dependency "nokogiri"
end
