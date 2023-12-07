# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'orangetheses/version'

Gem::Specification.new do |spec|
  spec.name          = 'orangetheses'
  spec.version       = Orangetheses::VERSION
  spec.authors       = ['Jon Stroop']
  spec.email         = ['jpstroop@gmail.com']

  spec.summary       = 'Indexing routines for Princeton Theses.'
  spec.description   = 'Works with DSpace OAI-PMH service'
  spec.homepage      = 'https://github.com/pulibrary/orangetheses'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.' unless spec.respond_to?(:metadata)

  spec.metadata['allowed_push_host'] = ''

  spec.required_ruby_version = '>= 3.1'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '>= 1.16.0', '< 3'
  spec.add_development_dependency 'coveralls_reborn', '~> 0.23'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop', '~> 1.57'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.25'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'webmock'

  spec.add_dependency 'chronic'
  spec.add_dependency 'erb'
  spec.add_dependency 'faraday'
  spec.add_dependency 'iso-639'
  spec.add_dependency 'nokogiri'
  spec.add_dependency 'oai'
  spec.add_dependency 'psych', '~> 5.1'
  spec.add_dependency 'retriable'
  spec.add_dependency 'rsolr'
  spec.add_dependency 'yaml'
end
