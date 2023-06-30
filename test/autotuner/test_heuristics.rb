# frozen_string_literal: true

require "test_helper"

module Autotuner
  class TestHeuristics < Minitest::Test
    def test_heuristics
      Autotuner.heuristics.each do |heuristic|
        assert_predicate(heuristic.class, :enabled?)
      end
    end

    def test_name
      names = []
      Autotuner.heuristics.each do |heuristic|
        name = heuristic.name

        assert_instance_of(String, name)
        # Names should be unique
        refute_includes(names, name)

        names << name
      end
    end

    def test_debug_state
      messages = Autotuner.heuristics.map(&:debug_state)

      messages.each do |msg|
        assert_instance_of(Hash, msg)
      end
    end
  end
end
