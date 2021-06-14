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

    def delete(url:, etag: nil)
      request(:delete, url: url, http: with_headers(etag: etag))
        .status
        .success?
    end

    def get(url:)
      request(:get, url: url)
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

    def proppatch(body, url: nil)
      request(
        :proppatch,
        body,
        url: url,
        http: with_headers(content_type: :xml)
      )
    end

    def put(body, url:, content_type: nil, etag: nil)
      request(
        :put,
        body,
        url: url,
        http: with_headers(content_type: content_type, etag: etag)
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

    def with_headers(content_type: nil, depth: nil, etag: nil)
      http = authenticated

      http = http.headers(depth: depth) if depth
      http = http.headers("If-Match" => etag) if etag
      if content_type
        http = http.headers("Content-Type" => CONTENT_TYPES[content_type])
      end

      http
    end

    def request(verb, body = nil, url:, http: with_headers)
      response = http.request(
        verb, ContextualURL.call(credentials.host, url), body: body
      )
      unless response.status.success?
        raise RequestFailedError, response.status.to_s
      end

      parse(response)
    end

    def parse(response)
      return response if response.content_length&.zero? || response.body.empty?

      if response.content_type.mime_type == "text/calendar"
        response
      else
        XMLProcessor.call(response.body)
      end
    end
  end
end
