# frozen_string_literal: true

module Autotuner
  module Heuristics
    HEURISTICS = Heuristic::Base.subclasses.freeze
    ENABLED_HEURISTICS = HEURISTICS.dup.keep_if(&:enabled?).freeze

    def enabled_heuristics
      ENABLED_HEURISTICS
    end
  end
end
