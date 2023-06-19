# frozen_string_literal: true

module Autotuner
  class Report
    attr_reader :assist_message
    attr_reader :env_name
    attr_reader :suggested_value
    attr_reader :configured_value

    DISCLAIMER_MESSAGE = <<~MSG
      It is always recommended to experiment with these suggestions as some suggestions may not always yield positive performance improvements. The recommended method is to perform A/B testing where a portion of traffic does not have the these suggested values and a portion of traffic with these suggested values.
    MSG

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
      msg << "\n"
      msg << DISCLAIMER_MESSAGE
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
