# frozen_string_literal: true

require "test_helper"

module Autotuner
  class TestHeuristics < Minitest::Test
    def setup
      @heuristics = Autotuner.supported_heuristics.map { |h| h.new(nil) }
    end

    def test_heuristics
      assert_operator(Autotuner.supported_heuristics.length, :>, 0)

      Autotuner.supported_heuristics.each do |heuristic|
        assert_predicate(heuristic, :supported?)
      end
    end

    def test_name
      names = []
      @heuristics.each do |heuristic|
        name = heuristic.name

        assert_instance_of(String, name)
        # Names should be unique
        refute_includes(names, name)

        names << name
      end
    end

    def test_debug_state
      messages = @heuristics.map(&:debug_state)

      messages.each do |msg|
        assert_instance_of(Hash, msg)
      end
    end
  end
end
