# frozen_string_literal: true

require "test_helper"

module Autotuner
  class TestReport < Minitest::Test
    def test_to_s_with_one_value
      msg = "Testing message\n"
      env_name = "TESTING_ENV"
      suggested_value = 123
      report = Report.new(msg, env_name, suggested_value, nil)

      assert_equal(<<~MSG, report.to_s)
        Testing message

        Suggested tuning value:
          TESTING_ENV=123
      MSG
    end

    def test_to_s_with_one_value_and_configured_value
      msg = "Testing message\n"
      env_name = "TESTING_ENV"
      suggested_value = 123
      configured_value = 456
      report = Report.new(msg, env_name, suggested_value, configured_value)

      assert_equal(<<~MSG, report.to_s)
        Testing message

        Suggested tuning value:
          TESTING_ENV=123 (configured value: 456)
      MSG
    end

    def test_to_s_with_array_value
      msg = "Testing message\n"
      env_name = ["TESTING_ONE", "TESTING_TWO"]
      suggested_value = [12, 34]
      report = Report.new(msg, env_name, suggested_value, [nil, nil])

      assert_equal(<<~MSG, report.to_s)
        Testing message

        Suggested tuning values:
          TESTING_ONE=12
          TESTING_TWO=34
      MSG
    end

    def test_to_s_with_array_value_and_configured_value
      msg = "Testing message\n"
      env_name = ["TESTING_ONE", "TESTING_TWO"]
      suggested_value = [12, 34]
      report = Report.new(msg, env_name, suggested_value, [nil, 10])

      assert_equal(<<~MSG, report.to_s)
        Testing message

        Suggested tuning values:
          TESTING_ONE=12
          TESTING_TWO=34 (configured value: 10)
      MSG
    end
  end
end
