# frozen_string_literal: true

require "test_helper"

module Autotuner
  class TestActiveJobPlugin < Minitest::Test
    def setup
      # Reset the memoized work_collector between tests
      ActiveJobPlugin.instance_variable_set(:@work_collector, nil)
    end

    def test_work_collector_returns_work_collector_instance
      assert_instance_of(WorkCollector, ActiveJobPlugin.work_collector)
    end

    def test_work_collector_is_memoized
      assert_same(ActiveJobPlugin.work_collector, ActiveJobPlugin.work_collector)
    end
  end
end

begin
  require "active_job"

  module Autotuner
    class TestActiveJobPluginIntegration < Minitest::Test
      class TestJob < ActiveJob::Base
        include Autotuner::ActiveJobPlugin

        self.queue_adapter = :inline

        attr_reader :performed

        def perform
          @performed = true
        end
      end

      class TestErrorJob < ActiveJob::Base
        include Autotuner::ActiveJobPlugin

        self.queue_adapter = :inline

        def perform
          raise "job error"
        end
      end

      def setup
        @was_enabled = Autotuner.enabled?
        Autotuner.enabled = true
        ActiveJobPlugin.instance_variable_set(:@work_collector, nil)
      end

      def teardown
        Autotuner.instance_variable_set(:@enabled, @was_enabled)
      end

      def test_perform_calls_block_when_enabled
        TestJob.perform_now
      end

      def test_perform_calls_block_when_disabled
        Autotuner.instance_variable_set(:@enabled, false)

        TestJob.perform_now
      end

      def test_perform_uses_work_collector_when_enabled
        work_collector = mock
        work_collector.expects(:measure).once.yields
        ActiveJobPlugin.instance_variable_set(:@work_collector, work_collector)

        TestJob.perform_now
      end

      def test_perform_does_not_use_work_collector_when_disabled
        Autotuner.instance_variable_set(:@enabled, false)

        work_collector = mock
        work_collector.expects(:measure).never
        ActiveJobPlugin.instance_variable_set(:@work_collector, work_collector)

        TestJob.perform_now
      end

      def test_perform_captures_data_on_exception
        work_collector = mock
        work_collector.expects(:measure).once.yields
        ActiveJobPlugin.instance_variable_set(:@work_collector, work_collector)

        assert_raises(RuntimeError) do
          TestErrorJob.perform_now
        end
      end
    end
  end
rescue LoadError
  # ActiveJob not available; skip integration tests
end
