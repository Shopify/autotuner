# frozen_string_literal: true

require "test_helper"

module Autotuner
  class TestSystemContext < Minitest::Test
    def setup
      @system_context = SystemContext.new
    end

    def test_update
      @system_context.update(10.123, nil, nil)

      assert_equal(1, @system_context.request_time_data.length)
      assert_equal(10.123, @system_context.request_time_data.samples[0])
    end

    def test_debug_state
      debug_state = @system_context.debug_state

      assert_equal(@system_context.request_time_data.debug_state, debug_state[:request_time_data])
    end
  end
end
