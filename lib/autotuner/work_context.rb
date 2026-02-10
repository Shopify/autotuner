# frozen_string_literal: true

module Autotuner
  class WorkContext
    attr_reader :before_gc_context
    attr_reader :after_gc_context
    attr_reader :work_duration

    def initialize
      @before_gc_context = GCContext.new
      @after_gc_context = GCContext.new
      @work_duration = 0.0

      @start_time_ms = 0.0
    end

    def before_work
      @before_gc_context.update
      @start_time_ms = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
    end

    def after_work
      @work_duration = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond) - @start_time_ms
      @after_gc_context.update
    end
  end
end
