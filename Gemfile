# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in lexorank.gemspec
gemspec

gem 'shoulda-context'
if defined?(JRUBY_VERSION)
  gem 'activerecord-jdbcmysql-adapter'
  gem 'activerecord-jdbcpostgresql-adapter'
  gem 'activerecord-jdbcsqlite3-adapter'
else
  gem 'mysql2'
  gem 'pg'
  gem 'sqlite3', '~> 1.4'
end
gem 'm'
gem 'minitest'
gem 'minitest-reporters'
gem 'pry'
gem 'rake'
gem 'ruboconf', '~> 1.3'
