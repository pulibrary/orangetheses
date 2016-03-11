require 'faraday'
require 'json'
require 'tmpdir'

module Orangetheses
  class Fetcher

    # @param [Hash] opts  options to pass to the client
    # @option opts [String] :server ('http://dataspace.princeton.edu/rest/')
    # @option opts [String] :community ('267')
    def initialize(server: SERVER_URL,
                   community: COMMUNITY_ID)
      # Cheaply write each keyword arg to an instance var with the same name:
      binding.local_variables.each do |p|
        instance_variable_set("@#{p.to_s}", eval(p.to_s))
      end
    end

    # @param id [String] thesis collection id
    # @return [Array<Hash>] metadata hash for each record
    def fetch_collection(id)
      theses = []
      offset = 0
      count = REST_LIMIT
      until count < REST_LIMIT do
        url = "#{@server}/collections/#{id}/items?limit=#{REST_LIMIT}&offset=#{offset}&expand=metadata"
        puts url
        resp = Faraday.get url
        begin
          items = JSON.parse(resp.body)
        # retry if the rest service times out...
        rescue JSON::ParserError => e
          resp = Faraday.get url
          items = JSON.parse(resp.body)
        end
        theses << flatten_json(items)
        count = items.count
        offset += REST_LIMIT
      end
      theses.flatten
    end

    def index_collection(indexer, id)
      collection = fetch_collection(id)
      collection.each do |record|
        indexer.index_hash(record)
      end
    end

    def index_all_collections(indexer)
      collections.each do |c|
        index_collection(indexer, c)
      end
    end

    private

    def flatten_json(items)
      items.collect do |i|
        h = {}
        h['id'] = i['handle'][/[^\/]*$/]
        i['metadata'].each do |m|
          if h[m['key']].nil?
            h[m['key']] = [m['value']]
          else
            h[m['key']] << m['value']
          end
        end
        h
      end
    end


    def collections
      resp = Faraday.get "#{@server}/communities/#{@community}/collections"
      json = JSON.parse(resp.body)
      json.map {|i| i['id'].to_s}
    end

  end
end
