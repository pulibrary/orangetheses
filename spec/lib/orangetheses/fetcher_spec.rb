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

    stub_request(:get, "https://dataspace.princeton.edu/rest//collections/361/items?expand=metadata&limit=100&offset=100")
      .to_return(status: 300, body: "", headers: {})
  end

  it "exports theses as json" do
    fetched = fetcher.cache_all_collections(indexer)
    fetched_json = fetched.to_json
    parsed_response = JSON.parse(fetched_json)
    expect(parsed_response.first["id"]).to eq "dsp0141687h67f"
    expect(parsed_response.first["title_display"]).to eq "Calibration of the Princeton University Subsonic Instructional Wind Tunnel"
  end
end
