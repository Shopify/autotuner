# frozen_string_literal: true

module GCTuner
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

      def call(request_time, before_gc_context, after_gc_context)
        raise NotImplementedError
      end

      def tuning_message
        raise NotImplementedError
      end

      def debug_message
        raise NotImplementedError
      end
    end
  end
end
