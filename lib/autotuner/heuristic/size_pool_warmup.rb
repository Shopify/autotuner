# frozen_string_literal: true

module Autotuner
  module Heuristic
    class SizePoolWarmup < Base
      NAME = "SizePoolWarmup"

      SIZE_POOL_COUNT = GC::INTERNAL_CONSTANTS[:SIZE_POOL_COUNT]

      DATA_POINTS_COUNT = 1_000
      SIZE_POOL_CONFIGURATION_DELTA_RATIO = 0.01
      SIZE_POOL_CONFIGURATION_DELTA = 1_000

      REPORT_ASSIST_MESSAGE = <<~MSG
        The following suggestions adjusts the size of heap at boot time, which can improve bootup speed and reduce the time taken for the app to reach peak performance.
      MSG

      class << self
        private

        def supported?
          # Ruby 3.3.0 and later have support RUBY_GC_HEAP_INIT_SIZE_%d_SLOTS
          # RUBY_VERSION >= "3.3.0"
          # TODO: use the check above
          true
        end
      end

      def initialize
        super

        @request_time_data = DataStructure::DataPoints.new(DATA_POINTS_COUNT)

        @size_pools_data = Array.new(SIZE_POOL_COUNT)
        SIZE_POOL_COUNT.times do |i|
          @size_pools_data[i] = DataStructure::DataPoints.new(DATA_POINTS_COUNT)
        end

        @given_suggestion = false
      end

      def name
        NAME
      end

      def call(request_time, _before_gc_context, after_gc_context)
        # We only want to collect data at boot until plateau
        return if @given_suggestion

        insert_data(request_time, after_gc_context)
      end

      def tuning_report
        # Don't give suggestions twice
        return if @given_suggestion
        # The request time should plateau
        return unless @request_time_data.plateaued?

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

        Report.new(REPORT_ASSIST_MESSAGE, env_names, suggested_values, configured_values)
      end

      def debug_message
        msg = +<<~MSG
          given_suggestion: #{@given_suggestion}
          request_time_data: #{@request_time_data}
        MSG

        @size_pools_data.each_with_index do |data, i|
          msg << "size_pools_data[#{i}]: #{data}\n"
        end

        SIZE_POOL_COUNT.times do |i|
          env_var = env_name_for_size_pool(i)
          env_val = ENV[env_var]
          msg << "ENV[#{env_var}]: #{env_val}\n" if env_val
        end

        msg.freeze
      end

      private

      def insert_data(request_time, after_gc_context)
        @request_time_data.insert(request_time)

        @size_pools_data.each_with_index do |data, i|
          data.insert(after_gc_context.stat_heap[i][:heap_eden_slots])
        end
      end

      def env_name_for_size_pool(size_pool)
        slot_size = GC::INTERNAL_CONSTANTS[:BASE_SLOT_SIZE] * (2**size_pool)

        "RUBY_GC_HEAP_INIT_SIZE_#{slot_size}_SLOTS"
      end
    end
  end
end
