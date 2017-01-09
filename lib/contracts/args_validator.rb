module Contracts
  class ArgsValidator
    attr_accessor :splat_args_contract_index, :klass, :method, :contracts, :args_contracts, :args_validators
    def initialize(opts)
      @splat_args_contract_index = opts.fetch(:splat_args_contract_index)
      @klass                     = opts.fetch(:klass)
      @method                    = opts.fetch(:method)
      @contracts                 = opts.fetch(:contracts)
      @args_contracts            = opts.fetch(:args_contracts)
      @args_validators           = opts.fetch(:args_validators)
    end

    # Loop forward validating the arguments up to the splat (if there is one)
    # may change the `args` param
    def validate_args_before_splat!(args)
      (splat_args_contract_index || args.size).times do |i|
        validate!(args, i)
      end
    end

    ## possibilities
    # - splat is last argument,     like: def hello(a, b, *args)
    # - splat is not last argument, like: def hello(*args, n)
    def validate_splat_args_and_after!(args)
      return unless splat_args_contract_index
      from, count = splat_range(args)

      # splat arguments
      args.slice(from, count).each_with_index do |_arg, index|
        arg_index = from + index
        contract  = args_contracts[from]
        validator = args_validators[from]
        validate!(args, arg_index, contract, validator)
      end

      splat_upper_bound = from + count
      return if splat_upper_bound == args.size

      # after splat arguments
      args[splat_upper_bound..-1].each_with_index do |_arg, index|
        arg_index      = splat_upper_bound + index
        contract_index = from + index + 1
        contract       = args_contracts[contract_index]
        validator      = args_validators[contract_index]
        validate!(args, arg_index, contract, validator)
      end
    end

    # string, splat[integer], float
    # - "aom", 2, 3, 4, 5, 0.1        >>> 1, 4
    # - "aom", 2, 0.1                 >>> 1, 1
    # - "aom", 2, 3, 4, 5, 6, 7, 0.1  >>> 1, 6

    # splat[integer]
    # - 2, 3, 4, 5        >>> 0, 4
    # - 2                 >>> 0, 1
    # - 2, 3, 4, 5, 6, 7  >>> 0, 6
    def splat_range(args)
      args_after_splat  = args_contracts.size - (splat_args_contract_index + 1)
      in_splat          = args.size - args_after_splat - splat_args_contract_index

      [splat_args_contract_index, in_splat]
    end

    private

    def validate!(args, index, contract = nil, validator = nil)
      arg       = args[index]
      contract  ||= args_contracts[index]
      validator ||= args_validators[index]
      fail_if_invalid(validator, arg, index + 1, args.size, contract)

      return unless contract.is_a?(Contracts::Func)
      args[index] = Contract.new(klass, arg, *contract.contracts)
    end

    def fail_if_invalid(validator, arg, arg_pos, args_size, contract)
      return if validator && validator.call(arg)
      throw :return, Contracts::CallWith::SILENT_FAILURE unless Contract.failure_callback(
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
