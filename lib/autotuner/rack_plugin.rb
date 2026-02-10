# frozen_string_literal: true

module Autotuner
  class RackPlugin
    def initialize(app)
      @app = app
      @work_collector = WorkCollector.new(work_type: "request")
    end

    def call(env)
      if Autotuner.enabled?
        @work_collector.measure do
          @app.call(env)
        end
      else
        @app.call(env)
      end
    end
  end
end
