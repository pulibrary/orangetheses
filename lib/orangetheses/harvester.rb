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
      # Cheaply write each karg in an i. var. with the same name
      binding.local_variables.each do |p|
        instance_variable_set("@#{p.to_s}", eval(p.to_s))
      end
    end

    # @return [Array<String>] A list of tmp directories containing metadata records
    def harvest_all
      dirs = []
      dir = nil
      client.list_records.full.each_with_index do |record, i|
        if i % 1000 == 0
          dir = Dir.mktmpdir(nil, @dir)
          dirs << dir
        end
        File.open(File.join(dir, "#{i}.xml"), 'w') do |f| 
          f.write(record.metadata)
        end
      end
      dirs
    end

    private

    def write_record_to_tmp_file(record)

      f = ::Tempfile.new(['orangetheses','.xml'], @dir)
      f.write(record.metadata)
      f.close
      f.path
    end

    def client
      @client ||= OAI::Client.new @server, headers: {
        metadataPrefix: @metadata_prefix,
        verb: @verb,
        set: @set
      }
    end

  end
end
