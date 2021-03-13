# frozen_string_literal: true

$:.push File.expand_path("../lib", __FILE__)
require 'lexorank/version'

Gem::Specification.new do |spec|
  spec.name = 'lexorank'
  spec.version = Lexorank::VERSION
  spec.authors = ['Richard Böhme']
  spec.email = ['richard.boehme1999@gmail.com']

  spec.summary = 'Store order of your models by using lexicographic sorting.'
  spec.homepage = 'https://github.com/richardboehme/lexorank'
  spec.license = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.files = Dir['LICENSE', 'lib/**/*']

  spec.add_dependency 'activesupport'
  spec.add_dependency 'activerecord'

  spec.add_development_dependency 'shoulda-context'
  if defined?(JRUBY_VERSION)
    spec.add_development_dependency 'activerecord-jdbcsqlite3-adapter'
  else
    spec.add_development_dependency 'sqlite3'
  end
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'minitest-reporters'
  spec.add_development_dependency 'm'
  spec.add_development_dependency 'pry'
end
