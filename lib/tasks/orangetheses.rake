require 'orangetheses'

namespace :orangetheses do

  desc "Index all teh metadatas using OAI at SOLR=http://..."
  task :index_all_oai do
    harvester = Orangetheses::Harvester.new
    indexer = Orangetheses::Indexer.new(ENV['SOLR'])
    harvester.index_all(indexer)
  end

  desc "Exports all theses as solr json docs to FILEPATH"
  task :cache_theses do
    fetcher = Orangetheses::Fetcher.new
    indexer = Orangetheses::Indexer.new
    path = ENV['FILEPATH'] || '/tmp/theses.json'
    File.open(path, 'w') { |f| f.write(fetcher.cache_all_collections(indexer).to_json.to_s) }
  end

  desc "Index all from REST service at SOLR=http://..."
  task :index_all do
    fetcher = Orangetheses::Fetcher.new
    indexer = Orangetheses::Indexer.new(ENV['SOLR'])
    fetcher.index_all_collections(indexer)
  end

  desc "Index all visuals at SOLR=http://..."
  task :index_visuals do
    visuals = Orangetheses::Visual.new(ENV['SOLR'])
    visuals.delete_stale_visuals
    visuals.process_all_visuals
  end

end
