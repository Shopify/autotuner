# frozen_string_literal: true

module Autotuner
  class GCContext
    attr_reader :stat, :stat_heap, :latest_gc_info

    def initialize
      @stat = GC.stat
      @stat_heap = GC.stat_heap
      @latest_gc_info = GC.latest_gc_info
    end

    def update
      GC.stat(@stat)
      GC.stat_heap(nil, @stat_heap)
      GC.latest_gc_info(@latest_gc_info)
    end
  end
end
