# frozen_string_literal: true

require "test_helper"

module Autotuner
  module Report
    class TestSingleEnvironementVariable < Minitest::Test
      def test_heuristic_name
        msg = "Testing message\n"
        env_name = "TESTING_ENV"
        suggested_value = 123
        report = SingleEnvironmentVariable.new("test_heuristic", msg, env_name, suggested_value, nil)

        assert_equal("test_heuristic", report.heuristic_name)
      end

      def test_to_s
        msg = "Testing message\n"
        env_name = "TESTING_ENV"
        suggested_value = 123
        report = SingleEnvironmentVariable.new("test_heuristic", msg, env_name, suggested_value, nil)

        assert_equal(<<~MSG, report.to_s)
          Testing message

          Suggested tuning value:
            TESTING_ENV=123

          #{Base::DISCLAIMER_MESSAGE.strip}
        MSG
      end

      def test_to_s_with_configured_value
        msg = "Testing message\n"
        env_name = "TESTING_ENV"
        suggested_value = 123
        configured_value = 456
        report = SingleEnvironmentVariable.new("test_heuristic", msg, env_name, suggested_value, configured_value)

        assert_equal(<<~MSG, report.to_s)
          Testing message

          Suggested tuning value:
            TESTING_ENV=123 (configured value: 456)

          #{Base::DISCLAIMER_MESSAGE.strip}
        MSG
      end
    end
  end
end
