module Contracts
  module CallWith
    SILENT_FAILURE = "silent_failure".freeze
    def call_with(this, *args, &blk)
      args << blk if blk

      nil_block_appended = maybe_append_block!(args, blk)
      maybe_append_options!(args, blk)

      return if SILENT_FAILURE == catch(:return) do
        args_validator.validate_args_before_splat!(args)
      end

      return if SILENT_FAILURE == catch(:return) do
        args_validator.validate_splat_args_and_after!(args)
      end

      # If we put the block into args for validating, restore the args
      # OR if we added a fake nil at the end because a block wasn't passed in.
      args.slice!(-1) if blk || nil_block_appended
      result = execute_args(this, args, blk)

      validate_result(result)
      verify_invariants!(this)
      wrap_result_if_func(result)
    end

    private

    def args_validator
      @args_validator ||= Contracts::ArgsValidator.new(
        klass: klass,
        method: method,
        contracts: self,
        args_contracts: args_contracts,
        args_validators: args_validators,
        splat_args_contract_index: splat_args_contract_index
      )
    end

    def validate_result(result)
      return if ret_validator.call(result)
      Contract.failure_callback(
        :arg          => result,
        :contract     => ret_contract,
        :class        => klass,
        :method       => method,
        :contracts    => self,
        :return_value => true
      )
    end

    def verify_invariants!(this)
      return unless this.respond_to?(:verify_invariants!)
      this.verify_invariants!(method)
    end

    def wrap_result_if_func(result)
      return result unless ret_contract.is_a?(Contracts::Func)
      Contract.new(klass, result, *ret_contract.contracts)
    end

    def execute_args(this, args, blk)
      # a `call`-able method, like proc, block, lambda
      return method.call(*args, &blk) if method.respond_to?(:call)

      # original method name referrence
      method.send_to(this, *args, &blk)
    end

    # Explicitly append blk=nil if nil != Proc contract violation anticipated
    # if we specified a proc in the contract but didn't pass one in,
    # it's possible we are going to pass in a block instead. So lets
    # append a nil to the list of args just so it doesn't fail.
    #
    # a better way to handle this might be to take this into account
    # before throwing a "mismatched # of args" error.
    # returns true if it appended nil
    def maybe_append_block!(args, blk)
      return false unless @has_proc_contract && !blk &&
          (splat_args_contract_index || args.size < args_contracts.size)
      args << nil
      true
    end

    # Explicitly append options={} if Hash contract is present
    # Same thing for when we have named params but didn't pass any in.
    # returns true if it appended nil
    def maybe_append_options!(args, blk)
      return unless @has_options_contract
      if use_penultimate_contract?(args)
        args.insert(-2, {})
      elsif use_last_contract?(args)
        args << {}
      end
      true
    end

    def use_last_contract?(args)
      kinda_hash?(args_contracts[-1]) && !args[-1].is_a?(Hash)
    end

    def use_penultimate_contract?(args)
      kinda_hash?(args_contracts[-2]) && !args[-2].is_a?(Hash)
    end
  end # end CallWith
end
