#
#
#
require 'yaml'

module DopCommon
  class PlanParsingError < StandardError
  end

  class Plan
    include Validator
    include HashParser
    include RunOptions

    def initialize(hash)
      @hash = symbolize_keys(hash)
    end

    def validate
      valitdate_shared_options
      log_validation_method('name_valid?')
      log_validation_method('infrastructures_valid?')
      log_validation_method('nodes_valid?')
      log_validation_method('step_sets_valid?')
      log_validation_method('configuration_valid?')
      log_validation_method('credentials_valid?')
      log_validation_method(:hooks_valid?)
      try_validate_obj("Plan: Can't validate the infrastructures part because of a previous error"){infrastructures}
      try_validate_obj("Plan: Can't validate the nodes part because of a previous error"){nodes}
      try_validate_obj("Plan: Can't validate the steps part because of a previous error"){step_sets}
      try_validate_obj("Plan: Can't validate the credentials part because of a previous error"){credentials}
      try_validate_obj("Infrastructure #{name}: Can't validate hooks part because of a previous error") { hooks }
    end

    def name
      @name ||= name_valid? ?
        @hash[:name] : Digest::SHA2.hexdigest(@hash.to_s)
    end

    def infrastructures
      @infrastructures ||= infrastructures_valid? ?
        create_infrastructures : nil
    end

    def nodes
      @nodes ||= nodes_valid? ?
        inflate_nodes : nil
    end

    def step_sets
      @step_sets ||= step_sets_valid? ?
        create_step_sets : []
    end

    def configuration
      @configuration ||= configuration_valid? ?
        DopCommon::Configuration.new(@hash[:configuration]) :
        DopCommon::Configuration.new({})
    end

    def credentials
      @credentials ||= credentials_valid? ?
        create_credentials : {}
    end

    def find_node(name)
      nodes.find{|node| node.name == name}
    end

    def hooks
      @hooks ||= ::DopCommon::Hooks.new(hooks_valid? ? @hash[:hooks] : {})
    end

  private

    def name_valid?
      return false if @hash[:name].nil?
      @hash[:name].kind_of?(String) or
        raise PlanParsingError, 'The plan name has to be a String'
      @hash[:name][/^[\w-]+$/,0] or
        raise PlanParsingError, 'The plan name may only contain letters, numbers and underscores'
    end

    def infrastructures_valid?
      @hash[:infrastructures] or
        raise PlanParsingError, 'Plan: infrastructures hash is missing'
      @hash[:infrastructures].kind_of?(Hash) or
        raise PlanParsingError, 'Plan: infrastructures key has not a hash as value'
      @hash[:infrastructures].any? or
        raise PlanParsingError, 'Plan: infrastructures hash is empty'
    end

    def create_infrastructures
      @hash[:infrastructures].map do |name, hash|
        ::DopCommon::Infrastructure.new(name, hash, {:parsed_credentials => credentials})
      end
    end

    def nodes_valid?
      @hash[:nodes] or
        raise PlanParsingError, 'Plan: nodes hash is missing'
      @hash[:nodes].kind_of?(Hash) or
        raise PlanParsingError, 'Plan: nodes key has not a hash as value'
      @hash[:nodes].any? or
        raise PlanParsingError, 'Plan: nodes hash is empty'
      @hash[:nodes].values.all? { |n| n.kind_of?(Hash) } or
        raise PlanParsingError, 'Plan: nodes must be of hash type'
    end

    def parsed_nodes
      @parsed_nodes ||= @hash[:nodes].map do |name, hash|
        ::DopCommon::Node.new(name.to_s, hash, {
          :parsed_infrastructures => infrastructures,
          :parsed_credentials     => credentials,
          :parsed_hooks           => hooks,
          :parsed_configuration   => configuration,
        })
      end
    end

    def inflate_nodes
      parsed_nodes.map do |node|
        node.inflatable? ? node.inflate : node
      end.flatten
    end

    def step_sets_valid?
      case @hash[:steps]
      when nil then return false #steps can be nil for DOPv only plans
      when Array then return true
      when Hash # multiple step_sets defined
        @hash[:steps].any? or
          raise PlanParsingError, 'Plan: the hash in steps must not be empty'
        @hash[:steps].keys.all?{|k| k.kind_of?(String)} or
          raise PlanParsingError, 'Plan: all the keys in the steps hash have to be strings'
        @hash[:steps].values.all?{|v| v.kind_of?(Array)} or
          raise PlanParsingError, 'Plan: all values in the steps hash have to be arrays'
      else
        raise PlanParsingError, 'Plan: steps key has not a array or hash as value'
      end
      true
    end

    def create_step_sets
      case @hash[:steps]
      when Array
        [::DopCommon::StepSet.new('default', @hash[:steps])]
      when Hash
        @hash[:steps].map do |name, steps|
          ::DopCommon::StepSet.new(name, steps)
        end
      end
    end

    def configuration_valid?
      return false if @hash[:configuration].nil? # configuration hash is optional
      @hash[:configuration].kind_of? Hash or
        raise PlanParsingError, "Plan: 'configuration' key has not a hash as value"
    end

    def credentials_valid?
      return false if @hash[:credentials].nil? # credentials hash is optional
      @hash[:credentials].kind_of? Hash or
        raise PlanParsingError, "Plan: 'credentials' key has not a hash as value"
      @hash[:credentials].keys.all?{|k| k.kind_of?(String) or k.kind_of?(Symbol)} or
        raise PlanParsingError, "Plan: all keys in the 'credentials' hash have to be strings or symbols"
      @hash[:credentials].values.all?{|v| v.kind_of?(Hash)} or
        raise PlanParsingError, "Plan: all values in the 'credentials' hash have to be hashes"
    end

    def hooks_valid?
      return false unless @hash.has_key?(:hooks)
      raise PlanParsingError, "Plan: hooks, if specified, must be a non-empty hash" if
        !@hash[:hooks].kind_of?(Hash) || @hash[:hooks].empty?
      @hash[:hooks].keys.each do |h|
        raise PlanParsingError, "Plan: invalid hook name '#{h}'" unless
          h.to_s =~ /^(pre|post)_(create|update|destroy)_vm$/
      end
      true
    end

    def create_credentials
      Hash[@hash[:credentials].map do |name, hash|
        [name, ::DopCommon::Credential.new(name, hash)]
      end]
    end
  end
end
