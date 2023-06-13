# frozen_string_literal: true

module Autotuner
  class RackPlugin
    def initialize(app)
      @app = app
      @request_collector = RequestCollector.new
    end

    def call(env)
      if Autotuner.enabled?
        @request_collector.request do
          @app.call(env)
        end
      else
        @app.call(env)
      end
    end
  end
end
