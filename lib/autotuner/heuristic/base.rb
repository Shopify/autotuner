# frozen_string_literal: true

module Autotuner
  module Heuristic
    class Base
      class << self
        def enabled?
          supported? && !@disabled
        end

        def disable!
          @disabled = true
        end

        private

        def supported?
          raise NotImplementedError
        end
      end

      def name
        raise NotImplementedError
      end

      def call(request_time, before_gc_context, after_gc_context)
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
