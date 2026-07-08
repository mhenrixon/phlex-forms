# frozen_string_literal: true

source "https://rubygems.org"
gemspec

group :development, :test do
  gem "actionview", "~> 8.0" # ActionText::RichText stub for rich-text specs
  gem "activemodel", "~> 8.0" # for model-bound / validation-inference specs
  gem "daisyui", ">= 1.2" # soft runtime dependency; present here to test the daisy theme
  # soft runtime dependency (gemspec has no hard dep); present here to test
  # Forms::Live and the Forms::TagField tag primitives (>= 0.11.4 ships the
  # reactive_tags client handlers the tag widget's wire contract targets).
  gem "phlex-reactive", ">= 0.11.4"
  gem "debug"
  gem "gem-release"
  gem "rake"
  gem "rspec"
  gem "rubocop"
  gem "rubocop-performance"
  gem "rubocop-rake"
  gem "rubocop-rspec"
  gem "super_diff"
end
