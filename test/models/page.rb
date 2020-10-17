require 'lexorank/rankable'

class Page < ActiveRecord::Base
  rank!

  has_many :paragraphs
end
