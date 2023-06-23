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

    def test_request_calls_heuristics_with_request_time_and_gc_context
      mock_heuristic = Class.new(Heuristic::Base) do
        attr_reader :calls

        def initialize
          super

          @calls = []
          @call_klass = Data.define(:request_time, :before_gc_context, :after_gc_context)
        end

        def call(request_time, before_gc_context, after_gc_context)
          @calls << @call_klass.new(request_time, before_gc_context, after_gc_context)
        end
      end

      heuristics = [mock_heuristic.new, mock_heuristic.new]

      Autotuner.stubs(:heuristics).returns(heuristics)

      Process.stubs(:clock_gettime).with(Process::CLOCK_MONOTONIC, :float_millisecond)
        .returns(123.0).then.returns(153.0)
      @request_collector.request { GC.start }

      heuristics.each do |h|
        assert_equal(1, h.calls.length)
        assert_equal(30.0, h.calls[-1].request_time)
        assert_instance_of(GCContext, h.calls[-1].before_gc_context)
        assert_instance_of(GCContext, h.calls[-1].after_gc_context)

        # Ran at least 1 GC in the request
        assert_operator(h.calls[-1].before_gc_context.stat[:count], :<, h.calls[-1].after_gc_context.stat[:count])
      end

      Process.stubs(:clock_gettime).with(Process::CLOCK_MONOTONIC, :float_millisecond)
        .returns(400.0).then.returns(500.0)
      @request_collector.request { GC.start }

      heuristics.each do |h|
        assert_equal(2, h.calls.length)
        assert_equal(100.0, h.calls[-1].request_time)
        assert_instance_of(GCContext, h.calls[-1].before_gc_context)
        assert_instance_of(GCContext, h.calls[-1].after_gc_context)

        # Ran at least 1 GC in the request
        assert_operator(h.calls[-1].before_gc_context.stat[:count], :<, h.calls[-1].after_gc_context.stat[:count])
      end
    end

    def test_request_polls_heuristic_tuning_report
      mock_heuristic = Class.new(Heuristic::Base) do
        attr_writer :tuning_report
        attr_reader :tuning_report_calls

        def initialize
          super

          @tuning_report_calls = 0
        end

        def call(request_time, before_gc_context, after_gc_context); end

        def tuning_report
          @tuning_report_calls += 1

          @tuning_report
        end
      end

      original_reporter = Autotuner.reporter
      Autotuner.reporter = mock

      heuristics = [mock_heuristic.new, mock_heuristic.new]
      Autotuner.stubs(:heuristics).returns(heuristics)

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
    ensure
      Autotuner.reporter = original_reporter
    end

    def test_request_polls_debug_messages
      mock_heuristic = Class.new(Heuristic::Base) do
        attr_reader :name, :debug_message

        def initialize(name, debug_message)
          super()

          @name = name
          @debug_message = debug_message
        end

        def call(request_time, before_gc_context, after_gc_context); end

        def tuning_report
          nil
        end
      end

      orig_debug_reporter = Autotuner.debug_reporter
      Autotuner.debug_reporter = mock

      heuristics = [mock_heuristic.new("Heuristic1", "Debug1"), mock_heuristic.new("Heuristic2", "Debug2")]
      Autotuner.stubs(:heuristics).returns(heuristics)

      (RequestCollector::DEBUG_EMIT_FREQUENCY - 1).times do
        @request_collector.request {}
      end

      Autotuner.debug_reporter.expects(:call).with({ "Heuristic1" => "Debug1", "Heuristic2" => "Debug2" }).once
      @request_collector.request {}
    ensure
      Autotuner.debug_reporter = orig_debug_reporter
    end
  end
end
