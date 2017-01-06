module Contracts
  module FailureCallback
    # Default implementation of failure_callback. Provided as a block to be able
    # to monkey patch #failure_callback only temporary and then switch it back.
    # First important usage - for specs.
    DEFAULT_FAILURE_CALLBACK = proc do |data|
      msg = Contracts::ErrorFormatters.failure_msg(data)

      # this failed on the return contract
      raise ReturnContractError.new(msg, data) if data[:return_value]

      # this failed for a param contract
      raise data[:contracts].failure_exception.new(msg, data)
    end

    # Callback for when a contract fails. By default it raises
    # an error and prints detailed info about the contract that
    # failed. You can also monkeypatch this callback to do whatever
    # you want...log the error, send you an email, print an error
    # message, etc.
    #
    # Example of monkeypatching:
    #
    #   def Contract.failure_callback(data)
    #     puts "You had an error!"
    #     puts failure_msg(data)
    #     exit
    #   end
    def failure_callback(data, use_pattern_matching = true)
      if data[:contracts].pattern_match? && use_pattern_matching
        return DEFAULT_FAILURE_CALLBACK.call(data)
      end

      fetch_failure_callback.call(data)
    end

    # Used to override failure_callback without monkeypatching.
    #
    # Takes: block parameter, that should accept one argument - data.
    #
    # Example usage:
    #
    #   Contract.override_failure_callback do |data|
    #     puts "You had an error"
    #     puts failure_msg(data)
    #     exit
    #   end
    def override_failure_callback(&blk)
      @failure_callback = blk
    end

    # Used to restore default failure callback
    def restore_failure_callback
      @failure_callback = DEFAULT_FAILURE_CALLBACK
    end

    def fetch_failure_callback
      @failure_callback ||= DEFAULT_FAILURE_CALLBACK
    end
  end
end
