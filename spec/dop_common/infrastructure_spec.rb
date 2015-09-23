require 'spec_helper'

describe DopCommon::Infrastructure do

  before :all do
    DopCommon.log.level = ::Logger::ERROR
  end

  describe '#type' do
    it 'will set and return the type of infrastructure if specified correctly' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev'})
      expect(infrastructure.type).to eq('rhev')
    end
    it 'will raise an error if the type is unspecified and/or invalid' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {})
      expect { infrastructure.type }.to raise_error ::DopCommon::PlanParsingError
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => {:invalid => 'invalid'}})
      expect { infrastructure.type }.to raise_error ::DopCommon::PlanParsingError
    end
  end
  
  describe '#networks' do
    it 'will set and return networks if specified correctly' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev'})
      expect(infrastructure.networks).to eq({})
      infrastructure = ::DopCommon::Infrastructure.new(
        'dummy',
        {
          'type' => 'rhev',
          'networks' => {
            'net1' => nil,
            'net2' => {'ip_defgw' => '172.17.27.1', 'netmask' => '255.255.255.0'}
          }
        }
      )
      expect(infrastructure.networks['net1']).to be_a ::DopCommon::Network
      expect(infrastructure.networks['net2']).to be_a ::DopCommon::Network
    end
    it 'will raise an error if network specification is invalid' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev', 'networks' => 'invalid'})
      expect { infrastructure.networks }.to raise_error ::DopCommon::PlanParsingError
    end
  end

  describe '#affinity_groups' do
    it 'will set and return affinity groups if specified correctly' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev'})
      expect(infrastructure.affinity_groups).to eq({})
      infrastructure = ::DopCommon::Infrastructure.new(
        'dummy',
        {
          'type' => 'rhev',
          'affinity_groups' => {
            'ag1' => {'positive' => true, 'enforce' => false, 'cluster' => 'cl1'},
            'ag2' => {'positive' => false, 'enforce' => false, 'cluster' => 'cl1'}
          }
        }
      )
      expect(infrastructure.affinity_groups['ag1']).to be_a ::DopCommon::AffinityGroup
      expect(infrastructure.affinity_groups['ag2']).to be_a ::DopCommon::AffinityGroup
    end
    it 'will raise an error in case of invalid specification of affinity groups' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev', 'affinity_groups' => 'invalid'})
      expect { infrastructure.affinity_groups }.to raise_error ::DopCommon::PlanParsingError
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev', 'affinity_groups' => { :invalid => {}}})
      expect { infrastructure.affinity_groups }.to raise_error ::DopCommon::PlanParsingError
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev', 'affinity_groups' => { 'ag1' => 'invalid' }})
      expect { infrastructure.affinity_groups }.to raise_error ::DopCommon::PlanParsingError
    end
  end
end
