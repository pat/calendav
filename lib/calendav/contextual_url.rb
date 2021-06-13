# frozen_string_literal: true

module Calendav
  class ContextualURL
    def self.call(credentials, url_or_path)
      return credentials.host.to_s if url_or_path.nil? || url_or_path.empty?

      if url_or_path.start_with?("/")
        credentials.host.dup.tap { |new_url| new_url.path = url_or_path }.to_s
      else
        URI(url_or_path).to_s
      end
    end
  end
end
