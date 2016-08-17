require 'rsolr'
require 'rexml/document'
require 'chronic'
require 'logger'
require 'json'
require 'faraday'
require 'rubygems/package'
require 'zlib'
require 'tmpdir'

module Orangetheses
  class Visual

    VISUALS = 'VisualsResults.tar.gz'
    VISUALS_URL = "http://libweb5.princeton.edu/NewStaff/visuals/#{VISUALS}"
    SEPARATOR = '—'

    ### Unique visual xml elements ###
    # id: solr id 
    # title: title display
    # othertitle: other title field
    # imprint: publication display
    # unitdate: publication display
    # year1: pub year, sometimes centuries or uuuu
    # physdesc: description - size of...
    # note: multivalued
    # acqinfo: acquisitions note
    # creator: author display
    # contributor: experimenting with author display
    # subject: hierarchical, separated by '--'
    # genreform: genre - capitalize first letter
    ### Holdings based stuff ###
    # callno: call number
    # physicallocation: location note
    # link: link to file - can be multivalued
    # colllink: treat the same as link
    # collection: <holdings>: location code ctsn,ex,ga,map,mss,mudd,num,rcpxr,thx,wa,whs
    ######## IGNORE ########
    # designation: identical to callno
    # langcode: zxx - no language content
    # type: always image
    # source: always Visuals
    # year2: only 22 examples, some inconsistencies
    # holdings: assuming single holding
    # item:  <holdings>: assuming single item
    # primoItem: <holdings><item>: callno + physicallocation
    # temdata: <holdings><item>: identical to physical location
    NON_SPECIAL_ELEMENT_MAPPING = {
      'creator' => ['author_display', 'author_s'],
      'contributor' => ['author_display', 'author_s'],
      'physdesc' => ['description_display'],
      'note' => ['notes_display'],
      'acqinfo' => ['source_acquisition_display'],
      'unitdate' => ['pub_date_display'],
      'callno' => ['call_number_display', 'call_number_browse_s']
    }

    HARD_CODED_TO_ADD = {
      'format' => 'Visual material'
    }

    def initialize(solr_server=nil)
      solr_server = 'http://localhost:8888/solr/blacklight-core' if solr_server.nil?
      @tmpdir = Dir.mktmpdir
      @solr = RSolr.connect(url: solr_server)
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::INFO
      @logger.formatter = proc do |severity, datetime, progname, msg|
        time = datetime.strftime("%H:%M:%S")
        "[#{time}] #{severity}: #{msg}\n"
      end
    end

    def process_all_visuals
      get_all_visuals
      Dir["#{@tmpdir}/*.xml"].each { |f| process_visual_file(f) }
    end

    private

    def get_all_visuals
      `curl #{VISUALS_URL} > #{@tmpdir}/#{VISUALS}`
      `tar -zxvf #{@tmpdir}/#{VISUALS} -C #{@tmpdir}`
    end


    def process_visual_file(visual)
      objects = []
      doc = REXML::Document.new(File.new(visual))
      doc.elements.each("*/record") {|v| objects << build_hash(v.elements.to_a)}
      @logger.info("Adding #{visual}")
      @solr.add(objects)
      @solr.commit
      objects
    end

    def build_hash(elements)
      location_code = get_location_code(elements)
      links = get_links(elements)
      h = {
          'id' => id(elements),
          'title_t' => select_element(elements, 'title'),
          'title_citation_display' => select_element(elements, 'title'),
          'title_display' => select_element(elements, 'title'),
          'title_sort' => title_sort(elements),
          'other_title_display' => select_element(elements, 'othertitle'),
          'other_title_index' => select_element(elements, 'othertitle'),
          'author_sort' => select_element(elements, 'creator'),
          'pub_date_start_sort' => choose_date(elements),
          'pub_date_end_sort' => choose_date(elements),
          'pub_created_display' => publication(elements),
          'form_genre_display' => genre(elements),
          'genre_facet' => genre(elements),
          'location_code_s' => location_code,
          'advanced_location_s' => [location_code, get_library(location_code)],
          'location' => get_library(location_code),
          'electronic_access_1display' => links,
          'access_facet' => access_facet(location_code, links),
          'holdings_1display' => holdings(elements, location_code)
      }
      h.merge!(map_non_special_to_solr(elements))
      h.merge!(subjects_fields(elements))
      h.merge!(HARD_CODED_TO_ADD)
      related_names(h)
      h
    end

    def related_names(doc)
      if Array(doc['author_display']).length > 4
        related_names = doc['author_display']
        doc['author_display'] = [related_names.shift]
        doc['related_name_json_1display'] = { 'Related name' => related_names }.to_json.to_s
      end
    end

    def choose_date(elements)
      process_date(select_element(elements, 'year1'))
    end

    # @return 4 digit String or nil if uuuu
    def process_date(year)
      if year.nil?
        nil
      elsif year == '8981'
        '0898'
      elsif year == '173'
        '1730'
      elsif year.length == 2 # century
        (year.to_i-1).to_s + '00'
      elsif year.length == 3
        '0' + year
      elsif year == 'uuuu'
        nil   
      else
        year
      end
    end

    def get_location_code(elements)
      holdings = elements.select { |e| e.name == 'holdings' }
      return nil if holdings.empty?
      locs = holdings.first.elements.select { |e| e.name == 'collection' }
      locs.empty? ? nil : locs.first.text
    end

    def genre(elements)
      titles = elements.select { |e| e.name == 'genreform' }
      titles.empty? ? nil : titles.first.text.capitalize
    end

    def title_sort(elements)
      titles = elements.select { |e| e.name == 'title' }
      title = titles.empty? ? nil : titles.first.text
      unless title.nil?
        title.downcase.gsub(/[^\p{Alnum}\s]/, '').gsub(/^(a|an|the)\s/, '').gsub(/\s/,'')
      end
    end

    def get_links(elements)
      links = elements.select { |e| e.name == 'link' || e.name == 'colllink' }
      working_links = []
      links.each do |link|
        if Faraday.get(URI.escape(link.text)).status == 200
          working_links << link
        else
        @logger.info("#{id(elements)}: Bad link #{link.text}")
        end
      end
      return nil if working_links.empty?
      link_hash = {}
      working_links.each { |l| link_hash[l.text] = [l.text.split('/').last.capitalize] }
      link_hash.to_json.to_s
    end

    def holdings(elements, location_code)
      holdings = {}
      holding_info = {}
      holding_info['location_code'] = location_code || 'elfvisuals'
      cn = select_element(elements, 'callno')
      holding_info['call_number'] = cn unless cn.nil?
      holding_info['call_number_browse'] = cn unless cn.nil?
      loc_note = select_element(elements, 'physicallocation')
      holding_info['location_note'] = [loc_note] unless loc_note.nil?
      if location_code.nil?
        holding_info['library'] = 'Online'
        holding_info['location'] = 'Online'
      else
        holding_info['library'] = get_library(location_code)
        holding_info['location'] = location_full_display(location_code)
      end
      holding_info['dspace'] = true
      holdings['visuals'] = holding_info
      holdings.to_json.to_s
    end

    # joins imprint and unitdate fields
    def publication(elements)
      pub = elements.select { |e| e.name == 'imprint' }
      pub = pub.empty? ? '' : pub.first.text.gsub(/[[:punct:]]$/, '')
      date = elements.select { |e| e.name == 'unitdate' }
      date = date.empty? ? '' : date.first.text
      pubdate = if pub.empty?
        date
      elsif date.empty?
        pub
      else
        "#{pub}, #{date}"
      end
      pubdate.empty? ? nil : pubdate.split.map(&:capitalize).join(' ')
    end

    def id(elements)
      id = elements.select { |e| e.name == 'id' }.first.text
      "visuals#{id}"
    end

    def select_element(elements, field)
      element = elements.select { |e| e.name == field }
      element.empty? ? nil : element.first.text
    end

    def locations
      @locations || get_locations
    end

    def get_locations
      locations = Faraday.get('https://bibdata.princeton.edu/locations/holding_locations.json')
      if locations.status == 200
        @locations = {}
        JSON.parse(locations.body).each do |location|
          @locations[location['code']] = location
        end
      end
      @locations
    end

    def get_library(code)
      locations[code]['library']['label']
    end

    def location_full_display(code)
      locations[code]['label'] == '' ? get_library(code) : get_library(code) + ' - ' + locations[code]['label']
    end

    def access_facet(location_code, links)
      facet = []
      facet << 'In the Library' unless location_code.nil?
      facet << 'Online' unless links.nil?
      facet
    end

    def subjects_fields(elements)
      subjects = elements.select { |e| e.name == 'subject' }
      return {} if subjects.empty?
      full_subjects = []
      split_subjects = []
      subjects.each do |s|
        full_subjects << s.text.gsub('--', SEPARATOR)
        split_subjects << s.text.split('--')
      end
      {
        'subject_facet' => full_subjects,
        'subject_display' => full_subjects,
        'subject_topic_facet' => split_subjects.flatten.uniq
      }
    end

    # this is kind of a mess...
    def map_non_special_to_solr(vis_elements)
      h = { }
      NON_SPECIAL_ELEMENT_MAPPING.each do |element_name, fields|
        elements = vis_elements.select { |e| e.name == element_name }
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
