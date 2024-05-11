# frozen_string_literal: true

module Autotuner
  module Heuristic
    class TestRememberedWBUnprotectedObjects < Minitest::Test
      def setup
        skip if RUBY_VERSION < "3.3.0"

        @remembered_wb_unprotected_objects = RememberedWBUnprotectedObjects.new(nil)
        @request_context = RequestContext.new

        @request_context.after_gc_context.stat[:major_gc_count] =
          @request_context.before_gc_context.stat[:major_gc_count] + 1
        @request_context.after_gc_context.latest_gc_info[:major_by] = :shady
      end

      def test_enabled?
        assert_predicate(RememberedWBUnprotectedObjects, :enabled?)
      end

      def test_call_increments_major_and_wb_unprotected_counts
        @remembered_wb_unprotected_objects.call(@request_context)

        assert_equal(1, @remembered_wb_unprotected_objects.major_gc_count)
        assert_equal(1, @remembered_wb_unprotected_objects.remembered_wb_unprotected_gc_count)
      end

      def test_call_increments_major_count
        @request_context.after_gc_context.latest_gc_info[:major_by] = :nofree
        @remembered_wb_unprotected_objects.call(@request_context)

        assert_equal(1, @remembered_wb_unprotected_objects.major_gc_count)
        assert_equal(0, @remembered_wb_unprotected_objects.remembered_wb_unprotected_gc_count)
      end

      def test_call_does_not_increment_when_no_major_gc_ran
        @request_context.after_gc_context.stat[:major_gc_count] =
          @request_context.before_gc_context.stat[:major_gc_count]
        @remembered_wb_unprotected_objects.call(@request_context)

        assert_equal(0, @remembered_wb_unprotected_objects.major_gc_count)
        assert_equal(0, @remembered_wb_unprotected_objects.remembered_wb_unprotected_gc_count)
      end

      def test_tuning_report
        RememberedWBUnprotectedObjects::MIN_WB_UNPROTECTED_GC.times do
          @request_context.after_gc_context.latest_gc_info[:major_by] = :shady
          @remembered_wb_unprotected_objects.call(@request_context)

          @request_context.after_gc_context.latest_gc_info[:major_by] = :nofree
          @remembered_wb_unprotected_objects.call(@request_context)
        end

        report = @remembered_wb_unprotected_objects.tuning_report

        assert_equal("WBUnprotectedObjects", report.heuristic_name)
        assert_includes(report.assist_message, "50.00%")
        assert_equal(RememberedWBUnprotectedObjects::LIMIT_RATIO_ENV, report.env_name)
        assert_equal(RememberedWBUnprotectedObjects::DEFAULT_LIMIT_RATIO * 2, report.suggested_value)
        assert_nil(report.configured_value)
      end

      def test_tuning_report_with_configured_value
        original_env = ENV.to_h

        ENV["RUBY_GC_HEAP_REMEMBERED_WB_UNPROTECTED_OBJECTS_LIMIT_RATIO"] = "0.25"

        RememberedWBUnprotectedObjects::MIN_WB_UNPROTECTED_GC.times do
          @request_context.after_gc_context.latest_gc_info[:major_by] = :shady
          @remembered_wb_unprotected_objects.call(@request_context)

          @request_context.after_gc_context.latest_gc_info[:major_by] = :nofree
          @remembered_wb_unprotected_objects.call(@request_context)
        end

        report = @remembered_wb_unprotected_objects.tuning_report

        assert_includes(report.assist_message, "50.00%")
        assert_equal(RememberedWBUnprotectedObjects::LIMIT_RATIO_ENV, report.env_name)
        assert_equal(0.5, report.suggested_value)
        assert_equal(0.25, report.configured_value)
      ensure
        ENV.replace(original_env)
      end

      def test_tuning_report_with_configured_value_lower_than_default
        original_env = ENV.to_h

        ENV["RUBY_GC_HEAP_REMEMBERED_WB_UNPROTECTED_OBJECTS_LIMIT_RATIO"] = "0.0"

        RememberedWBUnprotectedObjects::MIN_WB_UNPROTECTED_GC.times do
          @request_context.after_gc_context.latest_gc_info[:major_by] = :shady
          @remembered_wb_unprotected_objects.call(@request_context)

          @request_context.after_gc_context.latest_gc_info[:major_by] = :nofree
          @remembered_wb_unprotected_objects.call(@request_context)
        end

        report = @remembered_wb_unprotected_objects.tuning_report

        assert_includes(report.assist_message, "50.00%")
        assert_equal(RememberedWBUnprotectedObjects::LIMIT_RATIO_ENV, report.env_name)
        assert_equal(RememberedWBUnprotectedObjects::DEFAULT_LIMIT_RATIO, report.suggested_value)
        assert_equal(0.0, report.configured_value)
      ensure
        ENV.replace(original_env)
      end

      def test_tuning_report_when_not_ready
        assert_nil(@remembered_wb_unprotected_objects.tuning_report)
      end

      def test_tuning_report_below_min_wb_unprotected_gc
        (RememberedWBUnprotectedObjects::MIN_WB_UNPROTECTED_GC - 1).times do
          @request_context.after_gc_context.latest_gc_info[:major_by] = :shady
          @remembered_wb_unprotected_objects.call(@request_context)
        end

        assert_nil(@remembered_wb_unprotected_objects.tuning_report)
      end

      def test_tuning_report_below_ratio
        RememberedWBUnprotectedObjects::MIN_WB_UNPROTECTED_GC.times do
          @request_context.after_gc_context.latest_gc_info[:major_by] = :shady
          @remembered_wb_unprotected_objects.call(@request_context)

          (1 / RememberedWBUnprotectedObjects::WB_UNPROTECTED_GC_RATIO_THRESHOLD).to_i.times do
            @request_context.after_gc_context.latest_gc_info[:major_by] = :nofree
            @remembered_wb_unprotected_objects.call(@request_context)
          end
        end

        assert_nil(@remembered_wb_unprotected_objects.tuning_report)
      end

      def test_tuning_report_does_not_give_suggestion_twice
        RememberedWBUnprotectedObjects::MIN_WB_UNPROTECTED_GC.times do
          @request_context.after_gc_context.latest_gc_info[:major_by] = :shady
          @remembered_wb_unprotected_objects.call(@request_context)
        end

        refute_nil(@remembered_wb_unprotected_objects.tuning_report)
        assert_nil(@remembered_wb_unprotected_objects.tuning_report)
      end

      def test_debug_state
        RememberedWBUnprotectedObjects::MIN_WB_UNPROTECTED_GC.times do
          @request_context.after_gc_context.latest_gc_info[:major_by] = :shady
          @remembered_wb_unprotected_objects.call(@request_context)

          @request_context.after_gc_context.latest_gc_info[:major_by] = :nofree
          @remembered_wb_unprotected_objects.call(@request_context)
        end

        @remembered_wb_unprotected_objects.tuning_report

        state = @remembered_wb_unprotected_objects.debug_state

        assert(state[:given_suggestion])
        assert_equal(RememberedWBUnprotectedObjects::MIN_WB_UNPROTECTED_GC * 2, state[:major_gc_count])
        assert_equal(RememberedWBUnprotectedObjects::MIN_WB_UNPROTECTED_GC, state[:remembered_wb_unprotected_gc_count])
      end

      def test_debug_state_with_no_data
        state = @remembered_wb_unprotected_objects.debug_state

        refute(state[:given_suggestion])
        assert_equal(0, state[:major_gc_count])
        assert_equal(0, state[:remembered_wb_unprotected_gc_count])
      end
    end
  end
end
