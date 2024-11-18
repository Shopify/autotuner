# frozen_string_literal: true

module Autotuner
  module Report
    class MultipleEnvironmentVariables < Base
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
        msg = +"Suggested tuning values:\n"
        env_name.each_with_index do |env, i|
          msg << suggested_tuning_str(env, suggested_value[i], configured_value[i])
        end
        msg
      end

      def suggested_tuning_str(env, suggested, configured)
        str = "  #{env}=#{suggested}"
        str << " (configured value: #{configured})" if configured
        str << "\n"
        str
      end
    end
  end
end
