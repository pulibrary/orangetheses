require 'orangetheses/version'

module Orangetheses
  SET = 'com_88435_dsp019c67wm88m'
  PMH_SERVER = 'http://dataspace.princeton.edu/oai/request'
  PMH_SERVER = 'http://asdspace300l.princeton.edu/oai/request' if $test
  METADATA_PREFIX = 'oai_dc'

  autoload :Harvester, 'orangetheses/harvester'
  autoload :Indexer, 'orangetheses/indexer'

end
