# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in lexorank.gemspec
gemspec

gem "shoulda-context"
gem "activerecord", "~> 7.0.0"
gem "activerecord-jdbcmysql-adapter", "~> 70.0", platforms: :jruby
gem "activerecord-jdbcpostgresql-adapter", "~> 70.0", platforms: :jruby
gem "activerecord-jdbcsqlite3-adapter", "~> 70.0", platforms: :jruby
gem "mysql2", platforms: :ruby
gem "pg", platforms: :ruby
gem "sqlite3", "~> 1.4", platforms: :ruby

# As long as we cannot use Rails 7.1 because of JRuby we need to pin concurrent-ruby
# to work around a require bug in Rails
gem "concurrent-ruby", "< 1.3.5"

# Standard library dependencies needed by Rails 7.0
gem "mutex_m"
gem "bigdecimal"
gem "drb"

gem "m"
gem "minitest"
gem "minitest-reporters"
gem "pry"
gem "rake"
gem "ruboconf", "~> 1.3"
