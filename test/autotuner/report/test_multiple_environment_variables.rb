# frozen_string_literal: true

require "test_helper"

module Autotuner
  module Report
    class TestMultipleEnvironementVariables < Minitest::Test
      def test_to_s
        msg = "Testing message\n"
        env_name = ["TESTING_ONE", "TESTING_TWO"]
        suggested_value = [12, 34]
        report = MultipleEnvironmentVariables.new(msg, env_name, suggested_value, [nil, nil])

        assert_equal(<<~MSG, report.to_s)
          Testing message

          Suggested tuning values:
            TESTING_ONE=12
            TESTING_TWO=34

          #{Base::DISCLAIMER_MESSAGE.strip}
        MSG
      end

      def test_to_s_with_configured_value
        msg = "Testing message\n"
        env_name = ["TESTING_ONE", "TESTING_TWO"]
        suggested_value = [12, 34]
        report = MultipleEnvironmentVariables.new(msg, env_name, suggested_value, [nil, 10])

        assert_equal(<<~MSG, report.to_s)
          Testing message

          Suggested tuning values:
            TESTING_ONE=12
            TESTING_TWO=34 (configured value: 10)

          #{Base::DISCLAIMER_MESSAGE.strip}
        MSG
      end
    end
  end
end
