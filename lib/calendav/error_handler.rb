# frozen_string_literal: true

require_relative "./errors"

module Calendav
  class ErrorHandler
    def self.call(...)
      new(...).call
    end

    def initialize(response)
      @response = response
    end

    def call
      raise PreconditionError, response if status.code == 412
      raise RedirectError, headers["Location"] if status.redirect?

      raise RequestError, response
    end

    private

    attr_reader :response

    def headers
      response.headers
    end

    def status
      response.status
    end
  end
end
