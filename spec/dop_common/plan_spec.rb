require 'spec_helper'

describe DopCommon::Plan do

  describe '#name' do
    it 'will return a hash if no name is defined' do
      plan = DopCommon::Plan.new({})
      if RUBY_VERSION <= '1.8.7'
        expect(plan.name).to eq 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
      else
        expect(plan.name).to eq '44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a'
      end
    end
    it 'will return the correct value if name is defined' do
      plan = DopCommon::Plan.new({:name => 'myplan'})
      expect(plan.name).to eq 'myplan'
      plan = DopCommon::Plan.new({:name => 'my-plan'})
      expect(plan.name).to eq 'my-plan'
    end
    it 'will throw and exception if the value is not a String' do
      plan = DopCommon::Plan.new({:name => 2})
      expect{plan.name}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw and exception if the value contais illegal chars' do
      plan = DopCommon::Plan.new({:name => 'my(plan'})
      expect{plan.name}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#infrastructures' do
    it 'will throw and exception if the infrastructures key is not defined' do
      plan = DopCommon::Plan.new({})
      expect{plan.infrastructures}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw and exception if the infrastructures value is not a Hash' do
      plan = DopCommon::Plan.new({:infrastructures => 'foo'})
      expect{plan.infrastructures}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw and exception if the infrastructures hash is empty' do
      plan = DopCommon::Plan.new({:infrastructures => {}})
      expect{plan.infrastructures}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#nodes' do
    it 'will return a list of nodes' do
      plan = DopCommon::Plan.new({:infrastructures => {:management => {}}, :nodes => {'mynode{i}.example.com' =>{:range  => '1..10', :digits => 3}}})
      expect(plan.nodes.length).to be 10
      expect(plan.nodes[0].name).to eq 'mynode001.example.com'
      expect(plan.nodes[9].name).to eq 'mynode010.example.com'
    end
    it 'will throw and exception if the nodes key is not defined' do
      plan = DopCommon::Plan.new({})
      expect{plan.nodes}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw and exception if the nodes value is not a Hash' do
      plan = DopCommon::Plan.new({:nodes => 'foo'})
      expect{plan.nodes}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw and exception if the nodes hash is empty' do
      plan = DopCommon::Plan.new({:nodes => {}})
      expect{plan.nodes}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#step_sets' do
    it 'will return an empty array if the steps key is not defined' do
      plan = DopCommon::Plan.new({})
      expect(plan.step_sets).to eq([])
    end
    it 'will return a StepSet object if the stepset is specified correctly' do
      plan = DopCommon::Plan.new({:steps => []})
      expect(plan.step_sets.all?{|s| s.kind_of?(DopCommon::StepSet)}).to be true
      plan = DopCommon::Plan.new({:steps => {'foo' => []}})
      expect(plan.step_sets.all?{|s| s.kind_of?(DopCommon::StepSet)}).to be true
    end
    it 'will throw and exception if the value is not an Array or Hash' do
      plan = DopCommon::Plan.new({:steps => 'foo'})
      expect{plan.step_sets}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw and exception if the hash is empty' do
      plan = DopCommon::Plan.new({:steps => {}})
      expect{plan.step_sets}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw and exception if the hash is invalid' do
      plan = DopCommon::Plan.new({:steps => {2 => {}}})
      expect{plan.step_sets}.to raise_error DopCommon::PlanParsingError
      plan = DopCommon::Plan.new({:steps => {'foo' => 2}})
      expect{plan.step_sets}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#credentials' do
    it 'will return an empty Hash of credentials if nothing is specified' do
      plan = DopCommon::Plan.new({})
      expect(plan.credentials).to eq({})
    end
    it 'will return a Hash of credentials if correctly specified' do
      plan = DopCommon::Plan.new({:credentials => {'test' => {
        :type     => :username_password,
        :username => 'a',
        :password => 'b'
      }}})
      expect(plan.credentials.key?('test')).to be true
      expect(plan.credentials['test']).to be_a ::DopCommon::Credential
    end
    it 'will raise an exception if the the key is not valid' do
      plan = DopCommon::Plan.new({:credentials => {2 => {}}})
      expect{plan.credentials}.to raise_error DopCommon::PlanParsingError
    end
    it 'will raise an exception if the value is not a hash' do
      plan = DopCommon::Plan.new({:credentials => {'test' => 2}})
      expect{plan.credentials}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#hooks' do
    it 'will return hooks object if specified properly' do
      plan = ::DopCommon::Plan.new({})
      expect(plan.hooks).to be_a(::DopCommon::Hooks)
      %w(create update destroy).each do |action|
        %w(pre post).each do |prefix|
          hook_name = "#{prefix}_#{action}_vm"
          plan = ::DopCommon::Plan.new({'hooks' => {hook_name => []}})
          expect(plan.hooks).to be_an_instance_of(::DopCommon::Hooks)
        end
      end
    end
    it 'will raise an error if not specified correctly' do
      plan = ::DopCommon::Plan.new({'hooks' => {}})
      expect { plan.hooks }.to raise_error ::DopCommon::PlanParsingError
      plan = ::DopCommon::Plan.new({'hooks' => {'invalid' => ['/foo/bar/baz']}})
      expect { plan.hooks }.to raise_error ::DopCommon::PlanParsingError
    end
  end
end
