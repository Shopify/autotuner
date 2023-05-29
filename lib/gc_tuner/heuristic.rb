# frozen_string_literal: true

module GCTuner
  module Heuristic
    HEURISTICS = [
      SizePoolWarmup,
    ].freeze

    class << self
      def enabled_heuristics
        HEURISTICS.dup.keep_if(&:enabled?)
      end
    end
  end
end
