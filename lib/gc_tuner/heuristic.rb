# frozen_string_literal: true

module GCTuner
  module Heuristic
    HEURISTICS = [
      SizePoolWarmup,
    ].freeze

    def enabled_heuristics
      HEURISTICS.keep_if(&:enabled?)
    end
  end
end
