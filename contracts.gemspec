require File.expand_path(File.join(__FILE__, "../lib/contracts/version"))

Gem::Specification.new do |s|
  s.name        = "contracts-lite"
  s.version     = Contracts::VERSION
  s.summary     = "Contracts for Ruby. (fork)"
  s.description = "This library provides contracts for Ruby. Contracts let you clearly express how your code behaves, and free you from writing tons of boilerplate, defensive code."
  s.author      = "Aditya Bhargava, Ruslan Gatyatov, Roman Heinrich"
  s.email       = "bluemangroupie@gmail.com"
  s.files       = `git ls-files`.split("\n")
  s.homepage    = "http://github.com/ddd-ruby/contracts.ruby"
  s.license     = "BSD-2-Clause"
end
