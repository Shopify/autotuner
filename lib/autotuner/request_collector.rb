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
      emit_metrics
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

    def emit_metrics
      return unless Autotuner.metrics_reporter

      metrics = {
        # Diff metrics
        "diff.time" => gc_stat_diff(:time),
        "diff.minor_gc_count" => gc_stat_diff(:minor_gc_count),
        "diff.major_gc_count" => gc_stat_diff(:major_gc_count),
        "request_time" => @request_context.request_time,

        # Metrics
        "heap_pages" => @request_context.after_gc_context.stat[:heap_eden_pages],
      }

      Autotuner.metrics_reporter.call(metrics)
    end

    def gc_stat_diff(stat)
      @request_context.after_gc_context.stat[stat] - @request_context.before_gc_context.stat[stat]
    end
  end
end
