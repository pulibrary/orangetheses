require 'spec_helper'
require 'rexml/document'

module Orangetheses
  describe Indexer do

    def load_fixture(name)
      REXML::Document.new(File.new(fixture_path(name))).root
    end

    def create_element(name, text)
      elem = REXML::Element.new(name)
      elem.text = text
      elem
    end

    let(:fixture1) { load_fixture 'f1.xml' }

    let(:doc) do
      {
        "id"=>"dsp01b2773v788",
        "dc.description.abstract"=>["Summary"],
        "dc.contributor"=>["Wolff, Tamsen"],
        "dc.contributor.advisor"=>["Sandberg, Robert"],
        "dc.contributor.author"=>["Clark, Hillary"],
        "dc.date.accessioned"=>["2013-07-11T14:31:58Z"],
        "dc.date.available"=>["2013-07-11T14:31:58Z"],
        "dc.date.created"=>["2013-04-02"],
        "dc.date.issued"=>["2013-07-11"],
        "dc.identifier.uri"=>["http://arks.princeton.edu/ark:/88435/dsp01b2773v788"],
        "dc.format.extent"=>["102 pages"],
        "dc.language.iso"=>["en_US"],
        "dc.title"=>["Dysfunction: A Play in One Act"],
        "dc.type"=>["Princeton University Senior Theses"],
        "pu.date.classyear"=>["2014"],
        "pu.department"=>["Princeton University. Department of English", "Princeton University. Program in Theater"],
        "pu.pdf.coverpage"=>["SeniorThesisCoverPage"],
        "dc.rights.accessRights"=>["Walk-in Access..."]
      }
    end

    let(:dspace) { subject.send(:dataspace) }
    let(:full_text) { subject.send(:full_text) }
    let(:citation) { subject.send(:citation) }

    describe '#_pull_dc_elements' do

      it 'pulls all of the descriptive elements' do
        elems = subject.send(:pull_dc_elements, fixture1)
        expected = %w(title creator contributor description contributor date
          date date date type format identifier identifier language rights)
        expect(elems.map(&:name)).to eq expected
      end

    end

    describe '#_choose_date' do
      let(:elements) { [
          create_element('format', '125 pages'),
          create_element('date', '2013-07-10T17:10:21Z'),
          create_element('date', '2013-07-10T17:10:21Z'),
          create_element('date', '2013-04-03'),
          create_element('date', '2012-07-10')
        ]
      }
      let(:no_date_elements) { [
          create_element('format', '125 pages'),
          create_element('foo', 'bar')
        ]
      }
      let(:just_month_year) { [
          create_element('format', '126 pages'),
          create_element('date', '2013-07-10T17:10:21Z'),
          create_element('date', '2011-06')
        ]
      }
      it 'takes the year of the earliest date' do
        expect(subject.send(:choose_date, elements)).to eq 2012
      end
      it 'returns nil if there is not a date' do
        expect(subject.send(:choose_date, no_date_elements)).to be_nil
      end
      it 'properly processes dates in the YYYY-MM format' do
        expect(subject.send(:choose_date, just_month_year)).to eq 2011
      end
    end

    describe '#_choose_date_hash' do
      let(:elements) { {
        'dc.format' => ['125 pages'],
        'dc.date' => ['2013-07-10T17:10:21Z'],
        'dc.date.issued' => ['2013-07-10T17:10:21Z'],
        'dc.date.created' => ['2013-04-03'],
        'dc.date.availabile' => ['2012-07-10']
      } }
      let(:no_date_elements) { {
        'dc.format' => ['125 pages'],
        'foo' => ['bar']
      } }
      let(:just_month_year) { {
        'dc.format' => ['126 pages'],
        'dc.date' => ['2013-07-10T17:10:21Z'],
        'dc.date.availabile' => ['2011-06']
      } }
      it 'takes the year of the earliest date' do
        expect(subject.send(:choose_date_hash, elements)).to eq 2012
      end
      it 'returns nil if there is not a date' do
        expect(subject.send(:choose_date_hash, no_date_elements)).to be_nil
      end
      it 'properly processes dates in the YYYY-MM format' do
        expect(subject.send(:choose_date_hash, just_month_year)).to eq 2011
      end
    end

    describe '#_title' do
      let(:elements) { [
          create_element('title', 'Baz quux'),
          create_element('date', '2012-07-10')
        ]
      }
      let(:no_title_element) { [
          create_element('format', '125 pages'),
          create_element('foo', 'bar')
        ]
      }
      it 'gets the title if there is one' do
        expect(subject.send(:title, elements)).to eq 'Baz quux'
      end
      it 'returns nil if there is not a title' do
        expect(subject.send(:title, no_title_element)).to be_nil
      end
    end

    describe '#_author_sort' do
      let(:elements) { [
          create_element('creator', 'Beeblebrox, Zaphod'),
          create_element('creator', 'Prefect, Ford'),
          create_element('date', '2012-07-10')
        ]
      }
      let(:no_author_sort_element) { [
          create_element('baz', 'quux'),
          create_element('foo', 'bar')
        ]
      }
      it 'gets exactly one author_sort if there is one' do
        expect(subject.send(:author_sort, elements)).to eq 'Beeblebrox, Zaphod'
      end
      it 'returns nil if there is not a author_sort' do
        expect(subject.send(:author_sort, no_author_sort_element)).to be_nil
      end
    end

    describe '#_first_or_nil' do
      let(:elements) { ['Beeblebrox, Zaphod', 'Prefect, Ford'] }
      let(:no_author_sort_element) { [] }
      it 'gets exactly one author_sort if there is one' do
        expect(subject.send(:first_or_nil, elements)).to eq 'Beeblebrox, Zaphod'
      end
      it 'returns nil if there is not a author_sort' do
        expect(subject.send(:first_or_nil, no_author_sort_element)).to be_nil
      end
    end

    describe '#_ark' do
      let(:elements_full) { [
          create_element('identifier', 'http://arks.princeton.edu/ark:/88435/dsp013t945q852'),
          create_element('identifier', '7412'),
          create_element('foo', 'bar')
        ]
      }
      let(:elements_rights) { [
          create_element('identifier', 'http://arks.princeton.edu/ark:/88435/dsp013t945q852'),
          create_element('identifier', '7412'),
          create_element('rights', 'there are restrictions')
        ]
      }
      let(:no_ark) { [
          create_element('identifier', '7412'),
          create_element('foo', 'bar')
        ]
      }
      it 'gets the ark with full text link display when no rights' do
        ark = "http://arks.princeton.edu/ark:/88435/dsp013t945q852"
        expected = %Q({"#{ark}":["#{dspace}","#{full_text}"]})
        expect(subject.send(:ark, elements_full)).to eq expected
      end
      it 'gets the ark with citation link display when rights' do
        ark = "http://arks.princeton.edu/ark:/88435/dsp013t945q852"
        expected = %Q({"#{ark}":["#{dspace}","#{citation}"]})
        expect(subject.send(:ark, elements_rights)).to eq expected
      end
      it 'returns nil if there is not a ark' do
        expect(subject.send(:ark, no_ark)).to be_nil
      end
    end

    describe '#_on_site_only?' do
      let(:doc_embargo_terms) { { 'pu.embargo.terms' => ['2100-01-01'] } }
      let(:doc_embargo_lift) { { 'pu.embargo.lift' => ['2100-01-01'] } }
      let(:doc_embargo_lift_past) { { 'pu.embargo.lift' => ['2000-01-01'] } }
      let(:doc_past_embargo_walkin) { { 'pu.embargo.lift' => ['2000-01-01'], 'pu.mudd.walkin' => ['yes'] } }
      let(:doc_location) { { 'pu.location' => ['physical location'] } }
      let(:doc_restriction) { doc }
      let(:doc_nothing) { {} }

      it 'doc with embargo terms field returns true' do
        expect(subject.send(:on_site_only?, doc_embargo_terms)).to be true
      end
      it 'doc with embargo lift field returns true' do
        expect(subject.send(:on_site_only?, doc_embargo_lift)).to be true
      end
      it 'doc with expired embargo lift field returns false' do
        expect(subject.send(:on_site_only?, doc_embargo_lift_past)).to be false
      end
      it 'doc with walkin value of yes returns true' do
        expect(subject.send(:on_site_only?, doc_past_embargo_walkin)).to be true
      end
      it 'doc with location field returns true' do
        expect(subject.send(:on_site_only?, doc_location)).to be true
      end
      it 'doc with restrictions field returns true' do
        expect(subject.send(:on_site_only?, doc_restriction)).to be true
      end
      it 'doc with no access-related fields returns false' do
        expect(subject.send(:on_site_only?, doc_nothing)).to be false
      end
    end

    describe '#_restrictions_display_text' do
      let(:doc_no_embargo) { {} }
      let(:doc_walkin_restriction_note) { { 'id' => '123', 'pu.location' => ['restriction'], 'pu.mudd.walkin' => ['yes'] } }
      let(:doc_no_valid_date) { { 'id' => '123', 'pu.embargo.lift' => ['never'] } }
      let(:doc_lift_date) { { 'id' => '123456', 'pu.embargo.lift' => ['2100-07-01'] } }
      let(:doc_lift_date_past) { { 'id' => '123456', 'pu.embargo.lift' => ['2010-07-01'] } }
      let(:doc_past_embargo_walkin) { { 'id' => '123456', 'pu.embargo.lift' => ['2010-07-01'], 'pu.mudd.walkin' => ['yes'] } }

      it 'returns nil for doc without embargo field' do
        expect(subject.send(:restrictions_display_text, doc_no_embargo)).to be nil
      end
      it 'returns restrction note for embargoed doc with invalid date' do
        expect(subject.send(:restrictions_display_text, doc_no_valid_date)).to be nil
      end
      it 'returns valid formatted embargo date in restriction note' do
        expect(subject.send(:restrictions_display_text, doc_lift_date_past)).to be nil
      end
      it 'returns walk-in access note for lifted embargoes with walk-in property' do
        expect(subject.send(:restrictions_display_text, doc_past_embargo_walkin)).to include('Walk-in Access.')
      end
      it 'returns valid formatted embargo date in restriction note' do
        expect(subject.send(:restrictions_display_text, doc_lift_date)).to include('July 1, 2100')
      end
      it 'restriction note email subject includes embargoed doc id' do
        expect(subject.send(:restrictions_display_text, doc_lift_date)).to include('123456')
      end
      it 'display specific restriction note instead when present when doc is walk-in' do
        expect(subject.send(:restrictions_display_text, doc_walkin_restriction_note)).to eq ['restriction']
      end
    end

    describe '#_embargo' do
      let(:doc_no_embargo) { {} }
      let(:doc_no_valid_date) { { 'pu.embargo.lift' => ['never'] } }
      let(:doc_lift_date) { { 'pu.embargo.lift' => ['2017-07-01'] } }
      let(:doc_terms_date) { { 'pu.embargo.terms' => ['2100-01-01'] } }

      it 'returns nil for doc without embargo field' do
        expect(subject.send(:embargo, doc_no_embargo)).to be nil
      end
      it 'returns nil for doc with invalid date' do
        expect(subject.send(:embargo, doc_no_valid_date)).to be nil
      end
      it 'returns formatted embargo date' do
        expect(subject.send(:embargo, doc_lift_date)).to eq('July 1, 2017')
      end
      it 'picks up embargo terms value when lift value not present' do
        expect(subject.send(:embargo, doc_terms_date)).to eq('January 1, 2100')
      end
    end

    describe '#_embargo?' do
      let(:doc_no_embargo) { {} }
      let(:doc_no_valid_date) { { 'pu.embargo.lift' => ['never'] } }
      let(:doc_lift_date) { { 'pu.embargo.lift' => ['2014-07-01'] } }
      let(:doc_terms_date) { { 'pu.embargo.terms' => ['2100-01-01'] } }

      it 'returns false for doc without embargo field' do
        expect(subject.send(:embargo?, doc_no_embargo)).to be false
      end
      it 'returns false for doc with invalid date' do
        expect(subject.send(:embargo?, doc_no_valid_date)).to be false
      end
      it 'returns false if embargo date in past' do
        expect(subject.send(:embargo?, doc_lift_date)).to be false
      end
      it 'returns true if embargo date is in future' do
        expect(subject.send(:embargo?, doc_terms_date)).to be true
      end
    end

    describe '#_call_number' do
      let(:doc_no_id) { nil }
      let(:doc_id) { ['123'] }
      it 'when other identifier not present returns AC102' do
        expect(subject.send(:call_number, doc_no_id)).to eq('AC102')
      end
      it 'when other identifier present appends id to AC102' do
        expect(subject.send(:call_number, doc_id)).to eq('AC102 123')
      end
    end


    describe '#_ark_hash' do
      let(:ark_doc_citation) { doc }
      let(:ark_doc_full_text) {
        doc.delete('dc.rights.accessRights')
        doc
      }
      let(:no_ark) {
        doc.delete('dc.identifier.uri')
        doc
      }
      it 'gets the ark with citation link display when restrctions' do
        ark = ark_doc_citation['dc.identifier.uri'].first
        expected = %Q({"#{ark}":["#{dspace}","#{citation}"]})
        expect(subject.send(:ark_hash, ark_doc_citation)).to eq expected
      end
      it 'gets the ark with full text link display when no restrctions' do
        ark = ark_doc_full_text['dc.identifier.uri'].first
        expected = %Q({"#{ark}":["#{dspace}","#{full_text}"]})
        expect(subject.send(:ark_hash, ark_doc_full_text)).to eq expected
      end
      it 'returns nil if there is not a ark' do
        expect(subject.send(:ark_hash, no_ark)).to be_nil
      end
    end

    describe '#_map_non_special_to_solr' do
      let(:elements) { [
          create_element('date', '2012-07-10'),
          create_element('description', 'Soon, I expect. Or later. One of those.'),
          create_element('creator', 'Oswald, Clara'),
          create_element('contributor', 'Baker, Tom'),
          create_element('format', '125 Pages'),
          create_element('rights', 'Come on!')
        ]
      }
      let(:h) { subject.send(:map_non_special_to_solr, elements) }
      it 'adds the expected keys' do
        expect(h).to include('description_display' => ['125 Pages'])
        expect(h).to include('summary_note_display' => ['Soon, I expect. Or later. One of those.'])
        expect(h).to include('rights_reproductions_note_display' => ['Come on!'])
        expect(h).to include('author_display' => ['Oswald, Clara'])
        expect(h).to include('advisor_display' => ['Baker, Tom'])
        expect(h).to include('author_s' => ['Oswald, Clara', 'Baker, Tom'])
      end
      it 'but leaves others out' do
        expect(h).to_not have_key('date')
      end
    end

    describe 'LaTex normalization' do
      it 'strips out all non alpha-numeric in LaTex expressions' do
        latex = '2D \\(^{1}\\)H-\\(^{14}\\)N HSQC inverse-detection experiments'
        title_search = subject.send(:title_search_hash, [latex])
        expect(title_search).to include(latex)
        expect(title_search).to include('2D 1H-14N HSQC inverse-detection experiments')
      end
    end

    describe '#_map_rest_non_special_to_solr' do
      let(:h) { subject.send(:map_rest_non_special_to_solr, doc) }
      it 'adds the expected keys' do
        expect(h).to include('author_display' => doc['dc.contributor.author'])
        author_facet = [doc['dc.contributor.author'], doc['dc.contributor'],
                        doc['dc.contributor.advisor'], doc['pu.department']].flatten
        expect(h['author_s']).to match_array(author_facet)
        expect(h).to include('summary_note_display' => doc['dc.description.abstract'])
      end
      it 'but leaves others out' do
        expect(h).to_not have_key('id')
      end
    end

    describe 'hard coded values' do
      it 'are added' do
        h = subject.send(:build_hash, [create_element('date', '2012-07-10')])
        expect(h).to include(Indexer::HARD_CODED_TO_ADD)
      end
    end

    describe '#_title_sort' do
      let(:with_punct) { [ create_element('title', '"Some quote" : Blah blah') ] }
      let(:with_article) { [ create_element('title', 'A title : blah blah') ] }
      let(:with_punct_and_article) { [ create_element('title', '"A quote" : blah blah') ] }
      let(:not_an_article) { [ create_element('title', 'thesis') ] }
      it 'strips punctuation' do
        expected = 'somequoteblahblah'
        expect(subject.send(:title_sort, with_punct)).to eq expected
      end
      it 'strips articles' do
        expected = 'titleblahblah'
        expect(subject.send(:title_sort, with_article)).to eq expected
      end
      it 'strips punctuation and articles' do
        expected = 'quoteblahblah'
        expect(subject.send(:title_sort, with_punct_and_article)).to eq expected
      end
      it 'leaves words that start with articles alone' do
        expected = 'thesis'
        expect(subject.send(:title_sort, not_an_article)).to eq expected
      end
    end

    describe '#_title_sort_hash' do
      let(:with_punct) { ['"Some quote" : Blah blah'] }
      let(:with_article) { ['A title : blah blah'] }
      let(:with_punct_and_article) { ['"A quote" : blah blah'] }
      let(:not_an_article) { ['thesis'] }
      it 'strips punctuation' do
        expected = 'somequoteblahblah'
        expect(subject.send(:title_sort_hash, with_punct)).to eq expected
      end
      it 'strips articles' do
        expected = 'titleblahblah'
        expect(subject.send(:title_sort_hash, with_article)).to eq expected
      end
      it 'strips punctuation and articles' do
        expected = 'quoteblahblah'
        expect(subject.send(:title_sort_hash, with_punct_and_article)).to eq expected
      end
      it 'leaves words that start with articles alone' do
        expected = 'thesis'
        expect(subject.send(:title_sort_hash, not_an_article)).to eq expected
      end
    end

    describe '#_class_year_fields' do
      let(:class_year) { ["2014"] }
      let(:doc_int) { { "pu.date.classyear" => class_year } }
      let(:doc_no_int) { { "pu.date.classyear" => ["Undated"] } }
      let(:doc_no_field) { {} }
      it 'returns empty hash when no integer in classyear field' do
        expect(subject.send(:class_year_fields, doc_no_int)).to eq({})
      end
      it 'returns empty hash when no classyear field' do
        expect(subject.send(:class_year_fields, doc_no_field)).to eq({})
      end
      it 'returns hash with class year as value for year fields' do
        expect(subject.send(:class_year_fields, doc_int)['class_year_s']).to eq(class_year)
        expect(subject.send(:class_year_fields, doc_int)['pub_date_start_sort']).to eq(class_year)
        expect(subject.send(:class_year_fields, doc_int)['pub_date_end_sort']).to eq(class_year)
      end
    end

    describe '#_holdings_access' do
      let(:doc_restrictions) { doc }
      let(:doc_embargo) { doc.merge('pu.embargo.terms' => ['2100-01-01']) }
      let(:doc_no_restrictions) { {} }
      let(:online_holding) { JSON.parse(subject.send(:online_holding, doc_no_restrictions)) }
      let(:physical_holding) { JSON.parse(subject.send(:physical_holding, doc_restrictions)) }
      let(:embargo_holding) { JSON.parse(subject.send(:physical_holding, doc_embargo, accessible: false)) }
      describe 'in the library' do
        it 'in the library access for record with restrictions note' do
          expect(subject.send(:holdings_access, doc_restrictions)['access_facet']).to eq('In the Library')
        end
        it 'includes mudd as an advanced location value' do
          expect(subject.send(:holdings_access, doc_restrictions)['advanced_location_s']).to include('Mudd Manuscript Library')
        end
        it 'holdings include call number' do
          expect(physical_holding['thesis'].has_key?('call_number')).to be true
        end
        it 'holdings include call number browse' do
          expect(physical_holding['thesis'].has_key?('call_number_browse')).to be true
        end
        it 'holdings dspace value is true' do
          expect(physical_holding['thesis']['dspace']).to be true
        end
      end
      describe 'embargo' do
        it 'in the library access for record with restrictions note' do
          expect(subject.send(:holdings_access, doc_embargo)['access_facet']).to be_nil
        end
        it 'includes mudd as an advanced location value' do
          expect(subject.send(:holdings_access, doc_embargo)['advanced_location_s']).to include('Mudd Manuscript Library')
        end
        it 'holdings include call number' do
          expect(embargo_holding['thesis'].has_key?('call_number_browse')).to be true
        end
        it 'holdings dspace value is true' do
          expect(embargo_holding['thesis']['dspace']).to be false
        end
      end
      # Alma update
      describe 'online' do
        it 'online access for record without restrictions note' do
          expect(subject.send(:holdings_access, doc_no_restrictions)['access_facet']).to eq('Online')
        end
        it 'electronic portfolio field' do
          expect(subject.send(:holdings_access, doc_no_restrictions)['electronic_portfolio_s']).to include('thesis')
        end
        it 'holdings include call number' do
          expect(online_holding['thesis'].has_key?('call_number')).to be true
        end
        it 'holdings include call number browse' do
          expect(online_holding['thesis'].has_key?('call_number_browse')).to be true
        end
      end
    end

    describe '#_code_to_language' do
      it 'defaults to English when no dc.language.iso field' do
        expect(subject.send(:code_to_language, nil)).to eq 'English'
      end

      it 'maps valid language code to standard language name' do
        expect(subject.send(:code_to_language, ['fr'])).to include 'French'
      end

      it 'supports multiple language codes' do
        expect(subject.send(:code_to_language, ['el', 'it'])).to include('Greek, Modern (1453-)', 'Italian')
      end

      it 'dedups' do
        expect(subject.send(:code_to_language, ['en_US', 'en'])).to eq ['English']
      end
    end
  end
end
