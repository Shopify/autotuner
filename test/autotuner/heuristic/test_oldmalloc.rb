# frozen_string_literal: true

module Autotuner
  module Heuristic
    class TestOldmalloc < Minitest::Test
      def setup
        @oldmalloc = Oldmalloc.new(nil)
        @request_context = RequestContext.new

        @request_context.after_gc_context.stat[:major_gc_count] =
          @request_context.before_gc_context.stat[:major_gc_count] + 1
        @request_context.after_gc_context.latest_gc_info[:major_by] = :oldmalloc
      end

      def test_enabled?
        assert_predicate(Oldmalloc, :enabled?)
      end

      def test_call_increments_major_and_malloc_counts
        @oldmalloc.call(@request_context)

        assert_equal(1, @oldmalloc.major_gc_count)
        assert_equal(1, @oldmalloc.oldmalloc_gc_count)
      end

      def test_call_increments_major_count
        @request_context.after_gc_context.latest_gc_info[:major_by] = :force
        @oldmalloc.call(@request_context)

        assert_equal(1, @oldmalloc.major_gc_count)
        assert_equal(0, @oldmalloc.oldmalloc_gc_count)
      end

      def test_call_does_not_increment_when_no_major_gc_ran
        @request_context.after_gc_context.stat[:major_gc_count] =
          @request_context.before_gc_context.stat[:major_gc_count]
        @oldmalloc.call(@request_context)

        assert_equal(0, @oldmalloc.major_gc_count)
        assert_equal(0, @oldmalloc.oldmalloc_gc_count)
      end

      def test_tuning_report
        Oldmalloc::MIN_OLDMALLOC_GC.times do
          @request_context.after_gc_context.latest_gc_info[:major_by] = :oldmalloc
          @oldmalloc.call(@request_context)

          @request_context.after_gc_context.latest_gc_info[:major_by] = :nofree
          @oldmalloc.call(@request_context)
        end

        report = @oldmalloc.tuning_report

        assert_includes(report.assist_message, "50.00%")
        assert_equal([Oldmalloc::LIMIT_ENV, Oldmalloc::LIMIT_MAX_ENV], report.env_name)
        assert_equal(
          [Oldmalloc::LIMIT_ENV_SUGGESTED_VALUE, Oldmalloc::LIMIT_MAX_SUGGESTED_VALUE],
          report.suggested_value,
        )
        assert_equal([nil, nil], report.configured_value)
      end

      def test_tuning_report_with_configured_values
        original_env = ENV.to_h

        ENV["RUBY_GC_OLDMALLOC_LIMIT"] = "100"
        ENV["RUBY_GC_OLDMALLOC_LIMIT_MAX"] = "200"

        Oldmalloc::MIN_OLDMALLOC_GC.times do
          @request_context.after_gc_context.latest_gc_info[:major_by] = :oldmalloc
          @oldmalloc.call(@request_context)

          @request_context.after_gc_context.latest_gc_info[:major_by] = :nofree
          @oldmalloc.call(@request_context)
        end

        report = @oldmalloc.tuning_report

        assert_includes(report.assist_message, "50.00%")
        assert_equal([Oldmalloc::LIMIT_ENV, Oldmalloc::LIMIT_MAX_ENV], report.env_name)
        assert_equal(
          [Oldmalloc::LIMIT_ENV_SUGGESTED_VALUE, Oldmalloc::LIMIT_MAX_SUGGESTED_VALUE],
          report.suggested_value,
        )
        assert_equal([100, 200], report.configured_value)
      ensure
        ENV.replace(original_env)
      end

      def test_tuning_report_when_not_ready
        assert_nil(@oldmalloc.tuning_report)
      end

      def test_tuning_report_below_min_oldmalloc
        (Oldmalloc::MIN_OLDMALLOC_GC - 1).times do
          @oldmalloc.call(@request_context)
        end

        assert_nil(@oldmalloc.tuning_report)
      end

      def test_tuning_report_below_ratio
        Oldmalloc::MIN_OLDMALLOC_GC.times do
          @request_context.after_gc_context.latest_gc_info[:major_by] = :oldmalloc
          @oldmalloc.call(@request_context)

          (1 / Oldmalloc::OLDMALLOC_GC_RATIO_THRESHOLD).to_i.times do
            @request_context.after_gc_context.latest_gc_info[:major_by] = :nofree
            @oldmalloc.call(@request_context)
          end
        end

        assert_nil(@oldmalloc.tuning_report)
      end

      def test_tuning_report_does_not_give_suggestion_twice
        Oldmalloc::MIN_OLDMALLOC_GC.times do
          @request_context.after_gc_context.latest_gc_info[:major_by] = :oldmalloc
          @oldmalloc.call(@request_context)

          @request_context.after_gc_context.latest_gc_info[:major_by] = :nofree
          @oldmalloc.call(@request_context)
        end

        refute_nil(@oldmalloc.tuning_report)
        assert_nil(@oldmalloc.tuning_report)
      end

      def test_debug_state
        Oldmalloc::MIN_OLDMALLOC_GC.times do
          @request_context.after_gc_context.latest_gc_info[:major_by] = :oldmalloc
          @oldmalloc.call(@request_context)

          @request_context.after_gc_context.latest_gc_info[:major_by] = :nofree
          @oldmalloc.call(@request_context)
        end

        @oldmalloc.tuning_report

        state = @oldmalloc.debug_state

        assert(state[:given_suggestion])
        assert_equal(Oldmalloc::MIN_OLDMALLOC_GC * 2, state[:major_gc_count])
        assert_equal(Oldmalloc::MIN_OLDMALLOC_GC, state[:oldmalloc_gc_count])
      end

      def test_debug_state_with_no_data
        state = @oldmalloc.debug_state

        refute(state[:given_suggestion])
        assert_equal(0, state[:major_gc_count])
        assert_equal(0, state[:oldmalloc_gc_count])
      end
    end
  end
end
