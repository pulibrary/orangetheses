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
    stub_request(:get, "https://dataspace.princeton.edu/rest/communities/")
      .to_return(status: 200, body: api_communities, headers: {})

    stub_request(:get, "https://dataspace.princeton.edu/rest/communities/267/collections")
      .to_return(status: 200, body: api_collections, headers: {})

    stub_request(:get, "https://dataspace.princeton.edu/rest/collections/361/items?expand=metadata&limit=100&offset=0")
      .to_return(status: 200, body: api_client_get, headers: {})

    stub_request(:get, "https://dataspace.princeton.edu/rest/collections/361/items?expand=metadata&limit=100&offset=100")
      .to_return(status: 200, body: "[]", headers: {})

    stub_request(:get, "https://dataspace.princeton.edu/rest/collections/9999/items?expand=metadata&limit=100&offset=0")
      .to_return(status: 200, body: '', headers: {})
  end

  ##
  # When no handle is given, Fetcher has a default value of COMMUNITY_HANDLE = '88435/dsp019c67wm88m'
  # which should resolve to DSpace ID 267
  it "takes a handle and gets a dspace id" do
    expect(fetcher.api_community_id).to eq '267'
  end
  
  context "cache theses as json" do
    around(:each) do |example|
      File.delete(cache) if File.exist?(cache)
      temp_filepath = ENV['FILEPATH']
      ENV['FILEPATH'] = cache
      example.run
      ENV['FILEPATH'] = temp_filepath
      File.delete(cache) if File.exist?(cache)
     end
     
     it "exports theses as json" do
       fetched = fetcher.cache_all_collections(indexer)
       fetched_json = fetched.to_json
       parsed_response = JSON.parse(fetched_json)
       expect(parsed_response.first["id"]).to eq "dsp0141687h67f"
       expect(parsed_response.first["title_display"]).to eq "Calibration of the Princeton University Subsonic Instructional Wind Tunnel"
     end
     
     it "knows where to write cached files" do
       expect(fetcher.json_file_path).to eq cache
     end
     
     it "writes a collection to a cache file" do
       expect(File.exist?(cache)).to eq false
       described_class.write_collection_to_cache('361')
       expect(File.exist?(cache)).to eq true
       cache_export = JSON.parse(File.read(cache))
       expect(cache_export.first["id"]).to eq "dsp0141687h67f"
     end
     
     it "writes all collections to a cache file" do
       expect(File.exist?(cache)).to eq false
       described_class.write_all_collections_to_cache
       expect(File.exist?(cache)).to eq true
       cache_export = JSON.parse(File.read(cache))
       expect(cache_export.first["id"]).to eq "dsp0141687h67f"
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
    it "retries if DSpace returns an empty string" do
      fetcher.logger = test_logger
      expect { fetcher.fetch_collection('9999') }.to raise_error JSON::ParserError
      log.rewind
      expect(log.read).to match("#{Orangetheses::RETRY_LIMIT} tries")
    end
  end
end
