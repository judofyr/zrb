require File.expand_path("../lib/zrb/version", __FILE__)

Gem::Specification.new do |s|
  s.name              = "zrb"
  s.version           = ZRB::VERSION.dup
  s.summary           = "Simple template engine"
  s.authors           = ["Magnus Holm"]
  s.email             = ["judofyr@gmail.com"]
  s.homepage          = "https://github.com/judofyr/zrb"
  s.license           = "MIT"
  s.required_ruby_version = ">= 1.9.3"

  s.files = %w'README.md' + Dir['lib/**/*.rb'] + Dir['test/**/*']

  s.add_dependency "tilt"
end
