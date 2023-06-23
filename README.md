# Autotuner

Autotuner is a tool to help you tune the garbage collector of Rails apps. Autotuner plugs into Rack as a middleware and will collect data from the garbage collector between requests. It will then intelligently provide suggestions to tune the garbage collector for faster bootup, warmup, and response times.

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
  Autotuner.enabled = true
  Autotuner.reporter = proc do |report|
    # This callback is called whenever a suggestion is provided by this gem.
    # You can output this report to your logging pipeline, stdout, a file,
    # or somewhere else!
    Rails.logger.info(report.to_s)
  end
  ```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Shopify/autotuner.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
