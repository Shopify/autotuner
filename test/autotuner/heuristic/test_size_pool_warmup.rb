# frozen_string_literal: true

require "test_helper"

module Autotuner
  module Heuristic
    class TestSizePoolWarmup < Minitest::Test
      def setup
        @size_pool_warmup = SizePoolWarmup.new
        @gc_context = GCContext.new
      end

      def test_tuning_report
        insert_plateau_data

        report = @size_pool_warmup.tuning_report

        assert_equal(SizePoolWarmup::REPORT_ASSIST_MESSAGE, report.assist_message)
        assert_equal(5, report.env_name.length)
        assert_equal(5, report.suggested_value.length)
        assert_equal(5, report.configured_value.length)
        [40, 80, 160, 320, 640].each_with_index do |slot_size, i|
          assert_equal("RUBY_GC_HEAP_INIT_SIZE_#{slot_size}_SLOTS", report.env_name[i])
          assert_equal(@gc_context.stat_heap[i][:heap_eden_slots], report.suggested_value[i])
          assert_nil(report.configured_value[i])
        end
      end

      def test_tuning_report_with_configured_values
        original_env = ENV.to_h

        # Correct configured value
        ENV["RUBY_GC_HEAP_INIT_SIZE_80_SLOTS"] = "20000"
        # Incorrect configured value
        ENV["RUBY_GC_HEAP_INIT_SIZE_320_SLOTS"] = "50000"

        insert_plateau_data([10_000, 20_000, 30_000, 40_000, 50_000])

        report = @size_pool_warmup.tuning_report

        assert_equal(SizePoolWarmup::REPORT_ASSIST_MESSAGE, report.assist_message)
        assert_equal(4, report.env_name.length)
        assert_equal(4, report.suggested_value.length)
        assert_equal(4, report.configured_value.length)
        [40, 160, 320, 640].each_with_index do |slot_size, i|
          assert_equal("RUBY_GC_HEAP_INIT_SIZE_#{slot_size}_SLOTS", report.env_name[i])
        end
        assert_equal(50_000, report.configured_value[2])
      ensure
        ENV.replace(original_env)
      end

      def test_tuning_report_when_not_ready
        report = @size_pool_warmup.tuning_report

        assert_nil(report)

        # Insert non-platueau data
        (SizePoolWarmup::DATA_POINTS_COUNT + 1).times do |_i|
          @gc_context.stat_heap[0][:heap_eden_slots] += 100

          @size_pool_warmup.call(100, @gc_context, @gc_context)
        end

        report = @size_pool_warmup.tuning_report

        assert_nil(report)
      end

      def test_tuning_report_does_not_give_suggestion_twice
        insert_plateau_data

        report = @size_pool_warmup.tuning_report

        refute_nil(report)

        report = @size_pool_warmup.tuning_report

        assert_nil(report)
      end

      def test_debug_message
        insert_plateau_data

        @size_pool_warmup.tuning_report
        msg = @size_pool_warmup.debug_message

        assert_includes(msg, "given_suggestion: true\n")
        assert_match(/^request_time_data: .+$/, msg)
        assert_match(/^size_pools_data\[0\]: .+$/, msg)
      end

      def test_debug_message_with_initial_configuration
        original_env = ENV.to_h

        ENV["RUBY_GC_HEAP_INIT_SIZE_40_SLOTS"] = "10000"
        ENV["RUBY_GC_HEAP_INIT_SIZE_80_SLOTS"] = "20000"

        insert_plateau_data

        @size_pool_warmup.tuning_report
        msg = @size_pool_warmup.debug_message

        assert_includes(msg, "given_suggestion: true\n")
        assert_match(/^request_time_data: .+$/, msg)
        assert_match(/^size_pools_data\[0\]: .+$/, msg)

        assert_match(/^ENV\[RUBY_GC_HEAP_INIT_SIZE_40_SLOTS\]: 10000$/, msg)
        assert_match(/^ENV\[RUBY_GC_HEAP_INIT_SIZE_80_SLOTS\]: 20000$/, msg)
      ensure
        ENV.replace(original_env)
      end

      def test_debug_message_for_no_data
        msg = @size_pool_warmup.debug_message

        assert_includes(msg, "given_suggestion: false\n")
        assert_match(/^request_time_data: .+$/, msg)
        assert_match(/^size_pools_data\[0\]: .+$/, msg)
      end

      private

      def insert_plateau_data(size_pool_slots = nil)
        SizePoolWarmup::SIZE_POOL_COUNT.times do |i|
          @gc_context.stat_heap[i][:heap_eden_slots] = size_pool_slots ? size_pool_slots[i] : rand(100)
        end

        (SizePoolWarmup::DATA_POINTS_COUNT + 1).times do |_i|
          @size_pool_warmup.call(100 + rand(2), @gc_context, @gc_context)
        end
      end
    end
  end
end
