require 'rsolr'
require 'rexml/document'
require 'date'
require 'logger'
require 'json'

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

    HARD_CODED_TO_ADD = {
      'language_facet' => 'English'
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

    private

    def build_hash(dc_elements)
      date = choose_date(dc_elements)
      h = {
        'id' => id(dc_elements),
        'title_display' => title(dc_elements),
        'title_sort' => title_sort(dc_elements),
        'author_sort' => author_sort(dc_elements),
        'pub_date_display' => date,
        'pub_date_start_sort' => date,
        'pub_date_end_sort' => date,
        'electronic_access_1display' => ark(dc_elements),
        'standard_no_1display' => non_ark_ids(dc_elements)
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
      dates = all_date_elements(dc_elements).map { |d| Date.parse(d.text) }
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
      arks.empty? ? nil : { arks.first.text => arks.first.text }.to_json.to_s
    end

    def non_ark_ids(dc_elements)
      non_ark_ids = dc_elements.select do |e|
        e.name == 'identifier' && !e.text.start_with?('http://arks.princeton')
      end
      unless non_ark_ids.empty?
        ids = []
        non_ark_ids.map(&:text).each do |n|
          ids << { 'Other Identifier' => n }.to_json.to_s
        end
        return ids
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
      collapse_single_val_arrays(h)
    end

    def collapse_single_val_arrays(h)
      h.each do |k,v|
        h[k] = v.first if v.is_a?(Array) && v.length == 1
      end
      h
    end

  end
end
