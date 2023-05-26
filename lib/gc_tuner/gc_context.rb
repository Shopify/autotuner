# frozen_string_literal: true

module GCTuner
  class GCContext
    attr_reader :stat, :stat_heap

    def initialize
      @stat = GC.stat
      @stat_heap = GC.stat_heap
    end

    def update
      GC.stat(@stat)
      GC.stat_heap(nil, @stat_heap)
    end
  end
end
