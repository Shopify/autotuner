# frozen_string_literal: true

module Autotuner
  module ActiveJobPlugin
    def self.included(base)
      base.around_perform do |_job, block|
        if Autotuner.enabled?
          Autotuner::ActiveJobPlugin.work_collector.measure { block.call }
        else
          block.call
        end
      end
    end

    def self.work_collector
      @work_collector ||= WorkCollector.new(work_type: "job")
    end
  end
end
