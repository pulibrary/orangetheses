# frozen_string_literal: true

require 'bundler/setup'
require 'orangetheses'
require 'pry-byebug'
require 'simplecov'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter
  ]
)
SimpleCov.start

RSpec.configure do |config|
  config.color = true
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.exclusion_filter = {
    ruby: lambda { |version|
      RUBY_VERSION.to_s !~ /^#{version}/
    }
  }
end

def fixture_path(filename)
  File.join(File.dirname(__FILE__), 'fixtures', filename)
end

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8
