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
      heuristic1 = mock
      heuristic2 = mock
      heuristic1.expects(:tuning_message).returns("Heuristic 1")
      heuristic2.expects(:tuning_message).returns("Heuristic 2")

      GCTuner.stubs(:heuristics).returns([heuristic1, heuristic2])

      assert_equal(["Heuristic 1", "Heuristic 2"], GCTuner.tuning_messages)
    end
  end
end
