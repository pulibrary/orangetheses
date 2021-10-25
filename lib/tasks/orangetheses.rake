# frozen_string_literal: true

require 'orangetheses'
require 'byebug'

namespace :orangetheses do
  desc 'Index all the metadata using OAI at SOLR=http://...'
  task index_all_oai: :environment do
    harvester = Orangetheses::Harvester.new
    indexer = Orangetheses::Indexer.new(solr_uri)

    harvester.index_all(indexer)
  end

  desc 'Exports all theses as solr json docs to FILEPATH'
  task :cache_theses, :environment do |_task, _args|
    fetcher = Orangetheses::Fetcher.new
    indexer = Orangetheses::Indexer.new

    File.open(json_file_path, 'w') do |f|
      fetched = fetcher.cache_all_collections(indexer)
      fetched_json = fetched.to_json
      f.write(fetched_json.to_s)
    end
  end

  desc 'Index all from REST service at SOLR=http://...'
  task :index_all do |_task, _args|
    fetcher = Orangetheses::Fetcher.new
    indexer = Orangetheses::Indexer.new(solr_uri)

    fetcher.index_all_collections(indexer)
  end

  desc 'Index a Collection from REST service at SOLR=http://...'
  task :index_collection, :collection_id do |_task, args|
    collection_id = args[:collection_id]

    fetcher = Orangetheses::Fetcher.new
    indexer = Orangetheses::Indexer.new(solr_uri)

    fetcher.index_collection(indexer, collection_id)
  end

  desc 'Index all visuals at SOLR=http://...'
  task index_visuals: :environment do
    visuals = Orangetheses::Visual.new(ENV['SOLR'])
    visuals.delete_stale_visuals
    visuals.process_all_visuals
  end

  private

  def json_file_path
    @json_file_path ||= ENV['FILEPATH'] || '/tmp/theses.json'
  end

  def solr_uri
    ENV['SOLR'] || Orangetheses::Indexer.default_solr_url
  end
end
