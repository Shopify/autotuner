# frozen_string_literal: true

module Autotuner
  module Heuristic
    class Malloc < Base
      class << self
        def supported?
          true
        end
      end

      MALLOC_GC_RATIO_THRESHOLD = 0.1
      MIN_MALLOC_GC = 10

      # From the GC_MALLOC_LIMIT_MIN macro
      # https://github.com/ruby/ruby/blob/3874381c4483ba7794ac2abf157e265546f9bfa7/gc.c#L312C9-L312C9
      DEFAULT_MALLOC_LIMIT = 16 * 1024 * 1024
      # From the GC_MALLOC_LIMIT_MAX macro
      # https://github.com/ruby/ruby/blob/3874381c4483ba7794ac2abf157e265546f9bfa7/gc.c#L315C9-L315C28
      DEFAULT_MALLOC_LIMIT_MAX = 32 * 1024 * 1024

      LIMIT_ENV = "RUBY_GC_MALLOC_LIMIT"
      LIMIT_MAX_ENV = "RUBY_GC_MALLOC_LIMIT_MAX"

      attr_reader :minor_gc_count
      attr_reader :malloc_gc_count

      def initialize(_system_context)
        super

        @minor_gc_count = 0
        @malloc_gc_count = 0

        @given_suggestion = false
      end

      def name
        "Malloc"
      end

      def call(request_context)
        # gc_by is only useful if we ran at least one minor GC during the request.
        if request_context.after_gc_context.stat[:minor_gc_count] ==
            request_context.before_gc_context.stat[:minor_gc_count]
          return
        end
        # gc_by is only useful if it wasn't a major GC.
        # It is a major GC when where is a major_by reason set.
        return if request_context.after_gc_context.latest_gc_info[:major_by]

        @minor_gc_count += 1
        @malloc_gc_count += 1 if request_context.after_gc_context.latest_gc_info[:gc_by] == :malloc
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
            The following suggestions reduce the number of minor garbage collection cycles, specifically a cycle called "malloc". Your app runs malloc cycles in approximately #{format("%.2f", malloc_gc_ratio * 100)}% of all minor garbage collection cycles.

            Reducing minor garbage collection cycles can help reduce response times. The following tuning values aim to reduce malloc garbage collection cycles by setting it to a higher value. This may cause a slight increase in memory usage. You should monitor memory usage carefully to ensure your app is not running out of memory.
          MSG
          [LIMIT_ENV, LIMIT_MAX_ENV],
          # Suggest to double the limit and max
          [suggested_malloc_limit, suggested_malloc_limit_max],
          [configured_malloc_limit, configured_malloc_limit_max],
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
        ENV[LIMIT_ENV]&.to_i
      end

      def configured_malloc_limit_max
        ENV[LIMIT_MAX_ENV]&.to_i
      end

      def suggested_malloc_limit
        if !configured_malloc_limit
          DEFAULT_MALLOC_LIMIT * 2
        elsif configured_malloc_limit < DEFAULT_MALLOC_LIMIT
          DEFAULT_MALLOC_LIMIT
        else
          configured_malloc_limit * 2
        end
      end

      def suggested_malloc_limit_max
        if !configured_malloc_limit_max
          DEFAULT_MALLOC_LIMIT_MAX * 2
        elsif configured_malloc_limit_max < DEFAULT_MALLOC_LIMIT_MAX
          DEFAULT_MALLOC_LIMIT_MAX
        else
          configured_malloc_limit_max * 2
        end
      end
    end
  end
end
