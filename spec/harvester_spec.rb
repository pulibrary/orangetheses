require 'spec_helper'

module Orangetheses
  describe Harvester do

    let(:another_server) { 'http://example.edu/oai/' }

    # describe '#harvest_all' do
    #   it 'does' do
    #     subject.harvest_all
    #   end
    # end

    describe '#index_all' do
      xit 'does' do
      end
    end

    describe '#_client' do

      let(:headers) { subject.instance_variable_get('@headers') }
      let(:base) { subject.instance_variable_get('@base') }

      describe 'defaults' do

        subject { described_class.new.send(:client) }

        it 'get set for the client' do
          expect(base.to_s).to eq PMH_SERVER
        end

      end

      describe 'overriding defaults' do

        subject { described_class.new(server: another_server).send(:client) }

        it "changes the client's params" do
          expect(base.to_s).to eq another_server
        end

      end

    end

  end
end
