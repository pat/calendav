# frozen_string_literal: true

module Calendav
  class Error < StandardError; end

  class ParsingXMLError < Error
    attr_reader :xml, :original

    def initialize(xml, original)
      super(original.message)

      @xml = xml
      @original = original
    end
  end

  class RequestError < Error
    attr_reader :response

    def initialize(response)
      super(response.status.to_s)

      @response = response
    end
  end

  class RedirectError < RequestError
    def location
      response.headers["Location"]
    end
  end

  class PreconditionError < RequestError; end
end
