# frozen_string_literal: true

module Autotuner
  module Heuristic
    class HeapSizeWarmup < Base
      class << self
        def supported?
          # Ruby 3.2 uses multiple heaps but does not support the
          # RUBY_GC_HEAP_%d_INIT_SLOTS environment variables, so we cannot
          # accurately tune the heap size.
          !RUBY_VERSION.start_with?("3.2.")
        end
      end

      # Ruby 3.3.0 and later have support for RUBY_GC_HEAP_%d_INIT_SLOTS
      SUPPORT_MULTI_HEAP_P = RUBY_VERSION >= "3.3.0"

      HEAP_NAMES =
        if SUPPORT_MULTI_HEAP_P
          GC.stat_heap.keys.map(&:to_s).freeze
        else
          [nil]
        end

      HEAP_SIZE_CONFIGURATION_DELTA_RATIO = 0.01
      HEAP_SIZE_CONFIGURATION_DELTA = 1_000

      REPORT_ASSIST_MESSAGE = <<~MSG
        The following suggestions adjust the size of the heap at boot time, which can improve bootup speed and reduce the time taken for the app to reach peak performance.
      MSG

      def initialize(_system_context)
        super

        @heaps_data = Array.new(HEAP_NAMES.length)
        HEAP_NAMES.length.times do |i|
          @heaps_data[i] = DataStructure::DataPoints.new(Configuration::DATA_POINTS_COUNT)
        end

        @given_suggestion = false
      end

      def name
        "HeapSizeWarmup"
      end

      def call(request_context)
        # We only want to collect data at boot until plateau
        return if @given_suggestion

        @heaps_data.each_with_index do |data, i|
          value =
            if SUPPORT_MULTI_HEAP_P
              request_context.after_gc_context.stat_heap[i][:heap_eden_slots]
            else
              request_context.after_gc_context.stat[:heap_available_slots]
            end

          data.insert(value)
        end
      end

      def tuning_report
        # Don't give suggestions twice
        return if @given_suggestion
        # The request time should plateau
        return unless @system_context.request_time_data.plateaued?

        @given_suggestion = true

        env_names = []
        suggested_values = []
        configured_values = []
        HEAP_NAMES.each_with_index do |heap_name, i|
          env_name = env_name_for_heap(heap_name)

          data = @heaps_data[i]
          suggested_value = data.samples[data.length - 1].to_i

          env_val = ENV[env_name]
          configured_value = env_val&.to_i

          if configured_value
            diff = (suggested_value - configured_value).abs

            # Don't report this if it's within the ratio
            next if diff <= configured_value * HEAP_SIZE_CONFIGURATION_DELTA_RATIO
            # Don't report this if it's within the delta
            next if diff <= HEAP_SIZE_CONFIGURATION_DELTA
          end

          env_names << env_name
          suggested_values << suggested_value
          configured_values << configured_value
        end

        # Don't generate report if there is nothing to report
        return if suggested_values.empty?

        Report::MultipleEnvironmentVariables.new(
          name,
          REPORT_ASSIST_MESSAGE,
          env_names,
          suggested_values,
          configured_values,
        )
      end

      def debug_state
        state = {
          given_suggestion: @given_suggestion,
        }

        # Don't output @heaps_data because there is too much data.

        HEAP_NAMES.each do |heap_name|
          env_var = env_name_for_heap(heap_name)
          env_val = ENV[env_var]
          state[:"ENV[#{env_var}]"] = env_val if env_val
        end

        state
      end

      def env_name_for_heap(heap_name)
        if SUPPORT_MULTI_HEAP_P
          "RUBY_GC_HEAP_#{heap_name}_INIT_SLOTS"
        else
          "RUBY_GC_HEAP_INIT_SLOTS"
        end
      end
    end
  end
end
