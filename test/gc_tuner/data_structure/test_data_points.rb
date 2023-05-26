# frozen_string_literal: true

require "test_helper"

module GCTuner
  module DataStructure
    class TestDataPoints < Minitest::Test
      def test_insert
        data_points = DataPoints.new(10)

        10.times { |i| data_points.insert(i) }

        assert_equal(10, data_points.length)
        assert_equal((0...10).to_a, data_points.samples)

        # Compression occurs
        data_points.insert(100)

        assert_equal(5, data_points.length)
        assert_equal([0.5, 2.5, 4.5, 6.5, 8.5], data_points.samples[0...5])

        # Insert compressed sample
        data_points.insert(200)

        assert_equal(6, data_points.length)
        assert_equal([0.5, 2.5, 4.5, 6.5, 8.5, 150], data_points.samples[0...6])
      end

      def test_plateaued?
        data_points = DataPoints.new(10)

        refute_predicate(data_points, :plateaued?)

        data_points.insert(0)

        refute_predicate(data_points, :plateaued?)

        data_points.insert(0)

        refute_predicate(data_points, :plateaued?)

        [1.0, 2.0, 3.0, 4.0, 5.1, 4.9, 5.1, 5.3, 4.8, 5.1].each { |i| data_points.insert(i) }

        assert(data_points.plateaued?(0.1))
        refute(data_points.plateaued?(0.01))
      end

      def test_correlation
        data_points1 = DataPoints.new(12)
        [14.2, 16.4, 11.9, 15.2, 18.5, 22.1, 19.4, 25.1, 23.4, 18.1, 22.6, 17.2].each { |i| data_points1.insert(i) }
        data_points2 = DataPoints.new(12)
        [215, 325, 185, 332, 406, 522, 412, 614, 544, 421, 445, 408].each { |i| data_points2.insert(i) }

        assert_in_delta(0.9575066230015973, data_points1.correlation(data_points2))
      end
    end
  end
end
