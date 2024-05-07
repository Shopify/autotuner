# frozen_string_literal: true

module Autotuner
  module Heuristic
    class GCCompact < Base
      class << self
        def supported?
          true
        end
      end

      def initialize(_system_context)
        super

        @called_gc_compact = nil
      end

      def name
        "GCCompact"
      end

      def call(request_context)
        return unless @called_gc_compact.nil?

        @called_gc_compact = request_context.before_gc_context.stat[:compact_count] > 0
      end

      def tuning_report
        return if @called_gc_compact

        # Don't give suggestion twice
        @called_gc_compact = true

        Report::String.new(<<~MSG)
          The following suggestion runs compaction at boot time, which reduces fragmentation inside of the Ruby heap. This can improve performance and reduce memory usage in forking web servers.

          Before forking your web server, run the following Ruby code:

            3.times { GC.start }
            GC.compact

          For example, in Puma, add the following code into config/puma.rb:

            compacted = false
            before_fork do
              unless compacted
                3.times { GC.start }
                GC.compact
                compacted = true
              end
            end
        MSG
      end

      def debug_state
        {
          called_gc_compact: @called_gc_compact,
        }
      end
    end
  end
end
