# frozen_string_literal: true

module Autotuner
  module Heuristics
    HEURISTICS = Heuristic::Base.subclasses.freeze
    SUPPORTED_HEURISTICS = HEURISTICS.dup.keep_if(&:supported?).freeze

    def supported_heuristics
      SUPPORTED_HEURISTICS
    end
  end
end
