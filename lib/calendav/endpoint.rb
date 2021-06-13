# frozen_string_literal: true

require_relative "./contextual_url"
require_relative "./xml_processor"

module Calendav
  class Endpoint
    CONTENT_TYPES = {
      ics: "text/calendar",
      xml: "application/xml; charset=utf-8"
    }.freeze

    RequestFailedError = Class.new(StandardError)

    def initialize(credentials)
      @credentials = credentials
    end

    def delete(url:)
      request(:delete, url: url).status.success?
    end

    def mkcalendar(body, url:)
      request(
        :mkcalendar,
        body,
        url: url,
        http: with_headers(content_type: :xml)
      )
    end

    def propfind(body, url: nil, depth: 0)
      request(
        :propfind,
        body,
        url: url,
        http: with_headers(depth: depth, content_type: :xml)
      )
    end

    def put(body, url:, content_type: nil)
      request(
        :put,
        body,
        url: url,
        http: with_headers(content_type: content_type)
      )
    end

    def report(body, url: nil, depth: 0)
      request(
        :report,
        body,
        url: url,
        http: with_headers(depth: depth, content_type: :xml)
      )
    end

    private

    attr_reader :credentials

    def authenticated
      case credentials.authentication
      when :basic_auth
        HTTP.basic_auth(user: credentials.username, pass: credentials.password)
      when :bearer_token
        HTTP.auth("Bearer #{credentials.password}")
      else
        raise "Unexpected authentication approach: " \
          "#{credentials.authentication}"
      end
    end

    def with_headers(content_type: nil, depth: nil)
      http = authenticated

      http = http.headers(depth: depth) if depth
      if content_type
        http = http.headers("Content-Type" => CONTENT_TYPES[content_type])
      end

      http
    end

    def request(verb, body = nil, url:, http: with_headers)
      response = http.request(
        verb, ContextualURL.call(credentials, url), body: body
      )
      unless response.status.success?
        raise RequestFailedError, response.status.to_s
      end

      return response if response.content_length&.zero?

      XMLProcessor.call(response.body)
    end
  end
end
