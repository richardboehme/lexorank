# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in lexorank.gemspec
gemspec

gem 'shoulda-context'
if defined?(JRUBY_VERSION)
  gem 'activerecord', '~> 7.0.0'
  gem 'activerecord-jdbcmysql-adapter', '~> 70.0', platforms: :jruby
  gem 'activerecord-jdbcpostgresql-adapter', '~> 70.0', platforms: :jruby
  gem 'activerecord-jdbcsqlite3-adapter', '~> 70.0', platforms: :jruby
else
  gem 'mysql2'
  gem 'pg'
  gem 'sqlite3'
end
gem 'm'
gem 'minitest'
gem 'minitest-reporters'
gem 'pry'
gem 'rake'
gem 'ruboconf', '~> 1.3'
