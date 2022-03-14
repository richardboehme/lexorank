# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'pry'
require 'active_record'
require 'securerandom'

require 'lexorank'
require 'lexorank/rankable'

db_config = {
  adapter: 'sqlite3',
  database: 'file:benchmarkmemdb?mode=memory&cache=private'
}
ActiveRecord::Base.establish_connection(db_config)
ActiveRecord::Schema.verbose = false

# trying to avoid sqlite caching here
$balanced_table_name = SecureRandom.hex
$unbalanced_table_name = SecureRandom.hex

ActiveRecord::Schema.define do
  create_table $balanced_table_name, force: :cascade do |t|
    t.string 'rank'
    t.index ['rank'], name: 'index_balanceds_on_rank', unique: true
  end

  create_table $unbalanced_table_name, force: :cascade do |t|
    t.string 'rank'
    t.index ['rank'], name: 'index_unbalanceds_on_rank', unique: true
  end
end

class Balanced < ActiveRecord::Base
  self.table_name = $balanced_table_name
  rank!
end

class Unbalanced < ActiveRecord::Base
  self.table_name = $unbalanced_table_name
  rank!
end

count = ARGV[0] ? ARGV[0].to_i : 10_000

ActiveRecord::Base.transaction do
  needed = 1
  count.times do |n|
    needed -= 1

    balanced = Balanced.new
    balanced.move_to(needed)
    balanced.save

    if needed.zero?
      # we need count + 1
      needed = n + 2
    end

    unbalanced = Unbalanced.new
    unbalanced.move_to(n % 2)
    unbalanced.save

    if ((n + 1) % 100).zero?
      puts "created #{n + 1} records"
    end
  end
end

def clear_active_record_cache
  ActiveRecord::Base.connection.query_cache.clear
  Balanced.reset_column_information
  Unbalanced.reset_column_information
end

Benchmark.bmbm do |x|
  x.report('Clear cache #1: ') { clear_active_record_cache }
  x.report('Unbalanced: ') { Unbalanced.ranked.to_a }
  x.report('Clear cache #2: ') { clear_active_record_cache }
  x.report('Balanced: ') { Balanced.ranked.to_a }
end
