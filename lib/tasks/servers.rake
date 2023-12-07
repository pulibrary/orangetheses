# frozen_string_literal: true

namespace :servers do
  desc 'Start the Apache Solr container services using Lando.'
  task :start, :environment do
    system('lando start')
  end

  desc 'Stop the Lando Apache Solr container services.'
  task :stop, :environment do
    system('lando stop')
  end
end
