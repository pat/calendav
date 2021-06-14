# frozen_string_literal: true

module Calendav
  class SyncCollection
    attr_reader :changes, :deletions, :sync_token

    def initialize(changes, deletions, sync_token)
      @changes = changes
      @deletions = deletions
      @sync_token = sync_token
    end
  end
end
