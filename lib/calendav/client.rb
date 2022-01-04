# frozen_string_literal: true

require_relative "./contextual_url"
require_relative "./endpoint"
require_relative "./clients/calendars_client"
require_relative "./clients/events_client"
require_relative "./requests/current_user_principal"

module Calendav
  class Client
    def initialize(credentials, timeout: nil)
      @credentials = credentials
      @timeout = timeout
    end

    def calendars
      @calendars = Clients::CalendarsClient.new(self, endpoint, credentials)
    end

    def events
      @events = Clients::EventsClient.new(self, endpoint, credentials)
    end

    def principal_url
      @principal_url ||= begin
        request = Requests::CurrentUserPrincipal.call
        response = endpoint.propfind(request.to_xml).first

        ContextualURL.call(
          credentials.host,
          response.xpath(".//dav:current-user-principal/dav:href").text
        )
      end
    end

    private

    attr_reader :credentials, :timeout

    def endpoint
      @endpoint ||= Endpoint.new(credentials, timeout: timeout)
    end
  end
end
