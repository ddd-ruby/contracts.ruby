require "set"
require "contracts/formatters"
require "contracts/builtin_contracts"
require "contracts/decorators"
require "contracts/errors"
require "contracts/error_formatter"
require "contracts/formatters"
require "contracts/invariants"
require "contracts/method_reference"
require "contracts/support"
require "contracts/engine"
require "contracts/method_handler"
require "contracts/core"

require "contracts/contract/call_with"
require "contracts/contract/validators"
require "contracts/contract"

module Contracts
  def self.included(base)
    base.send(:include, Core)
  end

  def self.extended(base)
    base.send(:extend, Core)
  end
end
