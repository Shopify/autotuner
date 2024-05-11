# frozen_string_literal: true

require "test_helper"

module Autotuner
  module Heuristic
    class TestHeapSizeWarmup < Minitest::Test
      def setup
        skip if RUBY_VERSION.start_with?("3.2.")

        @system_context = SystemContext.new
        @heap_size_warmup = HeapSizeWarmup.new(@system_context)
        @request_context = RequestContext.new
      end

      def test_enabled?
        assert_predicate(HeapSizeWarmup, :enabled?)
      end

      def test_tuning_report
        insert_plateau_data

        report = @heap_size_warmup.tuning_report

        assert_equal("HeapSizeWarmup", report.heuristic_name)
        assert_equal(HeapSizeWarmup::REPORT_ASSIST_MESSAGE, report.assist_message)

        if HeapSizeWarmup::SUPPORT_MULTI_HEAP_P
          assert_equal(5, report.env_name.length)
          assert_equal(5, report.suggested_value.length)
          assert_equal(5, report.configured_value.length)
          HeapSizeWarmup::HEAP_NAMES.each_with_index do |heap_name, i|
            assert_equal("RUBY_GC_HEAP_#{heap_name}_INIT_SLOTS", report.env_name[i])
            assert_equal(@request_context.after_gc_context.stat_heap[i][:heap_eden_slots], report.suggested_value[i])
            assert_nil(report.configured_value[i])
          end
        else
          assert_equal(1, report.env_name.length)
          assert_equal(1, report.suggested_value.length)
          assert_equal(1, report.configured_value.length)
          assert_equal("RUBY_GC_HEAP_INIT_SLOTS", report.env_name[0])
          assert_equal(@request_context.after_gc_context.stat[:heap_available_slots], report.suggested_value[0])
          assert_nil(report.configured_value[0])
        end
      end

      def test_tuning_report_with_configured_values
        original_env = ENV.to_h

        if HeapSizeWarmup::SUPPORT_MULTI_HEAP_P
          # Correct configured value
          ENV["RUBY_GC_HEAP_1_INIT_SLOTS"] = "20000"
          # Incorrect configured value
          ENV["RUBY_GC_HEAP_3_INIT_SLOTS"] = "50000"

          insert_plateau_data([10_000, 20_000, 30_000, 40_000, 50_000])

          report = @heap_size_warmup.tuning_report

          assert_equal(HeapSizeWarmup::REPORT_ASSIST_MESSAGE, report.assist_message)
          assert_equal(4, report.env_name.length)
          assert_equal(4, report.suggested_value.length)
          assert_equal(4, report.configured_value.length)

          (HeapSizeWarmup::HEAP_NAMES - ["1"]).each_with_index do |heap_name, i|
            assert_equal("RUBY_GC_HEAP_#{heap_name}_INIT_SLOTS", report.env_name[i])
          end
          assert_equal(50_000, report.configured_value[2])
        else
          # Incorrect configured value
          ENV["RUBY_GC_HEAP_INIT_SLOTS"] = "20000"

          insert_plateau_data(30_000)

          report = @heap_size_warmup.tuning_report

          assert_equal(HeapSizeWarmup::REPORT_ASSIST_MESSAGE, report.assist_message)
          assert_equal(1, report.env_name.length)
          assert_equal(1, report.suggested_value.length)
          assert_equal(1, report.configured_value.length)

          assert_equal("RUBY_GC_HEAP_INIT_SLOTS", report.env_name[0])
          assert_equal(20_000, report.configured_value[0])
        end
      ensure
        ENV.replace(original_env)
      end

      def test_tuning_report_with_perfect_configured_values
        original_env = ENV.to_h

        if HeapSizeWarmup::SUPPORT_MULTI_HEAP_P
          configured_values = HeapSizeWarmup::HEAP_NAMES.length.times.map { |i| i * 10_000 }
          HeapSizeWarmup::HEAP_NAMES.each_with_index do |heap_name, i|
            ENV["RUBY_GC_HEAP_#{heap_name}_INIT_SLOTS"] = configured_values[i].to_s
          end

          insert_plateau_data(configured_values)
        else
          ENV["RUBY_GC_HEAP_INIT_SLOTS"] = "10000"

          insert_plateau_data(10_000)
        end

        assert_nil(@heap_size_warmup.tuning_report)
      ensure
        ENV.replace(original_env)
      end

      def test_tuning_report_when_not_ready
        report = @heap_size_warmup.tuning_report

        assert_nil(report)

        # Insert non-platueau data
        request_time = 0
        (Configuration::DATA_POINTS_COUNT + 1).times do |_i|
          request_time += 10
          @request_context.stubs(:request_time).returns(request_time)

          @system_context.update(@request_context)
          @heap_size_warmup.call(@request_context)
        end

        report = @heap_size_warmup.tuning_report

        assert_nil(report)
      end

      def test_tuning_report_does_not_give_suggestion_twice
        insert_plateau_data

        report = @heap_size_warmup.tuning_report

        refute_nil(report)

        report = @heap_size_warmup.tuning_report

        assert_nil(report)
      end

      def test_debug_state
        insert_plateau_data

        @heap_size_warmup.tuning_report
        state = @heap_size_warmup.debug_state

        assert(state[:given_suggestion])
      end

      def test_debug_state_with_initial_configuration
        original_env = ENV.to_h

        if HeapSizeWarmup::SUPPORT_MULTI_HEAP_P
          ENV["RUBY_GC_HEAP_0_INIT_SLOTS"] = "10000"
          ENV["RUBY_GC_HEAP_2_INIT_SLOTS"] = "20000"

          insert_plateau_data

          @heap_size_warmup.tuning_report
          state = @heap_size_warmup.debug_state

          assert(state[:given_suggestion])

          assert_equal("10000", state[:"ENV[RUBY_GC_HEAP_0_INIT_SLOTS]"])
          assert_equal("20000", state[:"ENV[RUBY_GC_HEAP_2_INIT_SLOTS]"])
          refute(state.key?(:"ENV[RUBY_GC_HEAP_1_INIT_SLOTS]"))
        else
          ENV["RUBY_GC_HEAP_INIT_SLOTS"] = "10000"

          insert_plateau_data

          @heap_size_warmup.tuning_report
          state = @heap_size_warmup.debug_state

          assert(state[:given_suggestion])

          assert_equal("10000", state[:"ENV[RUBY_GC_HEAP_INIT_SLOTS]"])
        end
      ensure
        ENV.replace(original_env)
      end

      def test_debug_state_with_no_data
        state = @heap_size_warmup.debug_state

        refute(state[:given_suggestion])
      end

      private

      def insert_plateau_data(heap_slots = nil)
        if HeapSizeWarmup::SUPPORT_MULTI_HEAP_P
          HeapSizeWarmup::HEAP_NAMES.length.times do |i|
            @request_context.after_gc_context.stat_heap[i][:heap_eden_slots] =
              heap_slots ? heap_slots[i] : rand(100)
          end
        else
          @request_context.after_gc_context.stat[:heap_available_slots] = heap_slots ? heap_slots : rand(100)
        end

        (Configuration::DATA_POINTS_COUNT + 1).times do |_i|
          @request_context.stubs(:request_time).returns(100 + rand(2))
          @system_context.update(@request_context)
          @heap_size_warmup.call(@request_context)
        end
      end
    end
  end
end
