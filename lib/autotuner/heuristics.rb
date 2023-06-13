# frozen_string_literal: true

module Autotuner
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

    def debug_messages
      heuristics.map(&:debug_message)
    end

    private

    def enabled_heuristics
      HEURISTICS.dup.keep_if(&:enabled?)
    end
  end
end
