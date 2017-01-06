require "byebug"

require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/.direnv/"
end
if ENV['CI']=='true'
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require "contracts"
require File.expand_path(File.join(__FILE__, "../support"))
require File.expand_path(File.join(__FILE__, "../fixtures/fixtures"))

RSpec.configure do |config|
  config.pattern = "*.rb"

  # Only load tests with valid syntax in the current Ruby
  [1.9, 2.0, 2.1].each do |ver|
    config.pattern << ",ruby_version_specific/*#{ver}.rb" if ruby_version >= ver
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # # Print the 10 slowest examples and example groups
  # config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  # Unable to use it now
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed

  # Callbacks
  config.after :each do
    ::Contract.restore_failure_callback
  end
end
