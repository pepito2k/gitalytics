# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gitalytics/version'

Gem::Specification.new do |spec|
  spec.name        = "gitalytics"
  spec.version     = Gitalytics::VERSION

  spec.authors     = ["Gonzalo Robaina"]
  spec.email       = "gonzalo@robaina.me"

  spec.summary     = "Git Analytics"
  spec.description = "Get usefull analytics from your git log"
  spec.homepage    = "http://gonza.uy/gitalytics"
  spec.license     = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 1.9.3'

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency "color-generator"
end
