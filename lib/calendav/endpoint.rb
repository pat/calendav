# frozen_string_literal: true

require_relative "contextual_url"
require_relative "error_handler"
require_relative "parsers/response_xml"

module Calendav
  class Endpoint
    CONTENT_TYPES = {
      ics: "text/calendar",
      xml: "application/xml; charset=utf-8"
    }.freeze

    def initialize(credentials, timeout: nil)
      @credentials = credentials
      @timeout = timeout
    end

    def delete(url:, etag: nil) # rubocop:disable Naming/PredicateMethod
      request(:delete, url: url, http: with_headers(etag: etag))
        .status
        .success?
    end

    def get(url:)
      parse request(:get, url: url)
    end

    def mkcalendar(body, url:)
      parse request(
        :mkcalendar,
        body,
        url: url,
        http: with_headers(content_type: :xml)
      )
    end

    def options(url:)
      request(:options, url: url)
    end

    def propfind(body, url: nil, depth: 0)
      parse request(
        :propfind,
        body,
        url: url,
        http: with_headers(depth: depth, content_type: :xml)
      )
    end

    def proppatch(body, url: nil)
      parse request(
        :proppatch,
        body,
        url: url,
        http: with_headers(content_type: :xml)
      )
    end

    def put(body, url:, content_type: nil, etag: nil)
      parse request(
        :put,
        body,
        url: url,
        http: with_headers(content_type: content_type, etag: etag)
      )
    end

    def report(body, url: nil, depth: 0)
      parse request(
        :report,
        body,
        url: url,
        http: with_headers(depth: depth, content_type: :xml)
      )
    end

    private

    attr_reader :credentials, :timeout

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

      http = http.timeout(timeout) if timeout
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

      response.status.success? ? response : ErrorHandler.call(response)
    end

    def parse(response)
      return response if response.content_length&.zero? || response.body.empty?

      if response.content_type.mime_type == "text/calendar"
        response
      else
        Parsers::ResponseXML.call(response.body)
      end
    end
  end
end
