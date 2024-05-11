# frozen_string_literal: true

module Autotuner
  module Heuristic
    class TestGCCompact < Minitest::Test
      def setup
        @gc_compact = GCCompact.new(nil)

        @request_context = RequestContext.new
        @request_context.before_gc_context.stat[:compact_count] = 1
        @request_context.after_gc_context.stat[:compact_count] = 1
      end

      def test_enabled?
        assert_predicate(GCCompact, :enabled?)
      end

      def test_tuning_report
        # Test no GC compaction ran
        gc_compact = GCCompact.new(nil)
        gc_compact.call(RequestContext.new)

        report = gc_compact.tuning_report

        refute_nil(report)
        assert_equal("GCCompact", report.heuristic_name)

        # Does not give report twice
        report = gc_compact.tuning_report

        assert_nil(report)

        # Test GC compaction ran
        # We have to run these test in this exact order due to the call to
        # GC.compact is not reversible
        GC.compact
        gc_compact = GCCompact.new(nil)
        gc_compact.call(RequestContext.new)

        report = gc_compact.tuning_report

        assert_nil(report)
      end

      def test_debug_state
        @gc_compact.call(@request_context)

        state = @gc_compact.debug_state

        refute_nil(state[:called_gc_compact])
      end

      def test_debug_state_with_no_data
        state = @gc_compact.debug_state

        assert_nil(state[:called_gc_compact])
      end
    end
  end
end
