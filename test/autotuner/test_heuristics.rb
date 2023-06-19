# frozen_string_literal: true

require "test_helper"

module Autotuner
  class TestHeuristics < Minitest::Test
    def test_heuristics
      Autotuner.heuristics.each do |heuristic|
        assert_predicate(heuristic.class, :enabled?)
      end
    end

    def test_debug_messages
      messages = Autotuner.debug_messages

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

      Autotuner.stubs(:heuristics).returns([heuristic1, heuristic2])

      assert_equal(["Heuristic 1", "Heuristic 2"], Autotuner.debug_messages)
    end
  end
end
