# frozen_string_literal: true

module Calendav
  class SyncCollection
    attr_reader :changes, :deletions, :sync_token, :more

    def initialize(changes, deletions, sync_token, more)
      @changes = changes
      @deletions = deletions
      @sync_token = sync_token
      @more = more
    end

    def more?
      more
    end
  end
end
