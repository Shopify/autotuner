# frozen_string_literal: true

require "test_helper"

module Autotuner
  class TestSystemContext < Minitest::Test
    def setup
      @system_context = SystemContext.new
      @work_context = WorkContext.new
    end

    def test_update
      @work_context.stubs(:work_duration).returns(10.123)

      @system_context.update(@work_context)

      assert_equal(1, @system_context.work_duration_data.length)
      assert_equal(10.123, @system_context.work_duration_data.samples[0])
    end

    def test_debug_state
      debug_state = @system_context.debug_state

      assert_equal(@system_context.work_duration_data.debug_state, debug_state[:work_duration_data])
    end
  end
end
