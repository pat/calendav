# frozen_string_literal: true

require "uri"

module Calendav
  class ContextualURL
    PERMITTED_SPECIAL_CHARACTER = %w[! # $ & ' * + - = ? ^ _ ` { | } ~"].freeze

    def self.call(host, url_or_path)
      host = URI(host)
      return host.to_s if url_or_path.nil? || url_or_path.empty?

      if url_or_path.start_with?("/")
        url_or_path = encode_path(url_or_path)

        host.dup.tap { |new_url| new_url.path = url_or_path }.to_s
      else
        URI(url_or_path).to_s
      end
    end

    def self.encode_path(url)
      url.split("/").map do |path|
        PERMITTED_SPECIAL_CHARACTER.each do |ch|
          path.gsub!(ch, CGI.escape(ch))
        end
        path
      end.join("/") + "/"
    end
  end
end
