# frozen_string_literal: true

module Autotuner
  module Heuristic
    class TestMalloc < Minitest::Test
      def setup
        @malloc = Malloc.new(nil)
        @before_gc_context = GCContext.new
        @after_gc_context = GCContext.new

        @after_gc_context.stat[:minor_gc_count] = @before_gc_context.stat[:minor_gc_count] + 1
        @after_gc_context.latest_gc_info[:major_by] = nil
        @after_gc_context.latest_gc_info[:gc_by] = :malloc
      end

      def test_enabled?
        assert_predicate(Malloc, :enabled?)
      end

      def test_call_increments_minor_and_malloc_counts
        @malloc.call(10.0, @before_gc_context, @after_gc_context)

        assert_equal(1, @malloc.minor_gc_count)
        assert_equal(1, @malloc.malloc_gc_count)
      end

      def test_call_increments_minor_count
        @after_gc_context.latest_gc_info[:gc_by] = :newobj
        @malloc.call(10.0, @before_gc_context, @after_gc_context)

        assert_equal(1, @malloc.minor_gc_count)
        assert_equal(0, @malloc.malloc_gc_count)
      end

      def test_call_does_not_increment_for_major_gc
        @after_gc_context.latest_gc_info[:major_by] = :force
        @malloc.call(10.0, @before_gc_context, @after_gc_context)

        assert_equal(0, @malloc.minor_gc_count)
        assert_equal(0, @malloc.malloc_gc_count)
      end

      def test_call_does_not_increment_when_no_minor_gc_ran
        @after_gc_context.stat[:minor_gc_count] = @before_gc_context.stat[:minor_gc_count]
        @malloc.call(10.0, @before_gc_context, @after_gc_context)

        assert_equal(0, @malloc.minor_gc_count)
        assert_equal(0, @malloc.malloc_gc_count)
      end

      def test_tuning_report
        Malloc::MIN_MALLOC_GC.times do
          @after_gc_context.latest_gc_info[:gc_by] = :malloc
          @malloc.call(10.0, @before_gc_context, @after_gc_context)

          @after_gc_context.latest_gc_info[:gc_by] = :newobj
          @malloc.call(10.0, @before_gc_context, @after_gc_context)
        end

        report = @malloc.tuning_report

        assert_includes(report.assist_message, "50.00%")
        assert_equal([Malloc::LIMIT_ENV, Malloc::LIMIT_MAX_ENV], report.env_name)
        assert_equal(
          [Malloc::DEFAULT_MALLOC_LIMIT * 2, Malloc::DEFAULT_MALLOC_LIMIT_MAX * 2],
          report.suggested_value,
        )
        assert_equal([nil, nil], report.configured_value)
      end

      def test_tuning_report_with_configured_values
        original_env = ENV.to_h

        ENV["RUBY_GC_MALLOC_LIMIT"] = "100"
        ENV["RUBY_GC_MALLOC_LIMIT_MAX"] = "200"

        Malloc::MIN_MALLOC_GC.times do
          @after_gc_context.latest_gc_info[:gc_by] = :malloc
          @malloc.call(10.0, @before_gc_context, @after_gc_context)

          @after_gc_context.latest_gc_info[:gc_by] = :newobj
          @malloc.call(10.0, @before_gc_context, @after_gc_context)
        end

        report = @malloc.tuning_report

        assert_includes(report.assist_message, "50.00%")
        assert_equal([Malloc::LIMIT_ENV, Malloc::LIMIT_MAX_ENV], report.env_name)
        assert_equal(
          [200, 400],
          report.suggested_value,
        )
        assert_equal([100, 200], report.configured_value)
      ensure
        ENV.replace(original_env)
      end

      def test_tuning_report_when_not_ready
        assert_nil(@malloc.tuning_report)
      end

      def test_tuning_report_below_min_malloc
        (Malloc::MIN_MALLOC_GC - 1).times do
          @after_gc_context.latest_gc_info[:gc_by] = :malloc
          @malloc.call(10.0, @before_gc_context, @after_gc_context)
        end

        assert_nil(@malloc.tuning_report)
      end

      def test_tuning_report_below_ratio
        Malloc::MIN_MALLOC_GC.times do
          @after_gc_context.latest_gc_info[:gc_by] = :malloc
          @malloc.call(10.0, @before_gc_context, @after_gc_context)

          (1 / Malloc::MALLOC_GC_RATIO_THRESHOLD).to_i.times do
            @after_gc_context.latest_gc_info[:gc_by] = :newobj
            @malloc.call(10.0, @before_gc_context, @after_gc_context)
          end
        end

        assert_nil(@malloc.tuning_report)
      end

      def test_tuning_report_does_not_give_suggestion_twice
        Malloc::MIN_MALLOC_GC.times do
          @after_gc_context.latest_gc_info[:gc_by] = :malloc
          @malloc.call(10.0, @before_gc_context, @after_gc_context)
        end

        refute_nil(@malloc.tuning_report)
        assert_nil(@malloc.tuning_report)
      end

      def test_debug_state
        Malloc::MIN_MALLOC_GC.times do
          @after_gc_context.latest_gc_info[:gc_by] = :malloc
          @malloc.call(10.0, @before_gc_context, @after_gc_context)

          @after_gc_context.latest_gc_info[:gc_by] = :newobj
          @malloc.call(10.0, @before_gc_context, @after_gc_context)
        end

        @malloc.tuning_report

        state = @malloc.debug_state

        assert(state[:given_suggestion])
        assert_equal(Malloc::MIN_MALLOC_GC * 2, state[:minor_gc_count])
        assert_equal(Malloc::MIN_MALLOC_GC, state[:malloc_gc_count])
      end

      def test_debug_state_with_no_data
        state = @malloc.debug_state

        refute(state[:given_suggestion])
        assert_equal(0, state[:minor_gc_count])
        assert_equal(0, state[:malloc_gc_count])
      end
    end
  end
end
