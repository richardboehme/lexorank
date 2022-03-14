# frozen_string_literal: true

class GroupedParagraph < Paragraph
  rank!(group_by: :page_id)
end
