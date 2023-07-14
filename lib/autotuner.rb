# frozen_string_literal: true

require_relative "autotuner/data_structure/data_points"

require_relative "autotuner/heuristic/base"
require_relative "autotuner/heuristic/malloc"
require_relative "autotuner/heuristic/oldmalloc"
require_relative "autotuner/heuristic/size_pool_warmup"

require_relative "autotuner/report/base"
require_relative "autotuner/report/multiple_environment_variables"
require_relative "autotuner/report/single_environment_variable"

require_relative "autotuner/configuration"
require_relative "autotuner/gc_context"
require_relative "autotuner/heuristics"
require_relative "autotuner/rack_plugin"
require_relative "autotuner/request_collector"
require_relative "autotuner/request_context"
require_relative "autotuner/system_context"
require_relative "autotuner/version"

module Autotuner
  extend Configuration
  extend Heuristics
end
