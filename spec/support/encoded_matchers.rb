# frozen_string_literal: true

module EncodedMatchers
  def eq_encoded_url(expected)
    eq(RecodeURI.call(expected))
  end

  def match_encoded_urls(expected)
    match_array(expected.collect { |uri| RecodeURI.call(uri) })
  end
end

class RecodeURI
  def self.call(uri)
    encoded = URI(uri)

    encoded.path = encoded.path.split("/").collect do |piece|
      URI.encode_www_form_component(piece)
    end.join("/")

    encoded.path += "/" if uri.end_with?("/")

    encoded.to_s
  end
end

RSpec.configure do |config|
  config.include EncodedMatchers
end
