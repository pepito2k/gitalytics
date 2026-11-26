# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gitalytics/version'

Gem::Specification.new do |spec|
  spec.name        = 'gitalytics'
  spec.version     = Gitalytics::VERSION

  spec.authors     = ['Gonzalo Robaina']
  spec.email       = 'gonzalo@robaina.me'

  spec.summary     = 'Git Analytics'
  spec.description = 'Commit statistics for any git repository, in your terminal or as a self-contained HTML report.'
  spec.homepage    = 'https://github.com/pepito2k/gitalytics'
  spec.license     = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.start_with?('test/', 'docs/', '.') }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.1'
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['changelog_uri']         = 'https://github.com/pepito2k/gitalytics/blob/master/CHANGELOG.md'
  spec.metadata['source_code_uri']       = 'https://github.com/pepito2k/gitalytics'
end
