# frozen_string_literal: true

module Autotuner
  class RequestCollector
    HEURISTICS_POLLING_FREQUENCY = 100

    def initialize
      @requests_since_last_heuristic_poll = 0

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

      @requests_since_last_heuristic_poll += 1
    end

    def after_request
      request_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond) - @start_time_ms
      @after_gc_context.update

      Autotuner.heuristics.each do |heuristic|
        heuristic.call(request_time, @before_gc_context, @after_gc_context)
      end

      if @requests_since_last_heuristic_poll >= HEURISTICS_POLLING_FREQUENCY
        @requests_since_last_heuristic_poll = 0

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
    end
  end
end
