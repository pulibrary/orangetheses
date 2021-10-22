# frozen_string_literal: true

require 'spec_helper'

describe Orangetheses::Fetcher do
  let(:fetcher) { described_class.new(server: 'https://dataspace.princeton.edu/rest/', community: '267') }
  let(:indexer) { Orangetheses::Indexer.new }
  let(:api_collections) { File.read(fixture_path('api_collections.json')) }
  let(:api_client_get) { File.read(fixture_path('api_client_get.json')) }
  
  before do
    stub_request(:get, "https://dataspace.princeton.edu/rest//communities/267/collections")
      .to_return(status: 200, body: api_collections, headers: {})
      
    stub_request(:get, "https://dataspace.princeton.edu/rest//collections/361/items?expand=metadata&limit=100&offset=0")
      .to_return(status: 200, body: api_client_get, headers: {})
  end
  
  it "can be instantiated" do
    expect(fetcher).to be_instance_of(described_class)
  end
  
  it "exports theses as json" do
    fetched = fetcher.cache_all_collections(indexer)
    fetched_json = fetched.to_json
  end
end
