# frozen_string_literal: true

module Autotuner
  class Report
    attr_reader :assist_message
    attr_reader :env_name
    attr_reader :suggested_value
    attr_reader :configured_value

    def initialize(assist_message, env_name, suggested_value, configured_value)
      @assist_message = assist_message
      @env_name = env_name
      @suggested_value = suggested_value
      @configured_value = configured_value
    end

    def to_s
      msg = +@assist_message
      msg << "\n"
      case @env_name
      when Array
        msg << "Suggested tuning values:\n"
        env_name.each_with_index do |env, i|
          msg << suggested_tuning_str(env, suggested_value[i], configured_value[i])
        end
      else
        msg << "Suggested tuning value:\n"
        msg << suggested_tuning_str(env_name, suggested_value, configured_value)
      end
      msg.freeze
    end

    private

    def suggested_tuning_str(env, suggested, configured)
      str = +"  #{env}=#{suggested}"
      str << " (configured value: #{configured})" if configured
      str << "\n"
      str
    end
  end
end
