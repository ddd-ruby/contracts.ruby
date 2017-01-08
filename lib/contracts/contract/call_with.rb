module Contracts
  module CallWith
    def call_with(this, *args, &blk)
      args << blk if blk

      # Explicitly append blk=nil if nil != Proc contract violation anticipated
      nil_block_appended = maybe_append_block!(args, blk)

      # Explicitly append options={} if Hash contract is present
      maybe_append_options!(args, blk)

      # Loop forward validating the arguments up to the splat (if there is one)
      (splat_args_contract_index || args.size).times do |i|
        contract  = args_contracts[i]
        arg       = args[i]
        validator = args_validators[i]

        unless validator && validator.call(arg)
          return unless Contract.failure_callback(
            :arg          => arg,
            :contract     => contract,
            :class        => klass,
            :method       => method,
            :contracts    => self,
            :arg_pos      => i+1,
            :total_args   => args.size,
            :return_value => false
          )
        end

        if contract.is_a?(Contracts::Func)
          args[i] = Contract.new(klass, arg, *contract.contracts)
        end
      end

      # If there is a splat loop backwards to the lower index of the splat
      # Once we hit the splat in this direction set its upper index
      # Keep validating but use this upper index to get the splat validator.
      if splat_args_contract_index
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

          unless validator && validator.call(arg)
            return unless Contract.failure_callback(
              :arg          => arg,
              :contract     => contract,
              :class        => klass,
              :method       => method,
              :contracts    => self,
              :arg_pos      => i-1,
              :total_args   => args.size,
              :return_value => false
            )
          end

          if contract.is_a?(Contracts::Func)
            args[args.size - 1 - i] = Contract.new(klass, arg, *contract.contracts)
          end
        end
      end

      # If we put the block into args for validating, restore the args
      # OR if we added a fake nil at the end because a block wasn't passed in.
      args.slice!(-1) if blk || nil_block_appended
      result = if method.respond_to?(:call)
                 # proc, block, lambda, etc
                 method.call(*args, &blk)
               else
                 # original method name referrence
                 method.send_to(this, *args, &blk)
               end

      unless ret_validator.call(result)
        Contract.failure_callback(
          :arg          => result,
          :contract     => ret_contract,
          :class        => klass,
          :method       => method,
          :contracts    => self,
          :return_value => true
        )
      end

      this.verify_invariants!(method) if this.respond_to?(:verify_invariants!)

      if ret_contract.is_a?(Contracts::Func)
        result = Contract.new(klass, result, *ret_contract.contracts)
      end

      result
    end

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
