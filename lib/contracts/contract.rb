# This is the main Contract class. When you write a new contract, you'll
# write it as:
#
#   Contract [contract names] => return_value
#
# This class also provides useful callbacks and a validation method.
#
# For #make_validator and related logic see file
# lib/contracts/validators.rb
# For #call_with and related logic see file
# lib/contracts/call_with.rb
class Contract < Contracts::Decorator
  extend Contracts::Validators
  include Contracts::CallWith
  extend Contracts::FailureCallback

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

  attr_reader :args_contracts, :ret_contract, :klass, :method
  def initialize(klass, method, *contracts)
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

    # internally we just convert that return value syntax back to an array
    @args_contracts = contracts[0, contracts.size - 1] + contracts[-1].keys
    @ret_contract   = contracts[-1].values[0]

    @args_validators = args_contracts.map do |contract|
      Contract.make_validator(contract)
    end

    @args_contract_index = args_contracts.index do |contract|
      contract.is_a?(Contracts::Args)
    end

    @ret_validator = Contract.make_validator(ret_contract)
    @pattern_match = false

    # == @has_proc_contract
    last_contract      = args_contracts.last
    is_a_proc          = last_contract.is_a?(Class) && (last_contract <= Proc || last_contract <= Method)
    maybe_a_proc       = last_contract.is_a?(Contracts::Maybe) && last_contract.include_proc?
    @has_proc_contract = is_a_proc || maybe_a_proc || last_contract.is_a?(Contracts::Func)

    # ====

    # == @has_options_contract
    last_contract         = args_contracts.last
    penultimate_contract  = args_contracts[-2]
    @has_options_contract = if @has_proc_contract
                              penultimate_contract.is_a?(Hash) || penultimate_contract.is_a?(Contracts::Builtin::KeywordArgs)
                            else
                              last_contract.is_a?(Hash) || last_contract.is_a?(Contracts::Builtin::KeywordArgs)
                            end
    # ===

    @klass  = klass
    @method = method
  end

  def pretty_contract(c)
    return c.name if c.is_a?(Class)
    c.class.name
  end

  def to_s
    args = args_contracts.map { |c| pretty_contract(c) }.join(", ")
    ret  = pretty_contract(ret_contract)
    "#{args} => #{ret}".gsub("Contracts::Builtin::", "")
  end

  def [](*args, &blk)
    call(*args, &blk)
  end

  def call(*args, &blk)
    call_with(nil, *args, &blk)
  end

  # if we specified a proc in the contract but didn't pass one in,
  # it's possible we are going to pass in a block instead. So lets
  # append a nil to the list of args just so it doesn't fail.

  # a better way to handle this might be to take this into account
  # before throwing a "mismatched # of args" error.
  # returns true if it appended nil
  def maybe_append_block!(args, blk)
    return false unless @has_proc_contract && !blk &&
        (@args_contract_index || args.size < args_contracts.size)
    args << nil
    true
  end

  # Same thing for when we have named params but didn't pass any in.
  # returns true if it appended nil
  def maybe_append_options!(args, blk)
    return false unless @has_options_contract
    if @has_proc_contract &&
        (args_contracts[-2].is_a?(Hash) || args_contracts[-2].is_a?(Contracts::Builtin::KeywordArgs)) && !args[-2].is_a?(Hash)
      args.insert(-2, {})
    elsif (args_contracts[-1].is_a?(Hash) || args_contracts[-1].is_a?(Contracts::Builtin::KeywordArgs)) && !args[-1].is_a?(Hash)
      args << {}
    end
    true
  end

  # Used to determine type of failure exception this contract should raise in case of failure
  def failure_exception
    return PatternMatchingError if pattern_match?
    ParamContractError
  end

  # @private
  # Used internally to mark contract as pattern matching contract
  def pattern_match!
    @pattern_match = true
  end

  # Used to determine if contract is a pattern matching contract
  def pattern_match?
    @pattern_match
  end
end
