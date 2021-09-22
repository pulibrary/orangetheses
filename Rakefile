# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

import 'lib/tasks/orangetheses.rake'
import 'lib/tasks/oai.rake'
import 'lib/tasks/servers.rake'

RSpec::Core::RakeTask.new(:spec)

task default: :spec
