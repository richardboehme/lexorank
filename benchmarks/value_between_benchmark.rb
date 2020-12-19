$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'pry'
require 'active_record'

require 'lexorank'
require 'lexorank/rankable'

include Lexorank

Benchmark.bmbm do |x|
  x.report("value between two close ranks: ") {
    value_between('a' * 100_000, 'b' * 100_000)
  }
  x.report("value between two more different ranks: ") {
    value_between('0' * 100_000, 'z' * 100_000)
  }
end
