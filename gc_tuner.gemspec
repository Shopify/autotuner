# frozen_string_literal: true

require_relative "lib/gc_tuner/version"

Gem::Specification.new do |spec|
  spec.name = "gc_tuner"
  spec.version = GCTuner::VERSION
  spec.authors = ["Peter Zhu"]
  spec.email = ["peter@peterzhu.ca"]

  spec.summary = "Get suggestions to tune Ruby's garbage collector"
  spec.homepage = "https://github.com/Shopify/gc_tuner"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Shopify/gc_tuner"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    %x(git ls-files -z).split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency("mocha")
  spec.add_development_dependency("rubocop-minitest")
  spec.add_development_dependency("rubocop-shopify")
end
