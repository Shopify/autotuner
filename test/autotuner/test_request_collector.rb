# frozen_string_literal: true

require "test_helper"

module Autotuner
  class TestRequestCollector < Minitest::Test
    class MockHeuristic < Heuristic::Base
      Call = Data.define(:request_time, :before_gc_context, :after_gc_context)

      attr_reader :calls
      attr_reader :tuning_report_calls
      attr_writer :tuning_report

      def initialize
        super

        @calls = []
        @tuning_report_calls = 0
      end

      def call(request_time, before_gc_context, after_gc_context)
        @calls << Call.new(request_time, before_gc_context, after_gc_context)
      end

      def tuning_report
        @tuning_report_calls += 1

        @tuning_report
      end
    end

    def setup
      @request_collector = RequestCollector.new
    end

    def test_request_calls_heuristics_with_request_time_and_gc_context
      heuristics = [MockHeuristic.new, MockHeuristic.new]

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
      original_reporter = Autotuner.reporter
      Autotuner.reporter = mock

      heuristics = [MockHeuristic.new, MockHeuristic.new]

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
  end
end
