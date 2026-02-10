# frozen_string_literal: true

module Autotuner
  class WorkCollector
    HEURISTICS_POLLING_FREQUENCY = 100
    DEBUG_EMIT_FREQUENCY = 1000

    def initialize(work_type:)
      @work_type = work_type
      @work_count = 0

      @work_context = WorkContext.new

      @system_context = SystemContext.new

      @heuristics = Autotuner.supported_heuristics.map { |h| h.new(@system_context) }
    end

    def measure
      before_work

      yield
    ensure
      after_work
    end

    private

    def enabled_heuristics
      Enumerator.new do |y|
        @heuristics.each do |heuristic|
          next unless heuristic.class.enabled?

          y << heuristic
        end
      end
    end

    def before_work
      @work_context.before_work

      @work_count += 1
    end

    def after_work
      @work_context.after_work

      @system_context.update(@work_context)

      enabled_heuristics.each do |heuristic|
        heuristic.call(@work_context)
      end

      emit_heuristic_reports if @work_count % HEURISTICS_POLLING_FREQUENCY == 0
      emit_debugging_states if @work_count % DEBUG_EMIT_FREQUENCY == 0
      emit_metrics
    end

    def emit_heuristic_reports
      enabled_heuristics.each do |heuristic|
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

      enabled_heuristics.each do |h|
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
        "work_duration" => @work_context.work_duration,

        # Metrics
        "heap_pages" => @work_context.after_gc_context.stat[:heap_eden_pages],

        # Tags
        "work_type" => @work_type,
      }

      Autotuner.metrics_reporter.call(metrics)
    end

    def gc_stat_diff(stat)
      @work_context.after_gc_context.stat[stat] - @work_context.before_gc_context.stat[stat]
    end
  end
end
