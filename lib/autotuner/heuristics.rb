# frozen_string_literal: true

module Autotuner
  module Heuristics
    HEURISTICS = Heuristic::Base.subclasses.freeze

    def heuristics
      @heuristics ||= enabled_heuristics.map(&:new)
    end

    private

    def enabled_heuristics
      HEURISTICS.dup.keep_if(&:enabled?)
    end
  end
end
