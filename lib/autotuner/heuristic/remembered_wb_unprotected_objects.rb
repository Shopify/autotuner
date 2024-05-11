# frozen_string_literal: true

module Autotuner
  module Heuristic
    class RememberedWBUnprotectedObjects < Base
      class << self
        private

        def supported?
          # Ruby 3.3.0 and later have support RUBY_GC_HEAP_REMEMBERED_WB_UNPROTECTED_OBJECTS_LIMIT_RATIO
          RUBY_VERSION >= "3.3.0"
        end
      end

      WB_UNPROTECTED_GC_RATIO_THRESHOLD = 0.1
      MIN_WB_UNPROTECTED_GC = 10

      # From the GC_HEAP_REMEMBERED_WB_UNPROTECTED_OBJECTS_LIMIT_RATIO macro
      # https://github.com/ruby/ruby/blob/df4c77608e76068deed58b2781674b0eb247c325/gc.c#L295
      DEFAULT_LIMIT_RATIO = 0.01

      LIMIT_RATIO_ENV = "RUBY_GC_HEAP_REMEMBERED_WB_UNPROTECTED_OBJECTS_LIMIT_RATIO"

      attr_reader :major_gc_count
      attr_reader :remembered_wb_unprotected_gc_count

      def initialize(_system_context)
        super

        @major_gc_count = 0
        @remembered_wb_unprotected_gc_count = 0

        @given_suggestion = false
      end

      def name
        "WBUnprotectedObjects"
      end

      def call(request_context)
        # major_by is only useful if we ran at least one major GC during the request
        if request_context.after_gc_context.stat[:major_gc_count] ==
            request_context.before_gc_context.stat[:major_gc_count]
          return
        end

        # Technically, we could run more than one major GC in the request, but
        # since we don't have information about the other major GC, we'll treat
        # it as if there was only one major GC.
        @major_gc_count += 1
        @remembered_wb_unprotected_gc_count += 1 if request_context.after_gc_context.latest_gc_info[:major_by] == :shady
      end

      def tuning_report
        # Don't give suggestions twice
        return if @given_suggestion
        # Don't report if there's very few data points
        return if @remembered_wb_unprotected_gc_count < MIN_WB_UNPROTECTED_GC

        wb_unprotected_gc_ratio = @remembered_wb_unprotected_gc_count.to_f / @major_gc_count
        # Don't report if there's very few WB unprotected GC
        return if wb_unprotected_gc_ratio <= WB_UNPROTECTED_GC_RATIO_THRESHOLD

        @given_suggestion = true

        Report::SingleEnvironmentVariable.new(
          name,
          <<~MSG,
            The following suggestions reduce the number of major garbage collection cycles, specifically a cycle called "remembered write barrier unprotected" (also know as "shady" due to historical reasons). Your app runs remembered write barrier unprotected cycles in approximately #{format("%.2f", wb_unprotected_gc_ratio * 100)}% of all major garbage collection cycles.

            Reducing major garbage collection cycles can help reduce response times, especially for the extremes (e.g. p95 or p99 response times). The following tuning values aim to disable oldmalloc garbage collection cycles by setting it to an extremely high value. This may cause a slight increase in memory usage. You should monitor memory usage carefully to ensure your app is not running out of memory.
          MSG
          LIMIT_RATIO_ENV,
          suggested_limit_ratio,
          configured_limit_ratio,
        )
      end

      def debug_state
        {
          given_suggestion: @given_suggestion,
          major_gc_count: @major_gc_count,
          remembered_wb_unprotected_gc_count: @remembered_wb_unprotected_gc_count,
        }
      end

      private

      def configured_limit_ratio
        ENV[LIMIT_RATIO_ENV]&.to_f
      end

      def suggested_limit_ratio
        if !configured_limit_ratio
          DEFAULT_LIMIT_RATIO * 2
        elsif configured_limit_ratio < DEFAULT_LIMIT_RATIO
          DEFAULT_LIMIT_RATIO
        else
          configured_limit_ratio * 2
        end
      end
    end
  end
end
