# frozen_string_literal: true

module Autotuner
  module Heuristic
    class Oldmalloc < Base
      class << self
        def supported?
          true
        end
      end

      OLDMALLOC_GC_RATIO_THRESHOLD = 0.01
      MIN_OLDMALLOC_GC = 10

      LIMIT_ENV = "RUBY_GC_OLDMALLOC_LIMIT"
      LIMIT_MAX_ENV = "RUBY_GC_OLDMALLOC_LIMIT_MAX"

      # Except for aggressively decreasing memory usage, it doesn't make sense
      # for Rails apps to run oldmalloc major GC cycles. So we suggest an
      # extremely high value (around 1TB here) to essentially disable it.
      LIMIT_ENV_SUGGESTED_VALUE = 1_000_000_000_000
      LIMIT_MAX_SUGGESTED_VALUE = 1_000_000_000_000

      attr_reader :major_gc_count
      attr_reader :oldmalloc_gc_count

      def initialize(_system_context)
        super

        @major_gc_count = 0
        @oldmalloc_gc_count = 0

        @given_suggestion = false
      end

      def name
        "Oldmalloc"
      end

      def call(work_context)
        # major_by is only useful if we ran at least one major GC during the request
        if work_context.after_gc_context.stat[:major_gc_count] ==
            work_context.before_gc_context.stat[:major_gc_count]
          return
        end

        # Technically, we could run more than one major GC in the request, but
        # since we don't have information about the other major GC, we'll treat
        # it as if there was only one major GC.
        @major_gc_count += 1
        @oldmalloc_gc_count += 1 if work_context.after_gc_context.latest_gc_info[:major_by] == :oldmalloc
      end

      def tuning_report
        # Don't give suggestions twice
        return if @given_suggestion
        # Don't report if there's very few data points
        return if @oldmalloc_gc_count < MIN_OLDMALLOC_GC

        oldmalloc_gc_ratio = @oldmalloc_gc_count.to_f / @major_gc_count
        # Don't report if there's very few oldmalloc GC
        return if oldmalloc_gc_ratio <= OLDMALLOC_GC_RATIO_THRESHOLD

        @given_suggestion = true

        Report::MultipleEnvironmentVariables.new(
          name,
          <<~MSG,
            The following suggestions reduce the number of major garbage collection cycles, specifically a cycle called "oldmalloc". Your app runs oldmalloc cycles in approximately #{format("%.2f", oldmalloc_gc_ratio * 100)}% of all major garbage collection cycles.

            Reducing major garbage collection cycles can help reduce response times, especially for the extremes (e.g. p95 or p99 response times). The following tuning values aim to disable oldmalloc garbage collection cycles by setting it to an extremely high value. This may cause a slight increase in memory usage. You should monitor memory usage carefully to ensure your app is not running out of memory.
          MSG
          [LIMIT_ENV, LIMIT_MAX_ENV],
          [LIMIT_ENV_SUGGESTED_VALUE, LIMIT_MAX_SUGGESTED_VALUE],
          [ENV[LIMIT_ENV]&.to_i, ENV[LIMIT_MAX_ENV]&.to_i],
        )
      end

      def debug_state
        {
          given_suggestion: @given_suggestion,
          major_gc_count: @major_gc_count,
          oldmalloc_gc_count: @oldmalloc_gc_count,
        }
      end
    end
  end
end
