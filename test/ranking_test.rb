# frozen_string_literal: true

require "test_helper"

class RankingTest < Minitest::Test
  should "be able to rank entry" do
    page = Page.create
    assert page.persisted?
    assert_not page.rank

    page.move_to!(0)

    page.reload
    assert page.rank
  end

  should "rank multiple entries" do
    page_1, page_2, page_3 = create_sample_pages

    assert_equal [page_1, page_2, page_3], Page.ranked

    page_1.move_to!(2)
    assert_equal [page_2, page_3, page_1], Page.ranked

    page_3.move_to!(0)
    assert_equal [page_3, page_2, page_1], Page.ranked
  end

  should "move to top" do
    page_1, page_2, page_3 = create_sample_pages

    page_3.move_to_top!
    assert_equal [page_3, page_1, page_2], Page.ranked
  end

  should "move to end" do
    page_1, page_2, page_3 = create_sample_pages

    page_1.move_to_end!
    assert_equal [page_2, page_3, page_1], Page.ranked

    page_2.move_to_end do
      page_2.save
    end
    assert_equal [page_3, page_1, page_2], Page.ranked
  end

  should "move to end even if position is larger than collection" do
    page_1, page_2, page_3 = create_sample_pages

    page_1.move_to!(4)
    assert_equal [page_2, page_3, page_1], Page.ranked

    # stay the same if current page is already last page
    page_1.move_to!(5)
    assert_equal [page_2, page_3, page_1], Page.ranked
  end

  should "be able to use custom ranking column" do
    class Page1 < Base
      self.table_name = "pages"
      rank!(field: :other_ranking_field)
    end

    page = Page1.create
    assert_not page.other_ranking_field
    assert_not page.rank

    page.move_to!(0)

    assert page.other_ranking_field
    assert_not page.rank
  end

  should "report warning if field is nil" do
    error =
      assert_raises Lexorank::InvalidConfigError do
        class Page2 < Base
          self.table_name = "pages"
          rank!(field: nil)
        end
      end
    assert_equal 'The supplied ":field" option cannot be "nil"!', error.message
    assert_not Page2.respond_to?(:ranked)
    assert_not Page2.method_defined?(:move_to)
  end

  should "error out if invalid ranks" do
    Page.create(rank: "0")
    p = Page.create
    error =
      assert_raises Lexorank::InvalidRankError do
        p.move_to_top
      end
    assert_equal(
      "This rank should not be achievable using the Lexorank::Rankable module! " \
      "Please report to https://github.com/richardboehme/lexorank/issues! " \
      'The supplied ranks were nil and "0". Please include those in the issue description.',
      error.message
    )
  end
end
