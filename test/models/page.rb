# frozen_string_literal: true

require 'lexorank/rankable'

class Page < ActiveRecord::Base
  rank!

  has_many :paragraphs
end
