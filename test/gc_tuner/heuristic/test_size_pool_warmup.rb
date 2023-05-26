# frozen_string_literal: true

require "test_helper"

module GCTuner
  module Heuristic
    class TestSizePoolWarmup < Minitest::Test
      def setup
        @size_pool_warmup = SizePoolWarmup.new
      end

      def test_tuning_message
        insert_plateau_data

        [40, 80, 160, 320, 640].each do |i|
          assert_match(
            /^RUBY_GC_HEAP_INIT_SIZE_#{i}_SLOTS=\d+ \(confidence: [01]\.\d\d\)$/,
            @size_pool_warmup.tuning_message,
          )
        end
      end

      def test_tuning_message_with_initial_configuration
        original_env = ENV.to_h

        ENV["RUBY_GC_HEAP_INIT_SIZE_40_SLOTS"] = "100"
        ENV["RUBY_GC_HEAP_INIT_SIZE_80_SLOTS"] = "200"

        @size_pool_warmup = SizePoolWarmup.new

        gc_context = GCContext.new
        (SizePoolWarmup::DATA_POINTS_COUNT + 1).times do
          GC::INTERNAL_CONSTANTS[:SIZE_POOL_COUNT].times do |i|
            gc_context.stat_heap[i][:heap_eden_pages] += rand(10)
          end
          # 40 byte size
          gc_context.stat_heap[0][:heap_eden_pages] = 100

          # 80 byte size
          gc_context.stat_heap[1][:heap_eden_pages] = rand(100)

          @size_pool_warmup.call(100 + rand(2), gc_context, gc_context)
        end

        msg = @size_pool_warmup.tuning_message

        refute_includes(msg, "RUBY_GC_HEAP_INIT_SIZE_40_SLOTS")
        assert_match(/^RUBY_GC_HEAP_INIT_SIZE_80_SLOTS=\d+ \(confidence: [01]\.\d\d, tuned value: 200\)$/, msg)
      ensure
        ENV.replace(original_env)
      end

      def test_tuning_message_for_no_data
        assert_equal(
          "There is not enough data and/or response times have not plateaued.",
          @size_pool_warmup.tuning_message,
        )
      end

      def test_debug_message
        insert_plateau_data

        msg = @size_pool_warmup.debug_message

        assert_includes(msg, "plateaued: true\n")
        assert_match(/^request_time_data: .+$/, msg)
        assert_match(/^size_pools_data\[0\]: .+$/, msg)
        assert_match(/^RUBY_GC_HEAP_INIT_SIZE_40_SLOTS=\d+ \(confidence: [01]\.\d\d\)$/, msg)
      end

      def test_debug_message_with_initial_configuration
        original_env = ENV.to_h

        ENV["RUBY_GC_HEAP_INIT_SIZE_40_SLOTS"] = "100"
        ENV["RUBY_GC_HEAP_INIT_SIZE_80_SLOTS"] = "200"

        @size_pool_warmup = SizePoolWarmup.new

        gc_context = GCContext.new
        (SizePoolWarmup::DATA_POINTS_COUNT + 1).times do
          GC::INTERNAL_CONSTANTS[:SIZE_POOL_COUNT].times do |i|
            gc_context.stat_heap[i][:heap_eden_pages] += rand(10)
          end
          # 40 byte size
          gc_context.stat_heap[0][:heap_eden_pages] = 100

          # 80 byte size
          gc_context.stat_heap[1][:heap_eden_pages] = rand(100)

          @size_pool_warmup.call(100 + rand(2), gc_context, gc_context)
        end

        msg = @size_pool_warmup.debug_message

        assert_includes(msg, "plateaued: true\n")
        assert_match(/^request_time_data: .+$/, msg)
        assert_match(/^size_pools_data\[0\]: .+$/, msg)

        assert_match(/^RUBY_GC_HEAP_INIT_SIZE_40_SLOTS=\d+ \(confidence: .+, tuned value: 100\)$/, msg)
        assert_match(/^RUBY_GC_HEAP_INIT_SIZE_80_SLOTS=\d+ \(confidence: [01]\.\d\d, tuned value: 200\)$/, msg)
      ensure
        ENV.replace(original_env)
      end

      def test_debug_message_for_no_data
        msg = @size_pool_warmup.debug_message

        assert_includes(msg, "plateaued: false\n")
        assert_match(/^request_time_data: .+$/, msg)
        assert_match(/^size_pools_data\[0\]: .+$/, msg)
      end

      private

      def insert_plateau_data
        gc_context = GCContext.new

        (SizePoolWarmup::DATA_POINTS_COUNT + 1).times do
          GC::INTERNAL_CONSTANTS[:SIZE_POOL_COUNT].times do |i|
            gc_context.stat_heap[i][:heap_eden_pages] += rand(10)
          end

          @size_pool_warmup.call(100 + rand(2), gc_context, gc_context)
        end
      end
    end
  end
end
