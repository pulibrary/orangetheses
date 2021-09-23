# frozen_string_literal: true

require 'nokogiri'

def config_path
  File.expand_path(
    File.join(
      File.dirname(__FILE__), '..', 'config'
    )
  )
end
require config_path

require 'orangetheses/version'

module Orangetheses
  # OAI
  SET = 'com_88435_dsp019c67wm88m'
  METADATA_PREFIX = 'oai_dc'

  # REST service
  COMMUNITY_HANDLE = '88435/dsp019c67wm88m'
  SERVER_URL = 'https://dataspace.princeton.edu/rest'
  SERVER_URL = 'https://updatespace.princeton.edu/rest' if $test
  REST_LIMIT = 100

  autoload :Harvester, 'orangetheses/harvester'
  autoload :Fetcher, 'orangetheses/fetcher'
  autoload :Indexer, 'orangetheses/indexer'
  autoload :Visual, 'orangetheses/visual'
end

require 'orangetheses/railtie' if defined?(Rails)
