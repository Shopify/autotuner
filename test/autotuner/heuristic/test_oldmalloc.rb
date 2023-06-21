# frozen_string_literal: true

module Autotuner
  module Heuristic
    class TestOldmalloc < Minitest::Test
      def setup
        @oldmalloc = Oldmalloc.new
        @before_gc_context = GCContext.new
        @after_gc_context = GCContext.new
      end

      def test_tuning_report
        @after_gc_context.stat[:major_gc_count] = @before_gc_context.stat[:major_gc_count] + 1
        Oldmalloc::MIN_OLDMALLOC_GC.times do
          @after_gc_context.latest_gc_info[:major_by] = :oldmalloc
          @oldmalloc.call(10.0, @before_gc_context, @after_gc_context)

          @after_gc_context.latest_gc_info[:major_by] = :nofree
          @oldmalloc.call(10.0, @before_gc_context, @after_gc_context)
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

        @after_gc_context.stat[:major_gc_count] = @before_gc_context.stat[:major_gc_count] + 1
        Oldmalloc::MIN_OLDMALLOC_GC.times do
          @after_gc_context.latest_gc_info[:major_by] = :oldmalloc
          @oldmalloc.call(10.0, @before_gc_context, @after_gc_context)

          @after_gc_context.latest_gc_info[:major_by] = :nofree
          @oldmalloc.call(10.0, @before_gc_context, @after_gc_context)
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
        report = @oldmalloc.tuning_report

        assert_nil(report)
      end

      def test_tuning_report_below_min_oldmalloc
        @after_gc_context.stat[:major_gc_count] = @before_gc_context.stat[:major_gc_count] + 1
        (Oldmalloc::MIN_OLDMALLOC_GC - 1).times do
          @after_gc_context.latest_gc_info[:major_by] = :oldmalloc
          @oldmalloc.call(10.0, @before_gc_context, @after_gc_context)
        end

        report = @oldmalloc.tuning_report

        assert_nil(report)
      end

      def test_tuning_report_below_ratio
        @after_gc_context.stat[:major_gc_count] = @before_gc_context.stat[:major_gc_count] + 1
        Oldmalloc::MIN_OLDMALLOC_GC.times do
          @after_gc_context.latest_gc_info[:major_by] = :oldmalloc
          @oldmalloc.call(10.0, @before_gc_context, @after_gc_context)

          (1 / Oldmalloc::OLDMALLOC_GC_RATIO_THRESHOLD).to_i.times do
            @after_gc_context.latest_gc_info[:major_by] = :nofree
            @oldmalloc.call(10.0, @before_gc_context, @after_gc_context)
          end
        end

        report = @oldmalloc.tuning_report

        assert_nil(report)
      end

      def test_tuning_report_does_not_give_suggestion_twice
        @after_gc_context.stat[:major_gc_count] = @before_gc_context.stat[:major_gc_count] + 1
        Oldmalloc::MIN_OLDMALLOC_GC.times do
          @after_gc_context.latest_gc_info[:major_by] = :oldmalloc
          @oldmalloc.call(10.0, @before_gc_context, @after_gc_context)

          @after_gc_context.latest_gc_info[:major_by] = :nofree
          @oldmalloc.call(10.0, @before_gc_context, @after_gc_context)
        end

        refute_nil(@oldmalloc.tuning_report)
        assert_nil(@oldmalloc.tuning_report)
      end

      def test_debug_message
        msg = @oldmalloc.debug_message

        assert_includes(msg, "given_suggestion: false\n")
        assert_includes(msg, "major_gc_count: 0\n")
        assert_includes(msg, "oldmalloc_gc_count: 0\n")
      end
    end
  end
end
