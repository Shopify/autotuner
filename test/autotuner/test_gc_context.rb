# frozen_string_literal: true

require "test_helper"

module Autotuner
  class TestGCContext < Minitest::Test
    def setup
      @gc_context = GCContext.new
      @has_stat_heap = RUBY_VERSION >= "3.2"
    end

    def test_update_does_not_change_hash
      orig_stat = @gc_context.stat
      orig_latest_gc_info = @gc_context.latest_gc_info
      orig_stat_heap = @gc_context.stat_heap if @has_stat_heap

      @gc_context.update

      assert_equal(orig_stat, @gc_context.stat)
      assert_equal(orig_latest_gc_info, @gc_context.latest_gc_info)
      assert_equal(orig_stat_heap, @gc_context.stat_heap) if @has_stat_heap
    end

    def test_update_does_not_change_keys
      orig_stat_keys = @gc_context.stat.keys
      orig_latest_gc_info_keys = @gc_context.latest_gc_info.keys
      orig_stat_heap_keys = @gc_context.stat_heap.keys if @has_stat_heap

      @gc_context.update

      refute_empty(orig_stat_keys)
      assert_equal(orig_stat_keys, @gc_context.stat.keys)
      refute_empty(orig_latest_gc_info_keys)
      assert_equal(orig_latest_gc_info_keys, @gc_context.latest_gc_info.keys)
      refute_empty(orig_stat_heap_keys) if @has_stat_heap
      assert_equal(orig_stat_heap_keys, @gc_context.stat_heap.keys) if @has_stat_heap
    end

    def test_update_updates_hashes
      stat_hash = @gc_context.stat
      latest_gc_info_hash = @gc_context.latest_gc_info
      stat_heap_hash = @gc_context.stat_heap if @has_stat_heap

      GC.expects(:stat).with(stat_hash).once
      GC.expects(:latest_gc_info).with(latest_gc_info_hash).once
      GC.expects(:stat_heap).with(nil, stat_heap_hash).once if @has_stat_heap

      @gc_context.update
    end
  end
end
