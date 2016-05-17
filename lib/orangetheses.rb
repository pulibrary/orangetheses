require 'orangetheses/version'

module Orangetheses
  #$test = true
  # OAI
  SET = 'com_88435_dsp019c67wm88m'
  PMH_SERVER = 'http://dataspace.princeton.edu/oai/request'
  PMH_SERVER = 'http://updatespace.princeton.edu/oai/request' if $test
  METADATA_PREFIX = 'oai_dc'

  # REST service
  COMMUNITY_HANDLE = '88435/dsp019c67wm88m'
  SERVER_URL = 'http://dataspace.princeton.edu/rest'
  SERVER_URL = 'http://updatespace.princeton.edu/rest' if $test
  REST_LIMIT = 100

  autoload :Harvester, 'orangetheses/harvester'
  autoload :Fetcher, 'orangetheses/fetcher'
  autoload :Indexer, 'orangetheses/indexer'
  autoload :Visual, 'orangetheses/visual'
end
