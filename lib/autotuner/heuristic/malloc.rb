# frozen_string_literal: true

module Autotuner
  module Heuristic
    class Malloc < Base
      NAME = "Malloc"

      MALLOC_GC_RATIO_THRESHOLD = 0.1
      MIN_MALLOC_GC = 10

      DEFAULT_MALLOC_LIMIT = 16 * 1024 * 1024
      DEFAULT_MALLOC_LIMIT_MAX = 32 * 1024 * 1024

      LIMIT_ENV = "RUBY_GC_MALLOC_LIMIT"
      LIMIT_MAX_ENV = "RUBY_GC_MALLOC_LIMIT_MAX"

      attr_reader :minor_gc_count
      attr_reader :malloc_gc_count

      class << self
        private

        def supported?
          true
        end
      end

      def initialize
        super

        @minor_gc_count = 0
        @malloc_gc_count = 0

        @given_suggestion = false
      end

      def name
        NAME
      end

      def call(_request_time, before_gc_context, after_gc_context)
        # gc_by is only useful if we ran at least one minor GC during the request.
        return if after_gc_context.stat[:minor_gc_count] == before_gc_context.stat[:minor_gc_count]
        # gc_by is only useful if it wasn't a major GC.
        # It is a major GC when where is a major_by reason set.
        return if after_gc_context.latest_gc_info[:major_by]

        @minor_gc_count += 1
        @malloc_gc_count += 1 if after_gc_context.latest_gc_info[:gc_by] == :malloc
      end

      def tuning_report
        # Don't give suggestions twice.
        return if @given_suggestion
        # Don't report if there's very few data points
        return if malloc_gc_count < MIN_MALLOC_GC

        malloc_gc_ratio = malloc_gc_count.to_f / minor_gc_count
        # Don't report if there's very few malloc GC.
        return if malloc_gc_ratio <= MALLOC_GC_RATIO_THRESHOLD

        @given_suggestion = true

        Report::MultipleEnvironmentVariables.new(
          <<~MSG,
            The following suggestions reduces the number of minor garbage collection cycles, specifically a cycle called "malloc". Your app runs malloc cycles in approximately #{format("%.2f", malloc_gc_ratio * 100)}% of all minor garbage collection cycles.

            Reducing minor garbage collection cycles can help reduce response times. The following tuning values aims to reduce malloc garbage collection cycles by setting it to a higher value. This may cause a slight increase in memory usage. You should monitor memory usage carefully to ensure your app is not running out of memory.
          MSG
          [LIMIT_ENV, LIMIT_MAX_ENV],
          # Suggest to double the limit and max
          [configured_malloc_limit * 2, configured_malloc_limit_max * 2],
          [ENV[LIMIT_ENV]&.to_i, ENV[LIMIT_MAX_ENV]&.to_i],
        )
      end

      def debug_state
        {
          given_suggestion: @given_suggestion,
          minor_gc_count: minor_gc_count,
          malloc_gc_count: malloc_gc_count,
        }
      end

      private

      def configured_malloc_limit
        ENV[LIMIT_ENV]&.to_i || DEFAULT_MALLOC_LIMIT
      end

      def configured_malloc_limit_max
        ENV[LIMIT_MAX_ENV]&.to_i || DEFAULT_MALLOC_LIMIT_MAX
      end
    end
  end
end
