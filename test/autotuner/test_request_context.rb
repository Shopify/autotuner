# frozen_string_literal: true

require "test_helper"

module Autotuner
  class TestRequestContext < Minitest::Test
    def setup
      @request_context = RequestContext.new
    end

    def test_before_request
      before_major_count = @request_context.before_gc_context.stat[:major_gc_count]
      after_major_count = @request_context.after_gc_context.stat[:major_gc_count]

      GC.start
      @request_context.before_request

      assert_operator(@request_context.before_gc_context.stat[:major_gc_count], :>, before_major_count)
      assert_equal(after_major_count, @request_context.after_gc_context.stat[:major_gc_count])
    end

    def test_after_request
      before_major_count = @request_context.before_gc_context.stat[:major_gc_count]
      after_major_count = @request_context.after_gc_context.stat[:major_gc_count]

      GC.start
      @request_context.after_request

      assert_equal(before_major_count, @request_context.before_gc_context.stat[:major_gc_count])
      assert_operator(@request_context.after_gc_context.stat[:major_gc_count], :>, after_major_count)
    end

    def test_request_time
      Process.stubs(:clock_gettime).with(Process::CLOCK_MONOTONIC, :float_millisecond)
        .returns(400.0).then.returns(500.0)

      @request_context.before_request
      @request_context.after_request

      assert_equal(100.0, @request_context.request_time)
    end
  end
end
