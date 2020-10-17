$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'lexorank'

require 'pry'
require 'shoulda-context'
require 'active_record'
require 'minitest/autorun'
require 'minitest/reporters'

Minitest::Reporters.use!([Minitest::Reporters::DefaultReporter.new(color: true)])

db_config = YAML.load_file(File.expand_path("../database.yml", __FILE__)).fetch(ENV["DB"] || "sqlite")
ActiveRecord::Base.establish_connection(db_config)
ActiveRecord::Schema.verbose = false
load 'schema.rb'

require 'models/page'
require 'models/paragraph'

class Minitest::Test
  include Shoulda::Context::DSL


  def teardown
    tables =
      if ActiveRecord::VERSION::MAJOR >= 5
        ActiveRecord::Base.connection.data_sources
      else
        ActiveRecord::Base.connection.tables
      end

    tables.each do |table|
      ActiveRecord::Base.connection.truncate(table)
    end
  end


  def assert_not(condition)
    assert !condition
  end

  def create_sample_pages(count: 3, clazz: Page)
    pages = []
    count.times do
      pages << clazz.create
    end

    pages.each_with_index do |page, index|
      page.move_to!(index)
    end

    pages
  end
end
