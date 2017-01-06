source "https://rubygems.org"

gemspec

group :test do
  gem "rspec"
  gem "rubocop", "~> 0.46", :platform => [:ruby_20, :ruby_21, :ruby_22, :ruby_23]
  gem "codecov"
end

group :development do
  gem "method_profiler"
  gem "ruby-prof"
end

group :test, :development do
  gem "rake"
  gem "byebug", :platform => [:ruby_20, :ruby_21, :ruby_22, :ruby_23]
end
