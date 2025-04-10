# frozen_string_literal: true

require 'spec_helper'

describe Orangetheses::Fetcher do
  let(:fetcher) { described_class.new }
  let(:indexer) { Orangetheses::Indexer.new }
  let(:api_communities) { File.read(fixture_path('communities.json')) }
  let(:api_collections) { File.read(fixture_path('api_collections.json')) }
  let(:api_client_get) { File.read(fixture_path('api_client_get.json')) }
  let(:cache) { fixture_path('cache_output.json') }

  before do
    stub_request(:get, 'https://dataspace-dev.princeton.edu/rest/communities/')
      .to_return(status: 200, body: api_communities, headers: {})

    stub_request(:get, 'https://dataspace-dev.princeton.edu/rest/communities/267/collections')
      .to_return(status: 200, body: api_collections, headers: {})

    stub_request(:get, 'https://dataspace-dev.princeton.edu/rest/collections/361/items?expand=metadata&limit=100&offset=0')
      .to_return(status: 200, body: api_client_get, headers: {})

    stub_request(:get, 'https://dataspace-dev.princeton.edu/rest/collections/361/items?expand=metadata&limit=100&offset=100')
      .to_return(status: 200, body: '[]', headers: {})

    stub_request(:get, 'https://dataspace-dev.princeton.edu/rest/collections/9999/items?expand=metadata&limit=100&offset=0')
      .to_return(status: 200, body: '', headers: {})
  end

  ##
  # When no handle is given, Fetcher has a default value of COMMUNITY_HANDLE = '88435/dsp019c67wm88m'
  # which should resolve to DSpace ID 267
  it 'takes a handle and gets a dspace id' do
    expect(fetcher.api_community_id).to eq '267'
  end

  context 'cache theses as json' do
    around do |example|
      File.delete(cache) if File.exist?(cache)
      temp_filepath = ENV['FILEPATH']
      ENV['FILEPATH'] = cache
      example.run
      ENV['FILEPATH'] = temp_filepath
      File.delete(cache) if File.exist?(cache)
    end

    it 'exports theses as json' do
      fetched = fetcher.cache_all_collections(indexer)
      expect(fetched).to be_an(Array)
      expect(fetched.length).to eq(1)
      document = fetched.first
      expect(document).to be_a(Orangetheses::DataspaceDocument)
      solr_document = document.to_solr
      expect(solr_document).to be_a(Hash)
      expect(solr_document).to include('id' => 'dsp0141687h67f')
      expect(solr_document).to include('title_display' => 'Calibration of the Princeton University Subsonic Instructional Wind Tunnel')
    end

    it 'knows where to write cached files' do
      expect(fetcher.json_file_path).to eq cache
    end

    it 'writes a collection to a cache file' do
      expect(File.exist?(cache)).to eq false
      described_class.write_collection_to_cache('361')
      expect(File.exist?(cache)).to eq true
      cached_file = File.read(cache)
      expect(cached_file).to be_a(String)
      expect(cached_file).not_to be_empty
      cache_exports = JSON.parse(cached_file)
      expect(cache_exports).to be_an(Array)
      expect(cache_exports.length).to eq(1)
      cache_export = cache_exports.first
      expect(cache_export).to be_a(Hash)
      expect(cache_export).to include('id' => 'dsp0141687h67f')
    end

    it 'writes all collections to a cache file' do
      expect(File.exist?(cache)).to eq false
      described_class.write_all_collections_to_cache
      expect(File.exist?(cache)).to eq true
      cache_export = JSON.parse(File.read(cache))
      expect(cache_export.first['id']).to eq 'dsp0141687h67f'
    end
  end

  context 'blank responses from DSpace API' do
    let(:log) { StringIO.new }
    let(:test_logger) do
      logger = Logger.new(log)
      logger.level = Logger::DEBUG
      logger
    end

    ##
    # When DSpace returns an empty string, retry the query RETRY_LIMIT times
    # If the issue is never resolved, the exception is raised.
    it 'retries if DSpace returns an empty string' do
      fetcher.logger = test_logger
      expect { fetcher.fetch_collection('9999') }.to raise_error JSON::ParserError
      log.rewind
      expect(log.read).to match("#{Orangetheses::RETRY_LIMIT} tries")
    end
  end

  context 'within the staging environment' do
    let(:community_json) do
      {
        "id": 267,
        "name": 'Princeton University Undergraduate Senior Theses, 1924-2021',
        "handle": '88435/dsp019c67wm88m',
        "type": 'community',
        "link": '/rest/communities/267',
        "expand": %w[
          parentCommunity
          collections
          subCommunities
          logo
          all
        ],
        "logo": nil,
        "parentCommunity": nil,
        "copyrightText": '',
        "introductoryText": "<h4>Members of the Princeton community wishing to view a senior thesis from 2014-2021 while away from campus should follow the instructions outlined on the <a href=\"https://princeton.service-now.com/snap?sys_id=6023&id=kb_article\">OIT website</a> for connecting to campus resources remotely. </h4>\r\n<h5>\r\nSee our <a href=\"http://libguides.princeton.edu/SeniorTheses/Home/\">Senior Thesis LibGuide</a> for helfpul information on searching and accessing Senior Theses</h5>",
        "shortDescription": '',
        "sidebarText": '',
        "countItems": 70_734,
        "subcommunities": [],
        "collections": []
      }
    end
    let(:communities_response_json) do
      [
        community_json
      ]
    end
    let(:communities_response_body) do
      JSON.generate(communities_response_json)
    end
    let(:collections_response_json) { [] }
    let(:collections_response_body) do
      JSON.generate(collections_response_json)
    end

    before do
      @env = ENV['RAILS_ENV']
      ENV['RAILS_ENV'] = 'staging'

      stub_request(:get, 'https://dataspace-staging.princeton.edu/rest/communities/').to_return(status: 200, body: communities_response_body)
      stub_request(:get, 'https://dataspace-staging.princeton.edu/rest/communities/267/collections').to_return(status: 200, body: collections_response_body)
    end

    after do
      # rubocop:disable RSpec/InstanceVariable
      ENV['RAILS_ENV'] = @env
      # rubocop:enable RSpec/InstanceVariable
    end

    it 'requests from the staging URI endpoint' do
      fetcher.cache_all_collections(indexer)

      expect(a_request(:get, 'https://dataspace-staging.princeton.edu/rest/communities/267/collections')).to have_been_made
      expect(a_request(:get, 'https://dataspace-staging.princeton.edu/rest/communities/')).to have_been_made
    end
  end

  context 'within the production environment' do
    let(:community_json) do
      {
        "id": 267,
        "name": 'Princeton University Undergraduate Senior Theses, 1924-2021',
        "handle": '88435/dsp019c67wm88m',
        "type": 'community',
        "link": '/rest/communities/267',
        "expand": %w[
          parentCommunity
          collections
          subCommunities
          logo
          all
        ],
        "logo": nil,
        "parentCommunity": nil,
        "copyrightText": '',
        "introductoryText": "<h4>Members of the Princeton community wishing to view a senior thesis from 2014-2021 while away from campus should follow the instructions outlined on the <a href=\"https://princeton.service-now.com/snap?sys_id=6023&id=kb_article\">OIT website</a> for connecting to campus resources remotely. </h4>\r\n<h5>\r\nSee our <a href=\"http://libguides.princeton.edu/SeniorTheses/Home/\">Senior Thesis LibGuide</a> for helfpul information on searching and accessing Senior Theses</h5>",
        "shortDescription": '',
        "sidebarText": '',
        "countItems": 70_734,
        "subcommunities": [],
        "collections": []
      }
    end
    let(:communities_response_json) do
      [
        community_json
      ]
    end
    let(:communities_response_body) do
      JSON.generate(communities_response_json)
    end
    let(:collections_response_json) { [] }
    let(:collections_response_body) do
      JSON.generate(collections_response_json)
    end

    before do
      @env = ENV['RAILS_ENV']
      ENV['RAILS_ENV'] = 'production'

      stub_request(:get, 'https://dataspace.princeton.edu/rest/communities/').to_return(status: 200, body: communities_response_body)
      stub_request(:get, 'https://dataspace.princeton.edu/rest/communities/267/collections').to_return(status: 200, body: collections_response_body)
    end

    after do
      # rubocop:disable RSpec/InstanceVariable
      ENV['RAILS_ENV'] = @env
      # rubocop:enable RSpec/InstanceVariable
    end

    it 'requests from the production URI endpoint' do
      fetcher.cache_all_collections(indexer)

      expect(a_request(:get, 'https://dataspace.princeton.edu/rest/communities/267/collections')).to have_been_made
      expect(a_request(:get, 'https://dataspace.princeton.edu/rest/communities/')).to have_been_made
    end
  end
end
