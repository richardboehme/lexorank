# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'lexorank/version'

Gem::Specification.new do |spec|
  spec.name = 'lexorank'
  spec.version = Lexorank::VERSION
  spec.authors = ['Richard Böhme']
  spec.email = ['richard.boehme1999@gmail.com']

  spec.summary = 'Store order of your models by using lexicographic sorting.'
  spec.homepage = 'https://github.com/richardboehme/lexorank'
  spec.license = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.1.0')

  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir['LICENSE', 'lib/**/*']

  spec.add_dependency 'activerecord'
  spec.add_dependency 'activesupport'
end
