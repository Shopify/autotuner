# frozen_string_literal: true

require "test_helper"

class TestGCTuner < Minitest::Test
  def test_enabled
    original_enabled = GCTuner.enabled?

    GCTuner.enabled = false

    refute_predicate(GCTuner, :enabled?)

    GCTuner.enabled = true

    assert_predicate(GCTuner, :enabled?)
  ensure
    GCTuner.enabled = original_enabled
  end

  def test_sample_ratio
    original_sample_ratio = GCTuner.sample_ratio
    original_enabled = GCTuner.enabled?

    GCTuner.stubs(:rand).returns(0.4)
    GCTuner.sample_ratio = 0.5

    assert_predicate(GCTuner, :enabled?)

    GCTuner.stubs(:rand).returns(0.6)
    GCTuner.sample_ratio = 0.5

    refute_predicate(GCTuner, :enabled?)
  ensure
    GCTuner.instance_variable_set(:@sample_ratio, original_sample_ratio)
    GCTuner.enabled = original_enabled
  end

  def test_invalid_sample_ratio
    assert_raises(ArgumentError) { GCTuner.sample_ratio = -1 }
    assert_raises(ArgumentError) { GCTuner.sample_ratio = 10 }
  end
end
