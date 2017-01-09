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

      restore_args!(args, blk, nil_block_appended)
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

    # Restore the args
    # - if we put the block into args for validating
    # - OR if we added a fake nil at the end because a block wasn't passed in.
    def restore_args!(args, blk, nil_block_appended)
      args.slice!(-1) if blk || nil_block_appended
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
      return unless @has_proc_contract && !blk && needs_more_args?(args)
      args << nil
      true
    end

    def needs_more_args?(args)
      is_splat           = splat_args_contract_index
      more_args_expected = args.size < args_contracts.size
      (is_splat || more_args_expected)
    end

    # Explicitly append options={} if Hash contract is present
    # Same thing for when we have named params but didn't pass any in.
    # returns true if it appended {}
    def maybe_append_options!(args, blk)
      return unless @has_options_contract
      return args.insert(-2, {}) if use_penultimate_contract?(args)
      return args.insert(-1, {}) if use_last_contract?(args)
    end

    def use_last_contract?(args)
      return if args[-1].is_a?(Hash)
      kinda_hash?(args_contracts[-1])
    end

    def use_penultimate_contract?(args)
      return if args[-2].is_a?(Hash)
      kinda_hash?(args_contracts[-2])
    end
  end # end CallWith
end
