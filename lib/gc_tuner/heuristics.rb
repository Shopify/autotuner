# frozen_string_literal: true

module GCTuner
  module Heuristics
    HEURISTICS = [
      Heuristic::SizePoolWarmup,
    ].freeze

    def heuristics
      @heuristics ||= enabled_heuristics.map(&:new)
    end

    def tuning_messages
      heuristics.map(&:tuning_message)
    end

    private

    def enabled_heuristics
      HEURISTICS.dup.keep_if(&:enabled?)
    end
  end
end
