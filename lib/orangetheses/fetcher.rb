# frozen_string_literal: true

require 'faraday'
require 'json'
require 'tmpdir'
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
require 'logger'

module Orangetheses
  class Fetcher
    # @param [Hash] opts  options to pass to the client
    # @option opts [String] :server ('https://dataspace.princeton.edu/rest/')
    # @option opts [String] :community ('267')
    def initialize(server: SERVER_URL, community: COMMUNITY_HANDLE)
      # Cheaply write each keyword arg to an instance var with the same name:
      binding.local_variables.each do |p|
        instance_variable_set("@#{p}", eval(p.to_s))
      end
    end

    def logger
      @logger ||= begin
                    built = Logger.new(STDOUT)
                    built.level = Logger::DEBUG
                    built
                  end
    end

    # @param id [String] thesis collection id
    # @return [Array<Hash>] metadata hash for each record
    def fetch_collection(id)
      theses = []
      offset = 0
      completed = false

      until completed
        url = build_collection_url(id: id, limit: REST_LIMIT, offset: offset)
        logger.debug("Querying for the DSpace Collection at #{url}...")
        response = api_client.get(url)
        if response.status != 200
          completed = true
        else
          items = JSON.parse(response.body)

          theses << flatten_json(items)
          offset += REST_LIMIT
        end
      end

      theses.flatten
    end

    def index_collection(indexer, id)
      fetched = fetch_collection(id)
      fetched.each do |record|
        indexer.index_hash(record)
      end
    end

    def index_all_collections(indexer)
      collections.each do |c|
        index_collection(indexer, c)
      end
    end

    def cache_all_collections(indexer)
      records = []
      collections.each do |c|
        collection = fetch_collection(c)
        collection.each do |record|
          records << indexer.get_solr_doc(record)
        end
      end
      records
    end

    private

    def build_collection_url(id:, limit:, offset:)
      "#{@server}/collections/#{id}/items?limit=#{limit}&offset=#{offset}&expand=metadata"
    end

    def flatten_json(items)
      items.collect do |i|
        h = {}
        h['id'] = i['handle'][%r{[^/]*$}]
        i['metadata'].each do |m|
          m['value'] = map_department(m['value']) if m['key'] == 'pu.department'
          m['value'] = map_program(m['value']) if m['key'] == 'pu.certificate'
          next if m['value'].nil?

          if h[m['key']].nil?
            h[m['key']] = [m['value']]
          else
            h[m['key']] << m['value']
          end
        end
        h
      end
    end

    def api_client
      Faraday
    end

    def api_communities
      @api_communities ||= begin
                             response = api_client.get("#{@server}/communities/")
                             response.body
                           end
    end

    def self.api_root_community_id
      '267'
    end

    def api_community
      @api_community ||= begin
                         api_communities.select { |c| c['handle'] == @community }
                       end
    end

    def api_community_id
      @api_community_id ||= api_community ? self.class.api_root_community_id : api_community['id']
    end

    def api_collections
      @api_collections ||= begin
                             response = api_client.get("#{@server}/communities/#{@community}/collections")
                             response.body
                           end
    end

    def api_collections_json
      @api_collections_json ||= begin
                                  JSON.parse(api_collections)
                                end
    end

    def collections
      @collections ||= api_collections_json.map { |i| i['id'] }
    end

    def map_department(dept)
      lc_authorized_departments[dept]
    end

    def map_program(program)
      lc_authorized_programs[program]
    end

    def lc_authorized_departments
      {
        'African American Studies' => 'Princeton University. Department of African American Studies',
        'Art and Archaeology' => 'Princeton University. Department of Art and Archaeology',
        'Aeronautical Engineering' => 'Princeton University. Department of Aeronautical Engineering',
        'Anthropology' => 'Princeton University. Department of Anthropology',
        'Architecture School' => 'Princeton University. School of Architecture',
        'Astrophysical Sciences' => 'Princeton University. Department of Astrophysical Sciences',
        'Biochemical Sciences' => 'Princeton University. Department of Biochemical Sciences',
        'Biology' => 'Princeton University. Department of Biology',
        'Civil and Environmental Engineering' => 'Princeton University. Department of Civil and Environmental Engineering',
        'Civil Engineering and Operations Research' => 'Princeton University. Department of Civil Engineering and Operations Research',
        'Chemical and Biological Engineering' => 'Princeton University. Department of Chemical and Biological Engineering',
        'Chemistry' => 'Princeton University. Department of Chemistry',
        'Classics' => 'Princeton University. Department of Classics',
        'Comparative Literature' => 'Princeton University. Department of Comparative Literature',
        'Computer Science' => 'Princeton University. Department of Computer Science',
        'East Asian Studies' => 'Princeton University. Department of East Asian Studies',
        'Economics' => 'Princeton University. Department of Economics',
        'Ecology and Evolutionary Biology' => 'Princeton University. Department of Ecology and Evolutionary Biology',
        'Electrical Engineering' => 'Princeton University. Department of Electrical Engineering',
        'Engineering and Applied Science' => 'Princeton University. School of Engineering and Applied Science',
        'English' => 'Princeton University. Department of English',
        'French and Italian' => 'Princeton University. Department of French and Italian',
        'Geosciences' => 'Princeton University. Department of Geosciences',
        'German' => 'Princeton University. Department of Germanic Languages and Literatures',
        'History' => 'Princeton University. Department of History',
        'Special Program in Humanities' => 'Princeton University. Special Program in the Humanities',
        'Independent Concentration' => 'Princeton University Independent Concentration Program',
        'Mathematics' => 'Princeton University. Department of Mathematics',
        'Molecular Biology' => 'Princeton University. Department of Molecular Biology',
        'Mechanical and Aerospace Engineering' => 'Princeton University. Department of Mechanical and Aerospace Engineering',
        'Medieval Studies' => 'Princeton University. Program in Medieval Studies',
        'Modern Languages' => 'Princeton University. Department of Modern Languages.',
        'Music' => 'Princeton University. Department of Music',
        'Near Eastern Studies' => 'Princeton University. Department of Near Eastern Studies',
        'Neuroscience' => 'Princeton Neuroscience Institute',
        'Operations Research and Financial Engineering' => 'Princeton University. Department of Operations Research and Financial Engineering',
        'Oriental Studies' => 'Princeton University. Department of Oriental Studies',
        'Philosophy' => 'Princeton University. Department of Philosophy',
        'Physics' => 'Princeton University. Department of Physics',
        'Politics' => 'Princeton University. Department of Politics',
        'Psychology' => 'Princeton University. Department of Psychology',
        'Religion' => 'Princeton University. Department of Religion',
        'Romance Languages and Literatures' => 'Princeton University. Department of Romance Languages and Literatures',
        'Slavic Languages and Literature' => 'Princeton University. Department of Slavic Languages and Literatures',
        'Sociology' => 'Princeton University. Department of Sociology',
        'Spanish and Portuguese' => 'Princeton University. Department of Spanish and Portuguese Languages and Cultures',
        'Spanish and Portuguese Languages and Cultures' => 'Princeton University. Department of Spanish and Portuguese Languages and Cultures',
        'Statistics' => 'Princeton University. Department of Statistics',
        'School of Public and International Affairs' => 'School of Public and International Affairs'
      }
    end

    def lc_authorized_programs
      {
        'African American Studies Program' => 'Princeton University. Program in African-American Studies',
        'African Studies Program' => 'Princeton University. Program in African Studies',
        'American Studies Program' => 'Princeton University. Program in American Studies',
        'Applications of Computing Program' => 'Princeton University. Program in Applications of Computing',
        'Architecture and Engineering Program' => 'Princeton University. Program in Architecture and Engineering',
        'Center for Statistics and Machine Learning' => 'Princeton University. Center for Statistics and Machine Learning',
        'Creative Writing Program' => 'Princeton University. Creative Writing Program',
        'East Asian Studies Program' => 'Princeton University. Program in East Asian Studies',
        'Engineering Biology Program' => 'Princeton University. Program in Engineering Biology',
        'Engineering and Management Systems Program' => 'Princeton University. Program in Engineering and Management Systems',
        'Environmental Studies Program' => 'Princeton University. Program in Environmental Studies',
        'Ethnographic Studies Program' => 'Princeton University. Program in Ethnographic Studies',
        'European Cultural Studies Program' => 'Princeton University. Program in European Cultural Studies',
        'Finance Program' => 'Princeton University. Program in Finance',
        'Geological Engineering Program' => 'Princeton University. Program in Geological Engineering',
        'Global Health and Health Policy Program' => 'Princeton University. Program in Global Health and Health Policy',
        'Hellenic Studies Program' => 'Princeton University. Program in Hellenic Studies',
        'Humanities Council and Humanistic Studies Program' => 'Princeton University. Program in Humanistic Studies',
        'Judaic Studies Program' => 'Princeton University. Program in Judaic Studies',
        'Latin American Studies Program' => 'Princeton University. Program in Latin American Studies',
        'Latino Studies Program' => 'Princeton University. Program in Latino Studies',
        'Linguistics Program' => 'Princeton University. Program in Linguistics',
        'Materials Science and Engineering Program' => 'Princeton University. Program in Materials Science and Engineering',
        'Medieval Studies Program' => 'Princeton University. Program in Medieval Studies',
        'Near Eastern Studies Program' => 'Princeton University. Program in Near Eastern Studies',
        'Neuroscience Program' => 'Princeton University. Program in Neuroscience',
        'Program in Cognitive Science' => 'Princeton University. Program in Cognitive Science',
        'Program in Entrepreneurship' => 'Princeton University. Program in Entrepreneurship',
        'Program in Gender and Sexuality Studies' => 'Princeton University. Program in Gender and Sexuality Studies',
        'Program in Music Theater' => 'Princeton University. Program in Music Theater',
        'Program in Technology & Society, Technology Track' => 'Princeton University. Program in Technology and Society',
        'Program in Values and Public Life' => 'Princeton University. Program in Values and Public Life',
        'Quantitative and Computational Biology Program' => 'Princeton University. Program in Quantitative and Computational Biology',
        'Robotics & Intelligent Systems Program' => 'Princeton University. Program in Robotics and Intelligent Systems',
        'Russian & Eurasian Studies Program' => 'Princeton University. Program in Russian, East European and Eurasian Studies',
        'South Asian Studies Program' => 'Princeton University. Program in South Asian Studies',
        'Theater' => 'Princeton University. Program in Theater',
        'Theater Program' => 'Princeton University. Program in Theater',
        'Sustainable Energy Program' => 'Princeton University. Program in Sustainable Energy',
        'Urban Studies Program' => 'Princeton University. Program in Urban Studies'
      }
    end
  end
end
