# frozen_string_literal: true

module Autotuner
  module Report
    class Base
      DISCLAIMER_MESSAGE = <<~MSG
        It is always recommended to experiment with these suggestions as some suggestions may not always yield positive performance improvements. The recommended method is to perform A/B testing where a portion of traffic does not have the these suggested values and a portion of traffic with these suggested values.
      MSG

      attr_reader :assist_message

      def initialize(assist_message)
        @assist_message = assist_message
      end

      def to_s
        msg = +assist_message
        msg << "\n"

        m = message
        if m
          msg << m
          msg << "\n"
        end

        msg << DISCLAIMER_MESSAGE
        msg.freeze
      end

      private

      def message
        raise NotImplementedError
      end
    end
  end
end
