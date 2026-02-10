# frozen_string_literal: true

module Autotuner
  module Heuristic
    class Base
      class << self
        def enabled?
          !@disabled
        end

        def disable!
          @disabled = true
        end

        def supported?
          raise NotImplementedError
        end
      end

      def initialize(system_context)
        @system_context = system_context
      end

      def name
        raise NotImplementedError
      end

      def call(work_context)
        raise NotImplementedError
      end

      def tuning_report
        raise NotImplementedError
      end

      def debug_state
        raise NotImplementedError
      end
    end
  end
end
