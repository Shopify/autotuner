# frozen_string_literal: true

module Autotuner
  module Heuristic
    class SizePoolWarmup < Base
      DATA_POINTS_COUNT = 1_000
      SIZE_POOL_CONFIGURATION_DELTA_RATIO = 0.01
      SIZE_POOL_CONFIGURATION_DELTA = 1

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

        @size_pool_count = GC::INTERNAL_CONSTANTS[:SIZE_POOL_COUNT]
        @size_pools_data = Array.new(@size_pool_count)
        @size_pools_tuning_configuration = Array.new(@size_pool_count)
        @size_pool_count.times do |i|
          @size_pools_data[i] = DataStructure::DataPoints.new(DATA_POINTS_COUNT)
          @size_pools_tuning_configuration[i] = ENV[env_name_for_size_pool(i)].to_i
        end

        @plateaued = false
      end

      def call(request_time, _before_gc_context, after_gc_context)
        # We only want to collect data at boot until the request time plateaus
        return if @plateaued

        insert_data(request_time, after_gc_context)

        return unless @request_time_data.plateaued?

        @plateaued = true
      end

      def tuning_message
        msg = nil

        if @plateaued
          size_pool_messages = @size_pool_count.times.map do |i|
            tuning_message_for_size_pool(i)
          end.compact

          unless size_pool_messages.empty?
            msg = <<~MSG
              Here are the recommended tuning values for size pools and the confidence scores.
              Confidence scores are between 0 and 1.0 and represent the correlation between
              the tuning value and the response time.

            MSG

            msg += size_pool_messages.join
          end
        else
          msg = <<~MSG.chomp
            There is not enough data and/or response times have not plateaued.
          MSG
        end

        msg
      end

      def debug_message
        msg = <<~MSG
          plateaued: #{@plateaued}
          request_time_data: #{@request_time_data}
        MSG

        @size_pools_data.each_with_index do |data, i|
          msg += "size_pools_data[#{i}]: #{data}\n"
        end

        if @plateaued
          msg += @size_pool_count.times.map do |i|
            tuning_message_for_size_pool(i, debug: true)
          end.join
        end

        msg
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

      def tuning_message_for_size_pool(size_pool, debug: false)
        configured_value = @size_pools_tuning_configuration[size_pool]

        data = @size_pools_data[size_pool]
        suggested_value = data.samples[data.length - 1].to_i

        diff = (configured_value - suggested_value).abs
        if debug ||
            (diff > configured_value * SIZE_POOL_CONFIGURATION_DELTA_RATIO && diff > SIZE_POOL_CONFIGURATION_DELTA)
          confidence = @request_time_data.correlation(data).abs

          msg = ""
          msg += "#{env_name_for_size_pool(size_pool)}=#{suggested_value} (confidence: #{format("%.2f", confidence)}"
          msg += ", tuned value: #{configured_value}" if configured_value > 0
          msg += ")\n"

          msg
        end
      end
    end
  end
end
