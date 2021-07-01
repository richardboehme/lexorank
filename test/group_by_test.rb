require 'test_helper'

class GroupByTest < ActiveSupport::TestCase
  should 'group paragraphs by page id and update accordingly' do
    page_1 = Page.create
    paragraphs_1 = create_sample_paragraphs(page_1)

    page_2 = Page.create
    paragraphs_2 = create_sample_paragraphs(page_2)

    assert_equal paragraphs_1, page_1.paragraphs.ranked
    assert_equal paragraphs_2, page_2.paragraphs.ranked

    paragraphs_2.last.move_to!(0)
    assert_equal [paragraphs_2.last, *paragraphs_2[0..1]], page_2.paragraphs.ranked

    paragraphs_1.first.move_to!(2)
    assert_equal paragraphs_1[1..2].push(paragraphs_1.first), page_1.paragraphs.ranked
  end

  should 'resolve attribute names' do
    assert_equal :page_id, GroupedParagraph.ranking_group_by

    class Paragraph2 < ActiveRecord::Base
      self.table_name = "paragraphs"
      belongs_to :page
      rank!(group_by: :page)
    end
    assert_equal :page_id, Paragraph2.ranking_group_by
  end

  should 'warn on invalid ranking field' do
    _, err = capture_io do
      class Paragraph3 < ActiveRecord::Base
        self.table_name = "paragraphs"
        rank!(group_by: :foo)
      end
    end
    assert_equal "The supplied grouping by \"foo\" is neither a column nor an association of the model!\n", err
    assert_nil Paragraph3.ranking_group_by
  end

  describe 'moving to a different group' do
    should 'insert into middle' do
      page1, page2 = create_sample_pages(count: 2)
      paragraph1, paragraph2, paragraph3 = create_sample_paragraphs(page1, clazz: GroupedParagraph)

      new_paragraph = create_sample_paragraphs(page2, count: 1, clazz: GroupedParagraph).first

      new_paragraph.page = page1
      new_paragraph.move_to(2)
      new_paragraph.save!

      expected = [paragraph1, paragraph2, new_paragraph,  paragraph3]
      assert_equal expected, GroupedParagraph.where(page_id: page1.id).ranked
    end

    should 'insert at top' do
      page1, page2 = create_sample_pages(count: 2)
      paragraph1, paragraph2, paragraph3 = create_sample_paragraphs(page1, clazz: GroupedParagraph)

      new_paragraph = create_sample_paragraphs(page2, count: 1, clazz: GroupedParagraph).first

      new_paragraph.page = page1
      new_paragraph.move_to(0)
      new_paragraph.save!

      expected = [new_paragraph, paragraph1, paragraph2,  paragraph3]
      assert_equal expected, GroupedParagraph.where(page_id: page1.id).ranked
    end

    should 'insert at the end' do
      page1, page2 = create_sample_pages(count: 2)
      paragraph1, paragraph2, paragraph3 = create_sample_paragraphs(page1, clazz: GroupedParagraph)

      new_paragraph = create_sample_paragraphs(page2, count: 1, clazz: GroupedParagraph).first

      new_paragraph.page = page1
      new_paragraph.move_to(3)
      new_paragraph.save!

      expected = [paragraph1, paragraph2,  paragraph3, new_paragraph]
      assert_equal expected, GroupedParagraph.where(page_id: page1.id).ranked
    end
  end
end
