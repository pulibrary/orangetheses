# frozen_string_literal: true

require 'orangetheses'

namespace :oai do
  desc 'Index Published Item using the OAI-PMH'
  task :index_record, [:identifier] do |_task, args|
    harvester = Orangetheses::Harvester.new
    indexer = Orangetheses::Indexer.new

    identifier = args[:identifier]
    harvester.index_item(indexer:, identifier:)
  end

  desc 'Index all Items within a set using the OAI-PMH'
  task :index_all do |_task, args|
    set = args.fetch(:set, nil)
    harvester = Orangetheses::Harvester.new(set:)

    indexer = Orangetheses::Indexer.new

    harvester.index_all(indexer)
  end

  desc 'Index all Items using the OAI-PMH'
  task :index_all do |_task, _args|
    harvester = Orangetheses::Harvester.new
    indexer = Orangetheses::Indexer.new

    harvester.index_all(indexer)
  end
end
