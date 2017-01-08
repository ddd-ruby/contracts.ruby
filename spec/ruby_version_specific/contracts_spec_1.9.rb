class GenericExample
  Contract C::SplatArgs[String], C::Num => C::ArrayOf[String]
  def splat_then_arg(*vals, n)
    vals.map { |v| v * n }
  end

  if ruby_version <= 1.9
    Contract ({:foo => C::Nat}) => nil
    def nat_test_with_kwarg(a_hash)
    end
  end
end

RSpec.describe "Contracts:" do
  before :all do
    @o = GenericExample.new
  end

  describe "Splat not last (or penultimate to block)" do
    it "should work with arg after splat" do
      expect { @o.splat_then_arg("hello", "world", 3) }.to_not raise_error
    end
  end


  context "Contracts::Args" do
    it "should print deprecation warning when used" do
      expect{
        klass = Class.new do
          include Contracts::Core

          Contract C::Num, C::Args[String] => C::ArrayOf[String]
          def arg_then_splat(n, *vals)
            vals.map { |v| v * n }
          end
        end
      }.to output(Regexp.new("DEPRECATION WARNING")).to_stdout
    end
  end
end
