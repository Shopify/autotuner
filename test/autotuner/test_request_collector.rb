# frozen_string_literal: true

require "test_helper"

module Autotuner
  class TestRequestCollector < Minitest::Test
    def setup
      @request_collector = RequestCollector.new
      @original_reporter = Autotuner.reporter
      Autotuner.reporter = proc { |_| }
    end

    def teardown
      Autotuner.reporter = @original_reporter
    end

    def test_request_updates_request_context
      RequestContext.any_instance.expects(:before_request).once

      @request_collector.request { RequestContext.any_instance.expects(:after_request).once }
    end

    def test_request_calls_heuristics_with_request_context
      mock_heuristic = Class.new(Heuristic::Base) do
        attr_reader :calls

        def initialize
          super(nil)

          @calls = []
        end

        def call(request_context)
          @calls << request_context
        end
      end

      heuristics = [mock_heuristic.new, mock_heuristic.new]
      @request_collector.instance_variable_set(:@heuristics, heuristics)

      @request_collector.request {}

      heuristics.each do |h|
        assert_equal(1, h.calls.length)
        assert_instance_of(RequestContext, h.calls[0])
      end
    end

    def test_request_polls_heuristic_tuning_report
      mock_heuristic = Class.new(Heuristic::Base) do
        attr_writer :tuning_report
        attr_reader :tuning_report_calls

        def initialize
          super(nil)

          @tuning_report_calls = 0
        end

        def call(request_context); end

        def tuning_report
          @tuning_report_calls += 1

          @tuning_report
        end
      end

      Autotuner.reporter = mock

      heuristics = [mock_heuristic.new, mock_heuristic.new]
      @request_collector.instance_variable_set(:@heuristics, heuristics)

      (RequestCollector::HEURISTICS_POLLING_FREQUENCY - 1).times do
        @request_collector.request {}

        heuristics.each { |h| assert_equal(0, h.tuning_report_calls) }
      end

      report1 = mock
      heuristics[1].tuning_report = report1
      Autotuner.reporter.expects(:call).with(report1).once

      @request_collector.request {}

      heuristics.each { |h| assert_equal(1, h.tuning_report_calls) }

      (RequestCollector::HEURISTICS_POLLING_FREQUENCY - 1).times do
        @request_collector.request {}

        heuristics.each { |h| assert_equal(1, h.tuning_report_calls) }
      end

      report1 = mock
      report2 = mock
      heuristics[0].tuning_report = report1
      heuristics[1].tuning_report = report2
      Autotuner.reporter.expects(:call).with(report1).once
      Autotuner.reporter.expects(:call).with(report2).once

      @request_collector.request {}

      heuristics.each { |h| assert_equal(2, h.tuning_report_calls) }
    end

    def test_request_does_not_call_disabled_heuristics
      disabled_heuristic, mock_heuristic = 2.times.map do
        Class.new(Heuristic::Base) do
          attr_reader :calls

          def initialize
            super(nil)

            @calls = []
          end

          def call(request_context)
            @calls << request_context
          end
        end
      end
      disabled_heuristic.disable!

      heuristics = [disabled_heuristic.new, mock_heuristic.new]
      @request_collector.instance_variable_set(:@heuristics, heuristics)

      @request_collector.request {}

      assert_empty(heuristics[0].calls)

      assert_equal(1, heuristics[1].calls.length)
      assert_instance_of(RequestContext, heuristics[1].calls[0])
    end

    def test_request_polls_debug_states
      mock_heuristic = Class.new(Heuristic::Base) do
        attr_reader :name, :debug_state

        def initialize(name, debug_state)
          super(nil)

          @name = name
          @debug_state = debug_state
        end

        def call(request_context); end

        def tuning_report
          nil
        end
      end

      orig_debug_reporter = Autotuner.debug_reporter
      Autotuner.debug_reporter = mock

      heuristics = [mock_heuristic.new("Heuristic1", { foo: "bar" }), mock_heuristic.new("Heuristic2", { bar: "baz" })]
      @request_collector.instance_variable_set(:@heuristics, heuristics)

      (RequestCollector::DEBUG_EMIT_FREQUENCY - 1).times do
        @request_collector.request {}
      end

      Autotuner.debug_reporter
        .expects(:call)
        .with do |value|
          value[:system_context].is_a?(Hash) &&
            value["Heuristic1"] == heuristics[0].debug_state &&
            value["Heuristic2"] == heuristics[1].debug_state
        end
        .once
      @request_collector.request {}
    ensure
      Autotuner.debug_reporter = orig_debug_reporter
    end

    def test_request_does_not_poll_debug_states_for_disabled_heuristics
      disabled_heuristic, mock_heuristic = 2.times.map do
        Class.new(Heuristic::Base) do
          attr_reader :name, :debug_state

          def initialize(name, debug_state)
            super(nil)

            @name = name
            @debug_state = debug_state
          end

          def call(request_context); end

          def tuning_report
            nil
          end
        end
      end
      disabled_heuristic.disable!

      orig_debug_reporter = Autotuner.debug_reporter
      Autotuner.debug_reporter = mock

      heuristics = [
        disabled_heuristic.new("DisabledHeuristic", { foo: "bar" }),
        mock_heuristic.new("Heuristic", { bar: "baz" }),
      ]
      @request_collector.instance_variable_set(:@heuristics, heuristics)

      (RequestCollector::DEBUG_EMIT_FREQUENCY - 1).times do
        @request_collector.request {}
      end

      Autotuner.debug_reporter
        .expects(:call)
        .with do |value|
          value[:system_context].is_a?(Hash) &&
            !value.key?("DisabledHeuristic") &&
            value["Heuristic"] == heuristics[1].debug_state
        end
        .once
      @request_collector.request {}
    ensure
      Autotuner.debug_reporter = orig_debug_reporter
    end

    def test_request_calls_metrics_reporter
      orig_metrics_reporter = Autotuner.metrics_reporter

      metrics = nil
      Autotuner.metrics_reporter = proc do |m|
        metrics = m
      end

      @request_collector.request {}

      refute_nil(metrics)
      ["diff.time", "diff.minor_gc_count", "diff.major_gc_count", "request_time", "request_time"].each do |key|
        assert_operator(metrics[key], :>=, 0)
      end

      # Run a major GC
      @request_collector.request { GC.start }

      assert_operator(metrics["diff.major_gc_count"], :>=, 1)

      # Run a minor GC
      @request_collector.request { GC.start(full_mark: false) }

      assert_operator(metrics["diff.minor_gc_count"], :>=, 1)
    ensure
      Autotuner.metrics_reporter = orig_metrics_reporter
    end
  end
end
