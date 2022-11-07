# frozen_string_literal: true

module Calendav
  class MultiResponse
    include Enumerable

    def initialize(document)
      @document = document
    end

    def each(*args, **kws, &block)
      responses.each(*args, **kws, &block)
    end

    def xpath(*args, **kws, &block)
      document.xpath(*args, **kws, &block)
    end

    private

    attr_reader :document

    def responses
      document.xpath("/dav:multistatus/dav:response")
    end
  end
end
