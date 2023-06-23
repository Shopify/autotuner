# frozen_string_literal: true

module Autotuner
  module Configuration
    attr_reader :sample_ratio
    attr_writer :enabled
    attr_accessor :reporter

    # Set this callback to report debug information periodically.
    attr_accessor :debug_reporter

    def enabled?
      @enabled
    end

    def sample_ratio=(ratio)
      raise ArgumentError, "ratio must be between 0 and 1.0" unless (0..1.0).include?(ratio)

      @sample_ratio = ratio

      self.enabled = rand < ratio
    end
  end
end
