# frozen_string_literal: true

module Autotuner
  module Report
    class SingleEnvironmentVariable < Base
      attr_reader :env_name
      attr_reader :suggested_value
      attr_reader :configured_value

      def initialize(heuristic_name, assist_message, env_name, suggested_value, configured_value)
        super(heuristic_name, assist_message)

        @env_name = env_name
        @suggested_value = suggested_value
        @configured_value = configured_value
      end

      private

      def message
        msg = +"Suggested tuning value:\n"
        msg << "  #{env_name}=#{suggested_value}"
        msg << " (configured value: #{configured_value})" if configured_value
        msg << "\n"
        msg
      end
    end
  end
end
