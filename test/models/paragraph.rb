# frozen_string_literal: true

require "lexorank/rankable"

class Paragraph < Base
  belongs_to :page

  rank!(group_by: :page)
end
