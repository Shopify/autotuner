# frozen_string_literal: true

require "test_helper"

module GCTuner
  class TestHeuristic < Minitest::Test
    def test_enabled_heuristics
      Heuristic.enabled_heuristics.each do |heuristic|
        assert_predicate(heuristic, :enabled?)
      end
    end
  end
end
