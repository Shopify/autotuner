# frozen_string_literal: true

module Autotuner
  class Railtie < ::Rails::Railtie
    initializer "autotuner.active_job" do
      require_relative "active_job_plugin"

      ActiveSupport.on_load(:active_job) do
        include Autotuner::ActiveJobPlugin
      end
    end
  end
end
