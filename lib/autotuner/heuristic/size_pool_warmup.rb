# frozen_string_literal: true

module Autotuner
  module Heuristic
    class SizePoolWarmup < Base
      class << self
        private

        def supported?
          # Ruby 3.3.0 and later have support RUBY_GC_HEAP_INIT_SIZE_%d_SLOTS
          # RUBY_VERSION >= "3.3.0"
          # TODO: use the check above
          true
        end
      end

      NAME = "SizePoolWarmup"

      SIZE_POOL_COUNT = GC::INTERNAL_CONSTANTS[:SIZE_POOL_COUNT]

      SIZE_POOL_CONFIGURATION_DELTA_RATIO = 0.01
      SIZE_POOL_CONFIGURATION_DELTA = 1_000

      REPORT_ASSIST_MESSAGE = <<~MSG
        The following suggestions adjusts the size of heap at boot time, which can improve bootup speed and reduce the time taken for the app to reach peak performance.
      MSG

      def initialize(_system_context)
        super

        @size_pools_data = Array.new(SIZE_POOL_COUNT)
        SIZE_POOL_COUNT.times do |i|
          @size_pools_data[i] = DataStructure::DataPoints.new(Configuration::DATA_POINTS_COUNT)
        end

        @given_suggestion = false
      end

      def name
        NAME
      end

      def call(request_context)
        # We only want to collect data at boot until plateau
        return if @given_suggestion

        @size_pools_data.each_with_index do |data, i|
          data.insert(request_context.after_gc_context.stat_heap[i][:heap_eden_slots])
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
        SIZE_POOL_COUNT.times do |i|
          env_name = env_name_for_size_pool(i)

          data = @size_pools_data[i]
          suggested_value = data.samples[data.length - 1].to_i

          env_val = ENV[env_name]
          configured_value = env_val&.to_i

          if configured_value
            diff = (suggested_value - configured_value).abs

            # Don't report this if it's within the ratio
            next if diff <= configured_value * SIZE_POOL_CONFIGURATION_DELTA_RATIO
            # Don't report this if it's within the delta
            next if diff <= SIZE_POOL_CONFIGURATION_DELTA
          end

          env_names << env_name
          suggested_values << suggested_value
          configured_values << configured_value
        end

        # Don't generate report if there is nothing to report
        return if suggested_values.empty?

        Report::MultipleEnvironmentVariables.new(REPORT_ASSIST_MESSAGE, env_names, suggested_values, configured_values)
      end

      def debug_state
        state = {
          given_suggestion: @given_suggestion,
        }

        # Don't output @size_pools_data because there is too much data.

        SIZE_POOL_COUNT.times do |i|
          env_var = env_name_for_size_pool(i)
          env_val = ENV[env_var]
          state[:"ENV[#{env_var}]"] = env_val if env_val
        end

        state
      end

      def env_name_for_size_pool(size_pool)
        slot_size = GC::INTERNAL_CONSTANTS[:BASE_SLOT_SIZE] * (2**size_pool)

        "RUBY_GC_HEAP_INIT_SIZE_#{slot_size}_SLOTS"
      end
    end
  end
end
