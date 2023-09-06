# Autotuner

Autotuner is a tool to help you tune the garbage collector of your Rails app. Autotuner plugs into Rack as a middleware and will collect data from the garbage collector between requests. It will then intelligently provide suggestions to tune the garbage collector for faster bootup, warmup, and response times.

## Installation

Install the gem and add to the application's Gemfile by executing:

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
  Autotuner.metrics_reporter = proc do |metrics|
    # stats is a hash of metric name (string) to integer value.
    metrics.each do |key, val|
      StatsD.gauge(key, val)
    end
  end
  ```

## Configuration

- `Autotuner.enabled=`: (required, unless `Autotuner.sample_ratio` is set) Sets whether autotuner is enabled or not. When autotuner is disabled, data is not collected and suggestions are not given. Defaults to `false`.
- `Autotuner.sample_ratio=`: (optional) Sets the portion of instances where autotuner is enabled. Pass a value between 0 (enabled on no intances) and 1.0 (enabled on all instances). Note that this does not sample reqeusts, but rather samples the portion of instances that have autotuner enabled (it will be enabled for all requests on those instances). Do not configure `Autotuner.enabled=` when you use this option.
- `Autotuner.reporter=`: (required) Callback called when a heuristic is ready to give a suggestion. The callback will be called with one argument which will be an instance of `Autotuner::Report::Base`. Call `#to_s` on this object to get a string containing instructions and recommendations. You must set this when autotuner is enabled.
- `Autotuner.debug_reporter=`: (optional) Callback to periodically emit debug messages of internal state of heuristics. The callback will be called with one argument which will be a hash with the heuristic name as the key and the debug message as the value. Regular users do not need to configure this as this is only useful for debugging purposes.
- `Autotuner.metrics_reporter=`: (optional) Callback to emit useful metrics about your service. The callback will be called with a hash containing the metric names (string) as the key and integer values.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Shopify/autotuner.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
