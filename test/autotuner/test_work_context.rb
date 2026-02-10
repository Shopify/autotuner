# frozen_string_literal: true

require "test_helper"

module Autotuner
  class TestWorkContext < Minitest::Test
    def setup
      @work_context = WorkContext.new
    end

    def test_before_work
      before_major_count = @work_context.before_gc_context.stat[:major_gc_count]
      after_major_count = @work_context.after_gc_context.stat[:major_gc_count]

      GC.start
      @work_context.before_work

      assert_operator(@work_context.before_gc_context.stat[:major_gc_count], :>, before_major_count)
      assert_equal(after_major_count, @work_context.after_gc_context.stat[:major_gc_count])
    end

    def test_after_work
      before_major_count = @work_context.before_gc_context.stat[:major_gc_count]
      after_major_count = @work_context.after_gc_context.stat[:major_gc_count]

      GC.start
      @work_context.after_work

      assert_equal(before_major_count, @work_context.before_gc_context.stat[:major_gc_count])
      assert_operator(@work_context.after_gc_context.stat[:major_gc_count], :>, after_major_count)
    end

    def test_work_duration
      Process.stubs(:clock_gettime).with(Process::CLOCK_MONOTONIC, :float_millisecond)
        .returns(400.0).then.returns(500.0)

      @work_context.before_work
      @work_context.after_work

      assert_equal(100.0, @work_context.work_duration)
    end
  end
end
