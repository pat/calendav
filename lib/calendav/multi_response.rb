# frozen_string_literal: true

module Calendav
  class MultiResponse
    include Enumerable

    def initialize(document)
      @document = document
    end

    def each(...)
      responses.each(...)
    end

    def xpath(...)
      document.xpath(...)
    end

    private

    attr_reader :document

    def responses
      document.xpath("/dav:multistatus/dav:response")
    end
  end
end
