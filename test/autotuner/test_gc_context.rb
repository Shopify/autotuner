# frozen_string_literal: true

require "test_helper"

module Autotuner
  class TestGCContext < Minitest::Test
    def setup
      @gc_context = GCContext.new
    end

    def test_update_does_not_change_hash
      orig_stat = @gc_context.stat
      orig_stat_heap = @gc_context.stat_heap

      @gc_context.update

      assert_equal(orig_stat, @gc_context.stat)
      assert_equal(orig_stat_heap, @gc_context.stat_heap)
    end

    def test_update_does_not_change_keys
      orig_stat_keys = @gc_context.stat.keys
      orig_stat_heap_keys = @gc_context.stat_heap.keys

      @gc_context.update

      refute_empty(orig_stat_keys)
      assert_equal(orig_stat_keys, @gc_context.stat.keys)
      refute_empty(orig_stat_heap_keys)
      assert_equal(orig_stat_heap_keys, @gc_context.stat_heap.keys)
    end

    def test_update_updates_hashes
      stat_hash = @gc_context.stat
      stat_heap_hash = @gc_context.stat_heap

      GC.expects(:stat).with(stat_hash).once
      GC.expects(:stat_heap).with(nil, stat_heap_hash).once

      @gc_context.update
    end
  end
end
