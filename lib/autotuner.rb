# frozen_string_literal: true

require_relative "autotuner/data_structure/data_points"

require_relative "autotuner/heuristic/base"
require_relative "autotuner/heuristic/gc_compact"
require_relative "autotuner/heuristic/heap_size_warmup"
require_relative "autotuner/heuristic/malloc"
require_relative "autotuner/heuristic/oldmalloc"
require_relative "autotuner/heuristic/remembered_wb_unprotected_objects"

require_relative "autotuner/report/base"
require_relative "autotuner/report/multiple_environment_variables"
require_relative "autotuner/report/single_environment_variable"
require_relative "autotuner/report/string"

require_relative "autotuner/configuration"
require_relative "autotuner/gc_context"
require_relative "autotuner/heuristics"
require_relative "autotuner/rack_plugin"
require_relative "autotuner/work_collector"
require_relative "autotuner/work_context"
require_relative "autotuner/system_context"
require_relative "autotuner/version"

module Autotuner
  extend Configuration
  extend Heuristics
end
