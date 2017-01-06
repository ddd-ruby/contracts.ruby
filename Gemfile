source "https://rubygems.org"

gemspec


group :test do
  gem "rspec"
  gem "codecov"
  gem "rubocop", "~> 0.46", :platform => [:ruby_20, :ruby_21, :ruby_22, :ruby_23]
end

group :development do
  gem "method_profiler"
  gem "ruby-prof"
end

group :test, :development do
  gem "byebug", :platform => [:ruby_20, :ruby_21, :ruby_22, :ruby_23]
  gem "rake"
end
