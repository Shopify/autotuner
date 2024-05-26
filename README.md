# Autotuner

Autotuner is a tool designed to help you tune the garbage collector of your Rails app. Autotuner integrates into Rack as a middleware and collects data from the garbage collector between requests. It will then intelligently provide suggestions to tune the garbage collector for faster bootup, warmup, and response times.

## Installation

To install the gem, add it to the application's Gemfile by executing:

```
$ bundle add autotuner
```

## Quick start

1. Open the `config.ru` file in your Rails app and add the following line immediately above `run(Rails.application)`:
   ```ruby
   use(Autotuner::RackPlugin)
   ```
1. Create an initializer in `config/initializers/autotuner.rb`:
   ```ruby
   # Enable autotuner. Alternatively, call Autotuner.sample_ratio= with a value
   # between 0 and 1.0 to sample on a portion of instances.
   Autotuner.enabled = true

   # This callback is called whenever a suggestion is provided by this gem.
   # You can output this report to your logging pipeline, stdout, a file,
   # or somewhere else!
   Autotuner.reporter = proc do |report|
     Rails.logger.info(report.to_s)
   end

   # This (optional) callback is called to provide metrics that can give you
   # insights about the performance of your app. It's recommended to send this
   # data to your observability service (e.g. Datadog, Prometheus, New Relic, etc).
   # Use a metric type that would allow you to calculate the average and percentiles.
   # On Datadog this would be the distribution type. On Prometheus this would be
   # the histogram type.
   Autotuner.metrics_reporter = proc do |metrics|
     # stats is a hash of metric name (string) to integer value.
     metrics.each do |key, val|
       StatsD.gauge(key, val)
     end
   end
   ```

## Experimenting with tuning suggestions

While autotuner aims to comprehensively analyze your traffic to give the suggestion, not all of the suggestions it provides will be perfect. There will be cases where the suggestions it provides may result in undesired outcomes. Therefore, it is NOT recommended to blindly apply suggestions from autotuner, but rather use a scientific approach to experiment with the suggestions. There are a few steps to this.

1. Before any suggestions from autotuner is applied, make sure you are collecting system metrics from your Rails app. Send this data to your observability service so you can measure average, 50th percentile, 99th percentile, and 99.9th percentile data.

   You can use `Autotuner.metrics_reporter` to collect important metrics from your app, including: GC time, number of major and minor GC cycles, request time, and number of heap pages allocated.
1. Establish an experimental group of machines/containers in production. Since response times and the state of the garbage collector are highly variable, it's much easier and more reliable to compare two groups at the same time rather than across different time periods with different traffic patterns.

   You can do this by assigning a random number to each machine/container at boot, and using that number to determine the group it belongs in. Depending on the traffic of your app, you may want to place between 5% (high traffic apps) to 50% (low traffic apps) in the experimental group.
1. Apply suggestions from Autotuner one at a time in the experimental group, and observe the impacts of the tuning. You may want to observe the impact over a few days to a week, including warmup performance after a new deploy and long periods of no deploys (such as a weekend).

   If you observe that the suggestion provides positive improvements, then also apply the suggestion to the default group and experiment with the next tuning suggestion provided by Autotuner.

   Some suggestions may provide a trade-off. For example, it may improve average response time at the expense of worse extremes (99th or 99.9th percentile). It is up to you to determine whether the trade-off is worth it.

   Some suggestions may cause a decrease in performance. In that case, discard the suggestion and experiment with the next suggestion provided by Autotuner.

## Configuration

- `Autotuner.enabled=`: (required, unless `Autotuner.sample_ratio` is set) Sets whether autotuner is enabled or not. When autotuner is disabled, data is not collected and suggestions are not given. Defaults to `false`.
- `Autotuner.sample_ratio=`: (optional) Sets the portion of instances where autotuner is enabled. Pass a value between 0 (enabled on no instances) and 1.0 (enabled on all instances). Note that this does not sample requests, but rather samples the portion of instances that have autotuner enabled (it will be enabled for all requests on those instances). Do not configure `Autotuner.enabled=` when you use this option.
- `Autotuner.reporter=`: (required) Callback called when a heuristic is ready to give a suggestion. The callback will be called with one argument which will be an instance of `Autotuner::Report::Base`. Call `#to_s` on this object to get a string containing instructions and recommendations. You must set this when autotuner is enabled.
- `Autotuner.debug_reporter=`: (optional) Callback to periodically emit debug messages of internal state of heuristics. The callback will be called with one argument which will be a hash with the heuristic name as the key and the debug message as the value. Regular users do not need to configure this as this is only useful for debugging purposes.
- `Autotuner.metrics_reporter=`: (optional) Callback to emit useful metrics about your service. The callback will be called with a hash containing the metric names (string) as the key and integer values.

## Emitted Metrics

The following metrics are passed to the `metrics_reporter` callback after each request.

| Name                  | Description |
| --------------------- | ----------- |
| `diff.time`           | Time spent doing garbage collection during the request. Produced by [GC::stat](https://docs.ruby-lang.org/en/master/GC.html#method-c-stat) |
| `diff.minor_gc_count` | Number of minor garbage collections that occurred during the request. Produced by [GC::stat](https://docs.ruby-lang.org/en/master/GC.html#method-c-stat) |
| `diff.major_gc_count` | Number of major garbage collections that occurred during the request. Produced by [GC::stat](https://docs.ruby-lang.org/en/master/GC.html#method-c-stat) |
| `heap_pages`          | Number of heap pages in use after the request. Produced by [GC::stat](https://docs.ruby-lang.org/en/master/GC.html#method-c-stat) |
| `request_time`        | Total duration of the request. |

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Shopify/autotuner.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
