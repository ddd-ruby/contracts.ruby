module Contracts
  class ArgsValidator
    attr_accessor :splat_args_contract_index, :klass, :method, :contracts, :args_contracts, :args_validators
    def initialize(splat_args_contract_index:, klass:, method:, contracts:, args_contracts:, args_validators:)
      @splat_args_contract_index = splat_args_contract_index
      @klass                     = klass
      @method                    = method
      @contracts                 = contracts
      @args_contracts            = args_contracts
      @args_validators           = args_validators
    end

    # Loop forward validating the arguments up to the splat (if there is one)
    # may change the `args` param
    def validate_args_before_splat!(args)
      (splat_args_contract_index || args.size).times do |i|
        validate!(args, i)
      end
    end

    # If there is a splat loop backwards to the lower index of the splat
    # Once we hit the splat in this direction set its upper index
    # Keep validating but use this upper index to get the splat validator.

    ## possibilities
    # - splat is last argument,     like: def hello(a, b, *args)
    # - splat is not last argument, like: def hello(*args, n)
    def validate_splat_args_and_after!(args)
      return unless splat_args_contract_index
      splat_upper_index = splat_args_contract_index
      (args.size - splat_args_contract_index).times do |i|
        arg = args[args.size - 1 - i]

        if args_contracts[args_contracts.size - 1 - i].is_a?(Contracts::SplatArgs)
          splat_upper_index = i
        end

        # Each arg after the spat is found must use the splat validator
        j         = i < splat_upper_index ? i : splat_upper_index
        contract  = args_contracts[args_contracts.size - 1 - j]
        validator = args_validators[args_contracts.size - 1 - j]

        fail_if_invalid(validator, arg, i - 1, args.size, contract)

        next unless contract.is_a?(Contracts::Func)
        args[args.size - 1 - i] = Contract.new(klass, arg, *contract.contracts)
      end
    end

    private

    def validate!(args, index)
      arg       = args[index]
      contract  = args_contracts[index]
      validator = args_validators[index]
      fail_if_invalid(validator, arg, index + 1, args.size, contract)

      return unless contract.is_a?(Contracts::Func)
      args[index] = Contract.new(klass, arg, *contract.contracts)
    end

    def fail_if_invalid(validator, arg, arg_pos, args_size, contract)
      return if validator && validator.call(arg)
      throw :return, "silent_failure" unless Contract.failure_callback(
        :arg          => arg,
        :contract     => contract,
        :class        => klass,
        :method       => method,
        :contracts    => contracts,
        :arg_pos      => arg_pos,
        :total_args   => args_size,
        :return_value => false
      )
    end
  end
end
