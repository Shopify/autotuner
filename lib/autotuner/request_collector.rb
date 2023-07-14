# frozen_string_literal: true

module Autotuner
  class RequestCollector
    HEURISTICS_POLLING_FREQUENCY = 100
    DEBUG_EMIT_FREQUENCY = 1000

    attr_reader :heuristics

    def initialize
      @request_count = 0

      @request_context = RequestContext.new

      @system_context = SystemContext.new

      @heuristics = Autotuner.enabled_heuristics.map { |h| h.new(@system_context) }
    end

    def request
      before_request

      yield
    ensure
      after_request
    end

    private

    def before_request
      @request_context.before_request

      @request_count += 1
    end

    def after_request
      @request_context.after_request

      @system_context.update(@request_context)

      heuristics.each do |heuristic|
        heuristic.call(@request_context)
      end

      emit_heuristic_reports if @request_count % HEURISTICS_POLLING_FREQUENCY == 0
      emit_debugging_states if @request_count % DEBUG_EMIT_FREQUENCY == 0
    end

    def emit_heuristic_reports
      heuristics.each do |heuristic|
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

      debug_states = {
        system_context: @system_context.debug_state,
      }

      heuristics.each do |h|
        debug_states[h.name] = h.debug_state
      end

      Autotuner.debug_reporter.call(debug_states)
    end
  end
end
