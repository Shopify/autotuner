# frozen_string_literal: true

module Autotuner
  class RequestContext
    attr_reader :before_gc_context
    attr_reader :after_gc_context
    attr_reader :request_time

    def initialize
      @before_gc_context = GCContext.new
      @after_gc_context = GCContext.new
      @request_time = 0.0

      @start_time_ms = 0.0
    end

    def before_request
      @before_gc_context.update
      @start_time_ms = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
    end

    def after_request
      @request_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond) - @start_time_ms
      @after_gc_context.update
    end
  end
end
