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
          create_element('foo', 'bar'),
        ]
      }
      it 'takes the year of the earliest date' do
        expect(subject.send(:choose_date, elements)).to eq 2012
      end
      it 'returns nil if there is not a date' do
        expect(subject.send(:choose_date, no_date_elements)).to be_nil
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

    describe '#_ark' do
      let(:elements) { [
          create_element('identifier', 'http://arks.princeton.edu/ark:/88435/dsp013t945q852'),
          create_element('identifier', '7412'),
          create_element('foo', 'bar')
        ]
      }
      let(:no_ark) { [
          create_element('identifier', '7412'),
          create_element('foo', 'bar')
        ]
      }
      it 'gets the ark if there is one' do
        expect(subject.send(:ark, elements)).to eq 'http://arks.princeton.edu/ark:/88435/dsp013t945q852'
      end
      it 'returns nil if there is not a ark' do
        expect(subject.send(:ark, no_ark)).to be_nil
      end
    end

    describe '#_non_ark_ids' do
      let(:elements) { [
          create_element('identifier', 'http://arks.princeton.edu/ark:/88435/dsp013t945q852'),
          create_element('identifier', '7412'),
          create_element('identifier', 'http://foo.bar'),
          create_element('foo', 'bar')
        ]
      }
      let(:no_identifier) { [
          create_element('baz', 'quux'),
          create_element('foo', 'bar')
        ]
      }
      it 'gets the identifiers if any' do
        expected = ['7412', 'http://foo.bar']
        expect(subject.send(:non_ark_ids, elements)).to eq expected
      end
      it 'returns nil if none' do
        expect(subject.send(:non_ark_ids, no_identifier)).to be_nil
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
        expect(h).to include('description_display' => '125 Pages')
        expect(h).to include('summary_note_display' => 'Soon, I expect. Or later. One of those.')
        expect(h).to include('rights_reproductions_note_display' => 'Come on!')
        expect(h).to include('author_display' => 'Oswald, Clara')
        expect(h).to include('author_sort' => 'Oswald, Clara')
        expect(h).to include('advisor_display' => 'Baker, Tom')
        expect(h).to include('author_s' => ['Oswald, Clara', 'Baker, Tom'])
      end
      it 'but leaves others out' do
        expect(h).to_not have_key('date')
      end
    end

    describe 'hard coded values' do
      it 'are added' do
        h = subject.send(:build_hash, [create_element('date', '2012-07-10')])
        expect(h).to include(Indexer::HARD_CODED_TO_ADD)
      end
    end

    describe 'title_sort' do
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



  end
end
