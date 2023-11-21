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
  # These are the handle and dspace ID for Princeton University Undergraduate Senior Theses, 1924-2021
  # on the production server.
  COMMUNITY_HANDLE = '88435/dsp019c67wm88m'
  COMMUNITY_ID = '267'
  SERVER_URL = 'https://dataspace.princeton.edu/rest'
  REST_LIMIT = 100
  RETRY_LIMIT = 5

  autoload(:DataspaceDocument, 'orangetheses/dataspace_document')
  autoload(:Fetcher, 'orangetheses/fetcher')
  autoload(:Harvester, 'orangetheses/harvester')
  autoload(:Indexer, 'orangetheses/indexer')
  autoload(:Visual, 'orangetheses/visual')
end

require 'orangetheses/railtie' if defined?(Rails)
