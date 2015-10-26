require 'orangetheses'

namespace :orangetheses do

  desc "Index all teh metadatas. Include SOLR=http://..."
  task :index_all do
    harvester = Orangetheses::Harvester.new
    indexer = Orangetheses::Indexer.new(ENV['SOLR'])
    harvester.index_all(indexer)
  end

end
