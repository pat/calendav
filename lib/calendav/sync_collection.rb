# frozen_string_literal: true

module Calendav
  class SyncCollection
    attr_reader :changes, :deletions, :token

    def initialize(changes, deletions, token)
      @changes = changes
      @deletions = deletions
      @token = token
    end
  end
end
