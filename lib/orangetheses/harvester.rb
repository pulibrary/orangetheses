require 'oai'
require 'tmpdir'

module Orangetheses
  class Harvester

    # @param [Hash] opts  options to pass to the client
    # @option opts [String] :dir  Directory in which to save files. A temporary
    #   directory will be created of this option is not included.
    # @option opts [String] :server ('http://dataspace.princeton.edu/oai/')
    # @option opts [String] :metadata_prefix ('oai_dc')
    # @option opts [String] :verb ('ListRecords')
    # @option opts [String] :set ('hdl_88435_dsp019c67wm88m')
    def initialize(dir: Dir.mktmpdir,
                   server: PMH_SERVER,
                   metadata_prefix: METADATA_PREFIX,
                   verb: "ListRecords",
                   set: SET)
      params = binding.local_variables
      params.each { |p| instance_variable_set("@#{p.to_s}", eval(p.to_s))}
    end

    # @return [Array<String, Symbol>] A list of paths to the files
    def harvest_all
      # use @dir here
    end

    private
    
    def client
      @client ||= OAI::Client.new @server, headers: {
        metadataPrefix: @metadata_prefix,
        verb: @verb,
        set: @set
      }
    end

  end
end
