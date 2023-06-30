# frozen_string_literal: true

module Autotuner
  class RequestCollector
    HEURISTICS_POLLING_FREQUENCY = 100
    DEBUG_EMIT_FREQUENCY = 1000

    def initialize
      @request_count = 0

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

      @request_count += 1
    end

    def after_request
      request_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond) - @start_time_ms
      @after_gc_context.update

      Autotuner.heuristics.each do |heuristic|
        heuristic.call(request_time, @before_gc_context, @after_gc_context)
      end

      emit_heuristic_reports if @request_count % HEURISTICS_POLLING_FREQUENCY == 0
      emit_debugging_states if @request_count % DEBUG_EMIT_FREQUENCY == 0
    end

    def emit_heuristic_reports
      Autotuner.heuristics.each do |heuristic|
        report = heuristic.tuning_report

        next unless report

        if Autotuner.reporter
          Autotuner.reporter.call(report)
        else
          warn("Autotuner has been enabled but Autotuner.reporter has not been configured")
        end
      end
    end

    def emit_debugging_states
      return unless Autotuner.debug_reporter

      debug_states = {}
      Autotuner.heuristics.each do |h|
        debug_states[h.name] = h.debug_state
      end

      Autotuner.debug_reporter.call(debug_states)
    end
  end
end
