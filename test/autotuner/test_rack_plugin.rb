# frozen_string_literal: true

require "test_helper"

module Autotuner
  class TestRackPlugin < Minitest::Test
    def setup
      @app = mock
      @rack_plugin = RackPlugin.new(@app)
    end

    def test_call_when_enabled
      env = mock

      @app.expects(:call).with(env).once

      @rack_plugin.call(env)
    end

    def test_call_when_disabled
      was_enabled = Autotuner.enabled?
      Autotuner.enabled = false

      env = mock

      @app.expects(:call).with(env).once

      @rack_plugin.call(env)
    ensure
      Autotuner.enabled = was_enabled
    end
  end
end
