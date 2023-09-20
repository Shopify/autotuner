# frozen_string_literal: true

module Autotuner
  class GCContext
    HAS_STAT_HEAP = GC.respond_to?(:stat_heap)

    attr_reader :stat, :latest_gc_info

    if HAS_STAT_HEAP
      attr_reader :stat_heap
    end

    def initialize
      @stat = GC.stat
      @latest_gc_info = GC.latest_gc_info

      if HAS_STAT_HEAP
        @stat_heap = GC.stat_heap
      end
    end

    def update
      GC.stat(@stat)
      GC.latest_gc_info(@latest_gc_info)

      if HAS_STAT_HEAP
        GC.stat_heap(nil, @stat_heap)
      end
    end
  end
end
