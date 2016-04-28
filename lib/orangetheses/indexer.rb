require 'rsolr'
require 'rexml/document'
require 'chronic'
require 'logger'
require 'json'
require 'iso-639'

module Orangetheses
  class Indexer

    SET = 'Princeton University Senior Theses'

    NON_SPECIAL_ELEMENT_MAPPING = {
      'creator' => ['author_display', 'author_s'],
      'contributor' => ['advisor_display', 'author_s'],
      'format' => ['description_display'],
      'rights' => ['rights_reproductions_note_display'],
      'description' => ['summary_note_display']
    }

    REST_NON_SPECIAL_ELEMENT_MAPPING = {
      'dc.contributor.author' => ['author_display', 'author_s'],
      'dc.contributor.advisor' => ['advisor_display', 'author_s'],
      'dc.contributor' => ['contributor_display', 'author_s'],
      'pu.department' => ['department_display', 'author_s'],
      'dc.format.extent' => ['description_display'],
      'dc.rights.accessRights' => ['rights_reproductions_note_display'],
      'pu.location' => ['rights_reproductions_note_display'],
      'pu.date.classyear' => ['class_year_s', 'pub_date_start_sort', 'pub_date_end_sort'],
      'dc.description.abstract' => ['summary_note_display']
    }

    HARD_CODED_TO_ADD = {
      'format' => 'Senior Thesis'
    }

    def initialize(solr_server=nil)
      solr_server = 'http://localhost:8983/solr' if solr_server.nil?
      @solr = RSolr.connect(url: solr_server)
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::INFO
      @logger.formatter = proc do |severity, datetime, progname, msg|
        time = datetime.strftime("%H:%M:%S")
        "[#{time}] #{severity}: #{msg}\n"
      end
    end

    # @param element  A REXML::Element (because this is what we get from the OAI gem)
    # @return  The HTTP response status from Solr (??)
    def index(metadata_element)
      begin
        dc_elements = pull_dc_elements(metadata_element)
        doc = build_hash(dc_elements)
        @logger.info("Adding #{doc['id']}")
        @solr.add(doc, add_attributes: { commitWithin: 10 })
      rescue NoMethodError => e
        @logger.error(e.to_s)
        @logger.error(metadata_element)
      rescue Exception => e
        @logger.error(e.to_s)
        dc_elements.each { |element| @logger.error(element.to_s) }
      end

    end

    # @param doc [Hash] Metadata hash with dc and pu terms
    # @return  The HTTP response status from Solr (??)
    def index_hash(doc)
      begin
        solr_doc = build_solr_hash(doc)
        @logger.info("Adding #{solr_doc['id']}")
        @solr.add(solr_doc, add_attributes: { commitWithin: 10 })
      rescue NoMethodError => e
        @logger.error(e.to_s)
        @logger.error(doc.to_s)
      rescue Exception => e
        @logger.error(e.to_s)
        @logger.error(doc.to_s)
      end

    end

    private

    def build_hash(dc_elements)
      date = choose_date(dc_elements)
      h = {
        'id' => id(dc_elements),
        'title_t' => title(dc_elements),
        'title_citation_display' => title(dc_elements),
        'title_display' => title(dc_elements),
        'title_sort' => title_sort(dc_elements),
        'author_sort' => author_sort(dc_elements),
        'format' => 'Senior Thesis',
        'pub_date_display' => date,
        'pub_date_start_sort' => date,
        'pub_date_end_sort' => date,
        'class_year_s' => date,
        'access_facet' => 'Online',
        'electronic_access_1display' => ark(dc_elements),
        'standard_no_1display' => non_ark_ids(dc_elements),
        'holdings_1display' => online_holding
      }
      h.merge!(map_non_special_to_solr(dc_elements))
      h.merge!(HARD_CODED_TO_ADD)
      h
    end

    # @return Array<REXML::Element>  the descriptive elements
    def pull_dc_elements(element)
      element.elements.to_a('oai_dc:dc/*')
    end

    def choose_date(dc_elements)
      dates = all_date_elements(dc_elements).map { |d| Chronic.parse(d.text) }
      dates.empty? ? nil : dates.min.year
    end

    def all_date_elements(dc_elements)
      dc_elements.select { |e| e.name == 'date' }
    end

    def title(dc_elements)
      titles = dc_elements.select { |e| e.name == 'title' }
      titles.empty? ? nil : titles.first.text
    end

    def title_sort(dc_elements)
      titles = dc_elements.select { |e| e.name == 'title' }
      title = titles.empty? ? nil : titles.first.text
      unless title.nil?
        title.downcase.gsub(/[^\p{Alnum}\s]/, '').gsub(/^(a|an|the)\s/, '').gsub(/\s/,'')
      end
    end

    def ark(dc_elements)
      arks = dc_elements.select do |e|
        e.name == 'identifier' && e.text.start_with?('http://arks.princeton')
      end
      arks.empty? ? nil : { arks.first.text => [dspace_display_text] }.to_json.to_s
    end

    def online_holding
      "{\"Thesis\":{\"library\":\"Online\", \"location_code\":\"elfthesis\"}}"
    end

    def physical_holding
      {
        'thesis' => {
          'location' => 'Mudd Manuscript Library',
          'library' => 'Mudd Manuscript Library',
          'location_code' => 'mudd',
          'dspace' => true
        }
      }.to_json.to_s
    end

    def non_ark_ids(dc_elements)
      non_ark_ids = dc_elements.select do |e|
        e.name == 'identifier' && !e.text.start_with?('http://arks.princeton')
      end
      unless non_ark_ids.empty?
        return { 'Other identifier' => non_ark_ids.map(&:text) }.to_json.to_s
      end
      nil
    end


    def id(dc_elements)
      arks = dc_elements.select do |e|
        e.name == 'identifier' && e.text.start_with?('http://arks.princeton')
      end
      arks.empty? ? nil : arks.first.text.split('/').last
    end

    def author_sort(dc_elements)
      authors = dc_elements.select { |e| e.name == 'creator' }
      authors.empty? ? nil : authors.first.text
    end

    def build_solr_hash(doc)
      h = {
        'id' => doc['id'],
        'title_t' => title_search_hash(doc['dc.title']),
        'title_citation_display' => first_or_nil(doc['dc.title']),
        'title_display' => first_or_nil(doc['dc.title']),
        'title_sort' => title_sort_hash(doc['dc.title']),
        'author_sort' => first_or_nil(doc['dc.contributor.author']),
        'electronic_access_1display' => ark_hash(doc['dc.identifier.uri']),
        'standard_no_1display' => non_ark_ids_hash(doc['dc.identifier.other']),
        'language_facet' => code_to_language(doc['dc.language.iso'])
      }
      h.merge!(map_rest_non_special_to_solr(doc))
      h.merge!(holdings_access(doc))
      h.merge!(HARD_CODED_TO_ADD)
      h
    end

    def choose_date_hash(doc)
      dates = all_date_elements_hash(doc).map { |k,v| Chronic.parse(v.first) }.compact
      dates.empty? ? nil : dates.min.year
    end

    def all_date_elements_hash(doc)
      doc.select { |k,v| k[/dc\.date/] }
    end

    def title_sort_hash(titles)
      unless titles.nil?
        titles.first.downcase.gsub(/[^\p{Alnum}\s]/, '').gsub(/^(a|an|the)\s/, '').gsub(/\s/,'')
      end
    end

    # Take first title, strip out latex expressions when present to include along
    # with non-normalized version (allowing users to get matches both when LaTex
    # is pasted directly into the search box and when sub/superscripts are placed
    # adjacent to regular characters
    def title_search_hash(titles)
      unless titles.nil?
        title = titles.first
        title.scan(/\\\(.*?\\\)/).each do |latex|
          title = title.gsub(latex, latex.gsub(/[^\p{Alnum}]/, ''))
        end
        title == titles.first ? title : [titles.first, title]
      end
    end

    def ark_hash(arks)
      arks.nil? ? nil : { arks.first => [dspace_display_text] }.to_json.to_s
    end

    def non_ark_ids_hash(non_ark_ids)
      non_ark_ids.nil? ? nil : { 'Other identifier' => non_ark_ids }.to_json.to_s
    end

    def first_or_nil(field)
      field.nil? ? nil : field.first
    end

    def dspace_display_text
      'DataSpace'
    end

    # this is kind of a mess...
    def map_non_special_to_solr(dc_elements)
      h = { }
      NON_SPECIAL_ELEMENT_MAPPING.each do |element_name, fields|
        elements = dc_elements.select { |e| e.name == element_name }
        fields.each do |f|
          if h.has_key?(f)
            h[f].push(*elements.map(&:text))
          else
            h[f] = elements.map(&:text)
          end
        end
      end
      h
    end

    # default English
    def code_to_language(codes)
      languages = []
      unless codes.nil?
        codes.each do |c|
          code_lang = ISO_639.find(c[/^[^_]*/]) # en_US is not valid iso code
          l = code_lang.nil? ? 'English' : code_lang.english_name
          languages << l
        end
      end
      languages.empty? ? 'English' : languages.uniq
    end

    def map_rest_non_special_to_solr(doc)
      h = { }
      REST_NON_SPECIAL_ELEMENT_MAPPING.each do |field_name, solr_fields|
        if doc.has_key?(field_name)
          solr_fields.each do |f|
            val = []
            val << h[f]
            val << doc[field_name]
            h[f] = val.flatten.compact
            # Ruby might have a bug here
            # if h.has_key?(f)
            #   h[f].push(doc[field_name])
            # else
            #   h[f] = doc[field_name]
            # end
          end
        end
      end
      h
    end
    # online access when there isn't a restriction/location note
    def holdings_access(doc)
      if doc.has_key?('pu.location') || doc.has_key?('dc.rights.accessRights')
        {
          'location' => 'Mudd Manuscript Library',
          'location_display' => 'Mudd Manuscript Library',
          'location_code_s' => 'mudd',
          'access_facet' => 'In the Library',
          'holdings_1display' => physical_holding
        }
      else
        {
          'access_facet' => 'Online',
          'holdings_1display' => online_holding
        }
      end
    end
  end
end
