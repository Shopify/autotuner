# frozen_string_literal: true

require "test_helper"

module GCTuner
  class TestHeuristics < Minitest::Test
    def test_heuristics
      GCTuner.heuristics.each do |heuristic|
        assert_predicate(heuristic.class, :enabled?)
      end
    end

    def test_tuning_messages
      messages = GCTuner.tuning_messages

      assert_equal(Heuristics::HEURISTICS.length, messages.length)
      assert_instance_of(Array, messages)
      messages.each do |msg|
        assert_instance_of(String, msg)
      end
    end

    def test_tuning_messages_calls_tuning_message
      heuristic1 = mock
      heuristic2 = mock
      heuristic1.expects(:tuning_message).returns("Heuristic 1")
      heuristic2.expects(:tuning_message).returns("Heuristic 2")

      GCTuner.stubs(:heuristics).returns([heuristic1, heuristic2])

      assert_equal(["Heuristic 1", "Heuristic 2"], GCTuner.tuning_messages)
    end

    def test_debug_messages
      messages = GCTuner.debug_messages

      assert_instance_of(Array, messages)
      assert_equal(Heuristics::HEURISTICS.length, messages.length)
      messages.each do |msg|
        assert_instance_of(String, msg)
      end
    end

    def test_debug_messages_calls_debug_message
      heuristic1 = mock
      heuristic2 = mock
      heuristic1.expects(:debug_message).returns("Heuristic 1")
      heuristic2.expects(:debug_message).returns("Heuristic 2")

      GCTuner.stubs(:heuristics).returns([heuristic1, heuristic2])

      assert_equal(["Heuristic 1", "Heuristic 2"], GCTuner.debug_messages)
    end
  end
end
