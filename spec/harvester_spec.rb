require 'spec_helper'

module Orangetheses
  describe Harvester do
    describe '#client' do

      let(:headers) { subject.instance_variable_get('@headers') }
      let(:base) { subject.instance_variable_get('@base') }

      describe 'defaults' do
        subject { described_class.new.client }
        it 'has them' do
          expect(headers[:metadataPrefix]).to eq METADATA_PREFIX
          expect(headers[:verb]).to eq 'ListRecords'
          expect(headers[:set]).to eq SET
          expect(base.to_s).to eq PMH_SERVER
        end
      end

      describe 'overriding defaults' do
        subject { described_class.new.client(server: TEST_SERVER) }
        it 'will' do
          expect(headers[:metadataPrefix]).to eq METADATA_PREFIX
          expect(headers[:verb]).to eq 'ListRecords'
          expect(headers[:set]).to eq SET
          expect(base.to_s).to eq TEST_SERVER
        end
      end

    end

  end
end
