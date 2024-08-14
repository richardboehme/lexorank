# frozen_string_literal: true

require 'lexorank'
require 'lexorank/ranking'
require 'active_support/concern'

module Lexorank::Rankable
  extend ActiveSupport::Concern

  module ClassMethods
    attr_reader :lexorank_ranking

    def rank!(field: :rank, group_by: nil, advisory_lock: {})
      @lexorank_ranking = Lexorank::Ranking.new(record_class: self, field: field, group_by: group_by, advisory_lock: advisory_lock)
      lexorank_ranking.validate!

      if lexorank_ranking.field
        scope :ranked, ->(direction: :asc) { where.not("#{lexorank_ranking.field}": nil).order("#{lexorank_ranking.field}": direction) }
        include InstanceMethods
      end
    end
  end

  module InstanceMethods
    def move_to_top(&block)
      move_to(0, &block)
    end

    def move_to(position, &block)
      self.class.lexorank_ranking.move_to(self, position, &block)
    end

    def move_to!(position)
      move_to(position) do
        save
      end
    end

    def move_to_top!
      move_to!(0)
    end

    def no_rank?
      !send(self.class.lexorank_ranking.field)
    end
  end
end

ActiveRecord::Base.include Lexorank::Rankable
