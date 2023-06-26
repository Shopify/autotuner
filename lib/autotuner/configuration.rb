# frozen_string_literal: true

module Autotuner
  module Configuration
    attr_reader :sample_ratio
    attr_accessor :reporter

    # Set this callback to report debug information periodically.
    attr_accessor :debug_reporter

    def enabled?
      @enabled
    end

    def enabled=(enabled)
      raise ArgumentError, "cannot configure `enabled` when `sample_ratio` is configured" if sample_ratio

      @enabled = enabled
    end

    def sample_ratio=(ratio)
      raise ArgumentError, "`ratio` must be between 0 and 1.0" unless (0..1.0).include?(ratio)
      if enabled? || enabled? == false
        raise ArgumentError, "cannot configure `sample_ratio` when `enabled` is configured"
      end

      @sample_ratio = ratio

      @enabled = rand < ratio
    end
  end
end
