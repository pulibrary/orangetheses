require 'orangetheses'

namespace :orangetheses do

  desc "Index all teh metadatas using OAI. Include SOLR=http://..."
  task :index_all_oai do
    harvester = Orangetheses::Harvester.new
    indexer = Orangetheses::Indexer.new(ENV['SOLR'])
    harvester.index_all(indexer)
  end

  desc "Index all from REST service. Include SOLR=http://..."
  task :index_all do
    fetcher = Orangetheses::Fetcher.new
    indexer = Orangetheses::Indexer.new(ENV['SOLR'])
    fetcher.index_all_collections(indexer)
  end

end
