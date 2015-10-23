require 'oai'

module Orangetheses
  class Harvester

    def client(server: PMH_SERVER, metadata_prefix: METADATA_PREFIX,
      verb: "ListRecords", set: SET)
      @client ||= OAI::Client.new server, headers: {
        metadataPrefix: metadata_prefix,
        verb: verb,
        set: set
      }
    end

  end
end
