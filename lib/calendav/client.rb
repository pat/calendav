# frozen_string_literal: true

require_relative "./contextual_url"
require_relative "./endpoint"
require_relative "./clients/calendars_client"
require_relative "./clients/events_client"
require_relative "./requests/current_user_principal"

module Calendav
  class Client
    def initialize(credentials)
      @credentials = credentials
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

        ContextualURL.call(
          credentials,
          endpoint
            .propfind(request.to_xml)
            .xpath(".//dav:current-user-principal/dav:href")
            .text
        )
      end
    end

    private

    attr_reader :credentials

    def endpoint
      @endpoint ||= Endpoint.new(credentials)
    end
  end
end
