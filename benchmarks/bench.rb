require "rubygems"
require "bundler"
Bundler.setup
require "contracts"
require "benchmark"
require "method_profiler"
require "ruby-prof"



class Some
  include Contracts::Core
  include Contracts::Builtin

  def add a, b
    a + b
  end

  Contract Num, Num => Num
  def contracts_add a, b
    a + b
  end

  def explicit_add a, b
    fail unless a.is_a?(Numeric)
    fail unless b.is_a?(Numeric)
    c = a + b
    fail unless c.is_a?(Numeric)
    c
  end
end


class Runner
  def benchmark
    some = Some.new
    Benchmark.bm 30 do |x|
      x.report "testing add" do
        1_000_000.times do |_|
          some.add(rand(1000), rand(1000))
        end
      end
      x.report "testing contracts add" do
        1_000_000.times do |_|
          some.contracts_add(rand(1000), rand(1000))
        end
      end
    end
  end

  def profile
    some = Some.new
    profilers = []
    profilers << MethodProfiler.observe(Contract)
    profilers << MethodProfiler.observe(Object)
    profilers << MethodProfiler.observe(Contracts::MethodDecorators)
    profilers << MethodProfiler.observe(Contracts::Decorator)
    profilers << MethodProfiler.observe(Contracts::Support)
    profilers << MethodProfiler.observe(UnboundMethod)
    10_000.times do |_|
      some.contracts_add(rand(1000), rand(1000))
    end
    profilers.each { |p| puts p.report }
  end

  def ruby_prof
    some = Some.new
    RubyProf.start
    100_000.times do |_|
      some.contracts_add(rand(1000), rand(1000))
    end
    result = RubyProf.stop
    printer = RubyProf::FlatPrinter.new(result)
    printer.print(STDOUT)
  end

  def all
    benchmark
    profile
    ruby_prof if ENV["FULL_BENCH"] # takes some time
  end
end


Runner.new.all
