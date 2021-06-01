require 'spec_helper'
require 'rexml/document'

module Orangetheses
  describe Visual do

    def load_fixture(name)
      REXML::Document.new(File.new(fixture_path(name))).root
    end

    def create_element(name, text)
      elem = REXML::Element.new(name)
      elem.text = text
      elem
    end

    let(:fixture) { load_fixture 'visuals.xml' }

    describe '#_select_element' do
      let(:elements) { [
          create_element('format', 'anything'),
          create_element('something', 'else')
        ]
      }
      it 'returns text of matched element' do
        expect(subject.send(:select_element, elements, 'format')).to eq 'anything'
        expect(subject.send(:select_element, elements, 'something')).to eq 'else'
      end
      it 'returns nil when element is not found' do
        expect(subject.send(:select_element, elements, 'blahblah')).to be_nil
      end
    end

    describe '#_id' do
      let(:elements) { [
          create_element('id', 'anything')
        ]
      }
      it 'prepends id element with visuals' do
        expect(subject.send(:id, elements)).to eq('visualsanything')
      end
    end

    describe '#_get_links' do
      let(:elements) { [
          create_element('id', '12345'),
          create_element('link', 'site/title.jpg'),
          create_element('link', 'other.com/url'),
          create_element('colllink', 'finally.org/messy file.pdf')
        ]
      }
      let(:check_links) { [
          create_element('id', '12345'),
          create_element('link', 'http://google.com'),
          create_element('link', 'http://libweb5.princeton.edu/visual_materials/ga/bad link.jpg'),
          create_element('colllink', 'http://libweb5.princeton.edu/visual_materials/ga/new york from brooklyn heights1.jpg')
        ]
      }
      let(:links) { JSON.parse(subject.send(:get_links, elements)) }
      it 'hash includes link elements' do
        dbl = double
        allow(dbl).to receive(:status).and_return(200)
        allow(Faraday).to receive(:get) { dbl }
        expect(links.has_key?('site/title.jpg')).to be true
        expect(links.has_key?('other.com/url')).to be true
      end
      it 'hash includes colllink elements when 301 status' do
        dbl = double
        allow(dbl).to receive(:status).and_return(301)
        allow(Faraday).to receive(:get) { dbl }
        expect(links.has_key?('finally.org/messy file.pdf')).to be true
      end
      it 'display text is filename after last slash with first word capitalized' do
        dbl = double
        allow(dbl).to receive(:status).and_return(200)
        allow(Faraday).to receive(:get) { dbl }
        expect(links.values.flatten.include?('Title.jpg')).to be true
        expect(links.values.flatten.include?('Url')).to be true
        expect(links.values.flatten.include?('Messy file.pdf')).to be true
      end
      it 'excludes links that do not resolve' do
        links = JSON.parse(subject.send(:get_links, check_links))
        expect(links.has_key?('http://google.com')).to be true
      end
    end

    describe '#_related_names' do
      before(:each) { subject.send(:related_names, doc) }
      describe 'with one name' do
        let(:doc) do
          {
            'author_display' => ['Author1']
          }
        end
        it 'author display field unchanged' do
          expect(doc['author_display']).to eq(['Author1'])
        end
        it 'related names field is nil' do
          expect(doc['related_name_json_1display']).to be_nil
        end
      end
      describe 'with few names' do
        let(:doc) do
          {
            'author_display' => ['Author1', 'Related1', 'Related2']
          }
        end
        it 'author display field unchanged' do
          expect(doc['author_display']).to eq(['Author1', 'Related1', 'Related2'])
        end
        it 'related names field is nil' do
          expect(doc['related_name_json_1display']).to be_nil
        end
      end
      describe 'with many names' do
        let(:doc) do
          {
            'author_display' => ['Author1', 'R1', 'R2', 'R3', 'R4']
          }
        end
        it 'author display field only first value' do
          expect(doc['author_display']).to eq(['Author1'])
        end
        it 'contributors in related name field' do
          names = JSON.parse(doc['related_name_json_1display'])['Related name']
          expect(names).to eq(['R1', 'R2', 'R3', 'R4'])
        end
      end
    end

    describe '#_get_locations' do
      let(:locations) { subject.send(:get_locations) }
      it 'hash values contains library info and holding location label' do
        expect(locations['ex'].has_key?('label')).to be true
        expect(locations['ex'].has_key?('library')).to be true
      end
    end

    describe '#_get_library' do
      let(:locations) {
        {
          'ga' =>
          {
            'label' => 'Graphic Arts Collection',
            'code' => 'ga',
            'library' =>
            {
              'label' => 'Rare Books and Special Collections',
              'code'=>'rare'
            }
          }
        }
      }
      it 'returns library label for holding location code' do
        allow(subject).to receive(:get_locations) { locations }
        expect(subject.send(:get_library, 'ga')).to eq(locations['ga']['library']['label'])
      end
    end

    describe '#_location_full_display' do
      let(:locations) {
        {
          'ga' =>
          {
            'label' => 'Graphic Arts Collection',
            'code' => 'ga',
            'library' =>
            {
              'label' => 'Rare Books and Special Collections',
              'code'=>'rare'
            }
          }
        }
      }
      let(:locations_no_label) {
        {
          'nolabel' =>
          {
            'label' => '',
            'code' => 'nolabel',
            'library' =>
            {
              'label' => 'Rare Books and Special Collections',
              'code'=>'rare'
            }
          }
        }
      }
      it 'returns library label plus label when available' do
        allow(subject).to receive(:get_locations) { locations }
        expect(subject.send(:location_full_display, 'ga')).to eq('Rare Books and Special Collections - Graphic Arts Collection')
      end
      it 'returns just library label when no label is available' do
        allow(subject).to receive(:get_locations) { locations_no_label }
        expect(subject.send(:location_full_display, 'nolabel')).to eq(locations_no_label['nolabel']['library']['label'])
      end
    end

    describe '#_access_facet' do
      it 'returns empty array when location_code and links are both nil' do
        expect(subject.send(:access_facet, nil, nil)).to eq []
      end
      it 'returns online when location_code is nil and links is not nil' do
        expect(subject.send(:access_facet, nil, '')).to eq ['Online']
      end
      it 'returns in the library when location_code is not nil and links is nil' do
        expect(subject.send(:access_facet, '', nil)).to eq ['In the Library']
      end
      it 'returns in the library and online when both location_code and links are not nil' do
        expect(subject.send(:access_facet, '', '')).to match_array ['In the Library', 'Online']
      end
    end

    describe '#_get_location_code' do
      let(:elements) {
        REXML::Document.new('<holdings><collection>code</collection></holdings>').to_a
      }
      it 'location code is collection element embedded in holdings' do
        expect(subject.send(:get_location_code, elements)).to eq('code')
      end
    end

    describe '#_choose_date' do
      let(:century) { [
          create_element('year1', '18')
        ]
      }
      let(:catalog_error) { [
          create_element('year1', '8981')
        ]
      }
      let(:catalog_173) { [
          create_element('year1', '173')
        ]
      }
      let(:three_digit) { [
          create_element('year1', '888')
        ]
      }
      let(:four_digit) { [
          create_element('year1', '1888')
        ]
      }
      let(:unknown) { [
          create_element('year1', 'uuuu')
        ]
      }
      let(:no_date) { [
          create_element('blah', 'blah')
        ]
      }
      it 'leaves date alone if 4 digits' do
        expect(subject.send(:choose_date, four_digit)).to eq '1888'
      end
      it 'returns nil if uuuu' do
        expect(subject.send(:choose_date, unknown)).to be_nil
      end
      it 'returns nil if no date' do
        expect(subject.send(:choose_date, no_date)).to be_nil
      end
      it 'pads three digit year to 4 digits' do
        expect(subject.send(:choose_date, three_digit)).to eq '0888'
      end
      it 'special case - catalog error fix' do
        expect(subject.send(:choose_date, catalog_error)).to eq '0898'
      end
      it 'special case - 1730 encoded as 173' do
        expect(subject.send(:choose_date, catalog_173)).to eq '1730'
      end
      it 'converts century to year' do
        expect(subject.send(:choose_date, century)).to eq '1700'
      end
    end

    describe '#_genre' do
      let(:elements) { [
          create_element('genreform', 'uncapitalized genre')
        ]
      }
      it 'capitalizes genreform element' do
        expect(subject.send(:genre, elements)).to eq 'Uncapitalized genre'
      end
    end

    describe '#_title_sort' do
      let(:stop_word) { [
          create_element('title', 'A good title')
        ]
      }
      let(:non_alphanum) { [
          create_element('title', '!!!Woot2!')
        ]
      }
      it 'strips out stop words' do
        expect(subject.send(:title_sort, stop_word)).to eq 'goodtitle'
      end
      it 'strips out non-alphanumeric' do
        expect(subject.send(:title_sort, non_alphanum)).to eq 'woot2'
      end
    end

    describe '#_holdings' do
      let(:elements) { [
          create_element('callno', 'GA 145'),
          create_element('physicallocation', 'Shelf 2B')
        ]
      }
      let(:locations) {
        {
          'ga' =>
          {
            'label' => 'Graphic Arts Collection',
            'code' => 'ga',
            'library' =>
            {
              'label' => 'Rare Books and Special Collections',
              'code'=>'rare'
            }
          }
        }
      }
      describe 'typical holdings' do
        let(:holdings) { JSON.parse(subject.send(:holdings, elements, 'ga')) }
        it 'holding id (key) is visuals' do
          expect(holdings.has_key?('visuals')).to be true
        end
        it 'holding code is provided location code' do
          expect(holdings['visuals']['location_code']).to eq 'ga'
        end
        it 'holding info has dspace set to true' do
          expect(holdings['visuals']['dspace']).to be true
        end
        it 'library label is included for location code' do
        allow(subject).to receive(:get_locations) { locations }
          expect(holdings['visuals']['library']).to eq subject.send(:get_library, 'ga')
        end
        it 'full location label is included for location code' do
        allow(subject).to receive(:get_locations) { locations }
          expect(holdings['visuals']['location']).to eq subject.send(:location_full_display, 'ga')
        end
        it 'Includes a call number field when callno is present' do
          expect(holdings['visuals']['call_number']).to eq 'GA 145'
        end
        it 'Includes a call number browse field when callno is present' do
          expect(holdings['visuals']['call_number_browse']).to eq 'GA 145'
        end
        it 'Includes a location not when physicallocation is present' do
          expect(holdings['visuals']['location_note']).to eq ['Shelf 2B']
        end
      end
      describe 'holdings missing everything' do
        let(:holdings_empty) { JSON.parse(subject.send(:holdings, [], nil)) }
        it 'holding id (key) is visuals' do
          expect(holdings_empty.has_key?('visuals')).to be true
        end
        it 'holding code is elfvisuals when no location code' do
          expect(holdings_empty['visuals']['location_code']).to eq 'elfvisuals'
        end
        it 'holding info has dspace set to true' do
          expect(holdings_empty['visuals']['dspace']).to be true
        end
        it 'library label is online when no location code provided' do
          expect(holdings_empty['visuals']['library']).to eq 'Online'
        end
        it 'full location label is online when no location code provided' do
          expect(holdings_empty['visuals']['location']).to eq 'Online'
        end
        it 'does not include a call number field when callno is missing' do
          expect(holdings_empty['visuals']['call_number']).to be nil
        end
        it 'does not include a call number browse field when callno is missing' do
          expect(holdings_empty['visuals']['call_number_browse']).to be nil
        end
        it 'does not include a location not when physicallocation is missing' do
          expect(holdings_empty['visuals']['location_note']).to be nil
        end
      end
    end

    describe '#_publication' do
      let(:elements) { [
          create_element('imprint', 'London.'),
          create_element('unitdate', '1975')
        ]
      }
      let(:elements_just_date) { [
          create_element('unitdate', '1975')
        ]
      }
      let(:elements_just_imprint) { [
          create_element('imprint', 'london')
        ]
      }
      let(:elements_uncapitalized) { [
          create_element('imprint', 'london press inc'),
          create_element('unitdate', 'd. early 1975')
        ]
      }
      it 'combines imprint and unitdate separated by comma, strips imprint punctuation' do
        expect(subject.send(:publication, elements)).to eq 'London, 1975'
      end
      it 'is just unitdate when imprint is missing' do
        expect(subject.send(:publication, elements_just_date)).to eq '1975'
      end
      it 'is just imprint when unitdate is missing' do
        expect(subject.send(:publication, elements_just_imprint)).to eq 'London'
      end
      it 'capitalizes each word' do
        expect(subject.send(:publication, elements_uncapitalized)).to eq 'London Press Inc, D. Early 1975'
      end
    end

    describe '#subjects_fields' do
      let(:elements) { [
          create_element('subject', 'one--two--three'),
          create_element('subject', 'one--four--five'),
          create_element('subject', 'special')
        ]
      }
      let(:subject_fields) { subject.send(:subjects_fields, elements) }
      let(:subject_display) { subject_fields['subject_display'] }
      let(:subject_facet) { subject_fields['subject_facet'] }
      let(:subject_topic_facet) { subject_fields['subject_topic_facet'] }
      it 'subject_display and subject_facet have the same values' do
        expect(subject_display).to eq(subject_facet)
      end
      it 'subject_topic_facet splits subjects on --' do
        expect(subject_topic_facet).to match_array ['one', 'two', 'three', 'four', 'five', 'special']
      end
      it 'subject_display replaces -- with em dash' do
        expect(subject_display).to match_array ['one—two—three', 'one—four—five', 'special']
      end
    end
  end
end
