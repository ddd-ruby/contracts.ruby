module Contracts
  module Core
    def self.included(base)
      common(base)
    end

    def self.extended(base)
      common(base)
    end

    def self.common(base)
      base.extend(MethodDecorators)

      base.instance_eval do
        def functype(funcname)
          contracts = Engine.fetch_from(self).decorated_methods_for(:class_methods, funcname)
          return "No contract for #{self}.#{funcname}" if contracts.nil?
          "#{funcname} :: #{contracts[0]}"
        end
      end

      base.class_eval do
        def functype(funcname)
          contracts = Engine.fetch_from(self.class).decorated_methods_for(:instance_methods, funcname)
          return "No contract for #{self.class}.#{funcname}" if contracts.nil?
          "#{funcname} :: #{contracts[0]}"
        end
      end
    end
  end
end
