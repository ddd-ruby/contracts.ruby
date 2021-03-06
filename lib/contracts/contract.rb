# This is the main Contract class. When you write a new contract, you'll
# write it as:
#
#   Contract [contract names] => return_value
#
# This class also provides useful callbacks and a validation method.
class Contract < Contracts::Decorator
  extend Contracts::Validators
  extend Contracts::FailureCallback
  include Contracts::CallWith

  # Used to verify if an argument satisfies a contract.
  #
  # Takes: an argument and a contract.
  #
  # Returns: a tuple: [Boolean, metadata]. The boolean indicates
  # whether the contract was valid or not. If it wasn't, metadata
  # contains some useful information about the failure.
  def self.valid?(arg, contract)
    make_validator(contract)[arg]
  end

  attr_reader :args_contracts, :ret_contract, :klass, :method, :ret_validator, :args_validators
  def initialize(klass, method, *contracts)
    contracts = correct_ret_only_contract(contracts, method)

    # internally we just convert that return value syntax back to an array
    @args_contracts = contracts[0, contracts.size - 1] + contracts[-1].keys
    @ret_contract   = contracts[-1].values[0]

    determine_has_proc_contract!
    determine_has_options_contract!

    @pattern_match = false
    @klass         = klass
    @method        = method
  end

  def to_s
    "#{args_contracts_to_s} => #{ret_contract_to_s}".gsub!("Contracts::Builtin::", "")
  end

  def [](*args, &blk)
    call(*args, &blk)
  end

  def call(*args, &blk)
    call_with(nil, *args, &blk)
  end

  # mark contract as pattern matching contract
  def pattern_match!
    @pattern_match = true
  end

  # Used to determine if contract is a pattern matching contract
  def pattern_match?
    @pattern_match
  end

  # Used to determine type of failure exception this contract should raise in case of failure
  def failure_exception
    return PatternMatchingError if pattern_match?
    ParamContractError
  end

  private

  # BEFORE
  # [Contracts::Builtin::Num]
  # AFTER:
  # [{nil=>Contracts::Builtin::Num}]
  def correct_ret_only_contract(contracts, method)
    unless contracts.last.is_a?(Hash)
      unless contracts.one?
        raise %{
          It looks like your contract for #{method.name} doesn't have a return
          value. A contract should be written as `Contract arg1, arg2 =>
          return_value`.
        }.strip
      end
      contracts = [nil => contracts[-1]]
    end
    contracts
  end

  def splat_args_contract_index
    @splat_args_contract_index ||= args_contracts.index do |contract|
      contract.is_a?(Contracts::SplatArgs)
    end
  end

  def args_validators
    @args_validators ||= args_contracts.map do |contract|
      Contract.make_validator(contract)
    end
  end

  def ret_validator
    @ret_validator ||= Contract.make_validator(ret_contract)
  end

  def determine_has_proc_contract!
    @has_proc_contract = kinda_proc?(args_contracts.last)
  end

  def determine_has_options_contract!
    relevant_contract     = (@has_proc_contract ? args_contracts[-2] : args_contracts[-1])
    @has_options_contract = kinda_hash?(relevant_contract)
  end

  def args_contracts_to_s
    args_contracts.map { |c| pretty_contract(c) }.join(", ")
  end

  def ret_contract_to_s
    pretty_contract(ret_contract)
  end

  def pretty_contract(c)
    return c.name if c.is_a?(Class)
    c.class.name
  end

  def kinda_hash?(v)
    v.is_a?(Hash) || v.is_a?(Contracts::Builtin::KeywordArgs)
  end

  def kinda_proc?(v)
    is_a_proc        = v.is_a?(Class) && (v <= Proc || v <= Method)
    maybe_a_proc     = v.is_a?(Contracts::Maybe) && v.include_proc?
    is_func_contract = v.is_a?(Contracts::Func)

    (is_a_proc || maybe_a_proc || is_func_contract)
  end
end
