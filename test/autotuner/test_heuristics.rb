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

    def test_debug_messages
      messages = Autotuner.debug_messages

      assert_instance_of(Hash, messages)
      assert_equal(Heuristics::HEURISTICS.length, messages.length)
      messages.each do |name, msg|
        assert_instance_of(String, name)
        assert_instance_of(String, msg)
      end
    end

    def test_debug_messages_calls_debug_message
      mock_heuristic = Class.new(Heuristic::Base) do
        attr_reader :name, :debug_message

        def initialize(name, debug_message)
          super()
          @name = name
          @debug_message = debug_message
        end
      end

      heuristic1 = mock_heuristic.new("Heuristic1", "Debug message 1")
      heuristic2 = mock_heuristic.new("Heuristic2", "Debug message 2")

      Autotuner.stubs(:heuristics).returns([heuristic1, heuristic2])

      assert_equal(
        { "Heuristic1" => "Debug message 1", "Heuristic2" => "Debug message 2" },
        Autotuner.debug_messages,
      )
    end
  end
end
