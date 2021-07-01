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
      if ActiveRecord::VERSION::MAJOR > 5
        ActiveRecord::Base.connection.truncate(table)
      else
        case ActiveRecord::Base.connection.adapter_name.downcase.to_sym
        when :mysql2 || :postgresql
          ActiveRecord::Base.connection.execute("TRUNCATE #{ActiveRecord::Base.connection.quote_table_name(table)}")
        when :sqlite
          ActiveRecord::Base.connection.execute("DELETE FROM #{ActiveRecord::Base.connection.quote_table_name(table)}")
        else
          raise NotImplementedError
        end
      end
    end
  end


  def assert_not(condition)
    assert !condition
  end

  def create_sample_docs(count:, clazz:, create_with: {})
    docs = []
    count.times do
      docs << clazz.create(create_with)
    end

    docs.each_with_index do |doc, index|
      doc.move_to!(index)
    end

    docs
  end

  def create_sample_pages(count: 3, clazz: Page)
    create_sample_docs(count: count, clazz: clazz)
  end
end
