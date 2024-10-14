# frozen_string_literal: true

require 'bundler/setup'
require 'coveralls'
require 'orangetheses'
require 'simplecov'
require 'webmock/rspec'
require 'pry-byebug'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start do
  add_filter 'spec'
end

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

def oai_record_fixture_path
  File.join(File.dirname(__FILE__), 'fixtures', 'oai', 'record.xml')
end

def holding_locations_fixture_path
  File.join(File.dirname(__FILE__), 'fixtures', 'bibdata', 'holding_locations.json')
end

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Leave this here to make it easier to disable WebMock when testing against
# the live DSpace API
# WebMock.enable_net_connect!
