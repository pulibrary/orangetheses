# frozen_string_literal: true

require 'orangetheses'

namespace :oai do
  desc 'Index Published Item using the OAI-PMH'
  task :index_record, [:identifier] do |_task, args|
    harvester = Orangetheses::Harvester.new
    indexer = Orangetheses::Indexer.new

    identifier = args[:identifier]
    harvester.index_item(indexer: indexer, identifier: identifier)
  end
end
