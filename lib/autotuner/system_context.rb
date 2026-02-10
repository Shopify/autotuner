# frozen_string_literal: true

module Autotuner
  class SystemContext
    attr_reader :work_duration_data

    def initialize
      @work_duration_data = DataStructure::DataPoints.new(Configuration::DATA_POINTS_COUNT)
    end

    def update(work_context)
      @work_duration_data.insert(work_context.work_duration)
    end

    def debug_state
      {
        work_duration_data: @work_duration_data.debug_state,
      }
    end
  end
end
