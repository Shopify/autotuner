# frozen_string_literal: true

require "test_helper"

module Autotuner
  class TestConfiguration < Minitest::Test
    def test_enabled
      original_enabled = Autotuner.enabled?

      Autotuner.enabled = false

      refute_predicate(Autotuner, :enabled?)

      Autotuner.enabled = true

      assert_predicate(Autotuner, :enabled?)
    ensure
      Autotuner.enabled = original_enabled
    end

    def test_sample_ratio
      original_sample_ratio = Autotuner.sample_ratio
      original_enabled = Autotuner.enabled?

      Autotuner.stubs(:rand).returns(0.4)
      Autotuner.sample_ratio = 0.5

      assert_predicate(Autotuner, :enabled?)

      Autotuner.stubs(:rand).returns(0.6)
      Autotuner.sample_ratio = 0.5

      refute_predicate(Autotuner, :enabled?)
    ensure
      Autotuner.instance_variable_set(:@sample_ratio, original_sample_ratio)
      Autotuner.enabled = original_enabled
    end

    def test_invalid_sample_ratio
      assert_raises(ArgumentError) { Autotuner.sample_ratio = -1 }
      assert_raises(ArgumentError) { Autotuner.sample_ratio = 10 }
    end
  end
end
