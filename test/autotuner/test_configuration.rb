# frozen_string_literal: true

require "test_helper"

module Autotuner
  class TestConfiguration < Minitest::Test
    def setup
      @original_sample_ratio = Autotuner.sample_ratio
      @original_enabled = Autotuner.enabled?
    end

    def teardown
      Autotuner.instance_variable_set(:@sample_ratio, @original_sample_ratio)
      Autotuner.instance_variable_set(:@enabled, @original_enabled)
    end

    def test_enabled
      Autotuner.enabled = false

      refute_predicate(Autotuner, :enabled?)

      Autotuner.enabled = true

      assert_predicate(Autotuner, :enabled?)
    end

    def test_enabled_when_sample_ratio_configured
      Autotuner.sample_ratio = 0.0
      assert_raises(ArgumentError) { Autotuner.enabled = true }
      assert_raises(ArgumentError) { Autotuner.enabled = false }
    end

    def test_sample_ratio_enables
      Autotuner.stubs(:rand).returns(0.4)
      Autotuner.sample_ratio = 0.5

      assert_predicate(Autotuner, :enabled?)
    end

    def test_sample_ratio_disables
      Autotuner.stubs(:rand).returns(0.6)
      Autotuner.sample_ratio = 0.5

      refute_predicate(Autotuner, :enabled?)
    end

    def test_sample_ration_of_0
      Autotuner.stubs(:rand).returns(0.0)
      Autotuner.sample_ratio = 0.0

      refute_predicate(Autotuner, :enabled?)
    end

    def test_sample_ratio_of_1
      Autotuner.stubs(:rand).returns(0.0)
      Autotuner.sample_ratio = 1.0

      assert_predicate(Autotuner, :enabled?)
    end

    def test_sample_ratio_when_enabled_configured
      Autotuner.enabled = true
      assert_raises(ArgumentError) { Autotuner.sample_ratio = 0.5 }

      Autotuner.enabled = false
      assert_raises(ArgumentError) { Autotuner.sample_ratio = 0.5 }
    end

    def test_invalid_sample_ratio
      assert_raises(ArgumentError) { Autotuner.sample_ratio = -1 }
      assert_raises(ArgumentError) { Autotuner.sample_ratio = 10 }
    end
  end
end
