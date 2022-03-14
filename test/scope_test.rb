# frozen_string_literal: true

require 'test_helper'

class ScopeTest < ActiveSupport::TestCase
  should 'filter out nil ranked entries' do
    Page.create
    assert Page.ranked.empty?
  end

  should 'consider direction' do
    page_1, page_2, page_3 = create_sample_pages
    assert_equal [page_1, page_2, page_3], Page.ranked
    assert_equal [page_1, page_2, page_3], Page.ranked(direction: :asc)
    assert_equal [page_3, page_2, page_1], Page.ranked(direction: :desc)
  end

  should 'consider custom ranking column' do
    class Page1 < ActiveRecord::Base
      self.table_name = 'pages'
      rank!(field: :other_ranking_field)
    end
    Page1.create # this one should not be found by the scope
    page_1, page_2, page_3 = create_sample_pages(clazz: Page1)
    assert_equal [page_1, page_2, page_3], Page1.ranked
  end

  # This currently relies on the active record error message
  should 'validate directions' do
    error = assert_raises(ArgumentError) do
      Page.ranked(direction: :foo)
    end
    assert_match 'Direction "foo" is invalid', error.message
  end
end
