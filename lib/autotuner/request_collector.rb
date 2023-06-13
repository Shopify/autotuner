# frozen_string_literal: true

module Autotuner
  class RequestCollector
    def initialize
      @before_gc_context = GCContext.new
      @after_gc_context = GCContext.new

      @start_time_ms = 0.0
    end

    def request
      before_request

      yield
    ensure
      after_request
    end

    private

    def before_request
      @before_gc_context.update
      @start_time_ms = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
    end

    def after_request
      request_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond) - @start_time_ms
      @after_gc_context.update

      Autotuner.heuristics.each do |heuristic|
        heuristic.call(request_time, @before_gc_context, @after_gc_context)
      end
    end
  end
end
