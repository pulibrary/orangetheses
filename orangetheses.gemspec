# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'orangetheses/version'

Gem::Specification.new do |spec|
  spec.name          = "orangetheses"
  spec.version       = Orangetheses::VERSION
  spec.authors       = ["Jon Stroop"]
  spec.email         = ["jpstroop@gmail.com"]

  spec.summary       = %q{Indexing routines for Princeton Theses.}
  spec.description   = %q{Works with OIT's DSpace OAI-PMH service}
  spec.homepage      = "https://github.com/pulibrary/orangetheses"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = ""
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 1.16.0", "< 3"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
  spec.add_dependency "iso-639"
  spec.add_dependency "oai"
  spec.add_dependency "faraday"
  spec.add_dependency "rsolr"
  spec.add_dependency "chronic"
end
