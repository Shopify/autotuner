# frozen_string_literal: true

module GCTuner
  module DataStructure
    class DataPoints
      STABLE_RATIO = 0.5

      attr_reader :samples, :length, :compression_ratio

      def initialize(capacity)
        raise "Capacity must be even" if capacity.odd?

        @samples = Array.new(capacity)

        @temp_sample = 0
        @temp_sample_count = 0

        @length = 0
        @compression_ratio = 1
      end

      def insert(value)
        compress if @length == @samples.length

        @temp_sample += value
        @temp_sample_count += 1

        return unless @temp_sample_count == @compression_ratio

        @samples[@length] = @temp_sample / @temp_sample_count

        @length += 1
        @temp_sample = 0
        @temp_sample_count = 0
      end

      def stable_region_slope
        # Find line of best fit for the last 50%
        range = (@length * STABLE_RATIO).to_i...@length

        slope(range)
      end

      def plateaued?(delta = 0.1)
        # Not enough data until filled
        return false if @compression_ratio == 1

        stable_region_slope.abs <= delta
      end

      def correlation(y)
        raise "Length not equal" unless length == y.length
        raise "Compression ratio not equal" unless compression_ratio == y.compression_ratio

        # Find the correlation between this and y
        # https://www.mathsisfun.com/data/correlation.html
        sum_x = 0
        sum_y = 0
        sum_x_2 = 0
        sum_y_2 = 0
        sum_x_y = 0
        length.times do |i|
          x_val = @samples[i]
          y_val = y.samples[i]

          sum_x += x_val
          sum_y += y_val
          sum_x_2 += x_val**2
          sum_y_2 += y_val**2
          sum_x_y += x_val * y_val
        end

        ((length * sum_x_y) - (sum_x * sum_y)).to_f / \
          (Math.sqrt((length * sum_x_2) - (sum_x**2)) * Math.sqrt((length * sum_y_2) - (sum_y**2)))
      end

      def to_s
        inspect
      end

      private

      def compress
        (@length / 2).times do |i|
          @samples[i] = (@samples[i * 2] + @samples[i * 2 + 1]) / 2.0
        end

        @length /= 2
        @compression_ratio *= 2
      end

      def slope(range)
        # Find the slope for the area in range using least squares
        # https://www.mathsisfun.com/data/least-squares-regression.html
        sum_x = 0
        sum_y = 0
        sum_x_2 = 0
        sum_x_y = 0
        range.each do |i|
          sum_x += i
          sum_y += @samples[i]
          sum_x_2 += i**2
          sum_x_y += i * @samples[i]
        end

        (range.size * sum_x_y - (sum_x * sum_y)).to_f / (range.size * sum_x_2 - (sum_x**2))
      end
    end
  end
end
