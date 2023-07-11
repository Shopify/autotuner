# frozen_string_literal: true

module Autotuner
  class SystemContext
    attr_reader :request_time_data

    def initialize
      @request_time_data = DataStructure::DataPoints.new(Configuration::DATA_POINTS_COUNT)
    end

    def update(request_time, _before_gc_context, _after_gc_context)
      @request_time_data.insert(request_time)
    end

    def debug_state
      {
        request_time_data: @request_time_data.debug_state,
      }
    end
  end
end
