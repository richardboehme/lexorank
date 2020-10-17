require 'lexorank'
require 'active_support/concern'

module Lexorank::Rankable
  extend ActiveSupport::Concern

  module ClassMethods
    attr_reader :ranking_column, :ranking_group_by

    def rank!(field: :rank, group_by: nil)
      @ranking_column = check_column(field)
      if group_by
        @ranking_group_by = check_column(group_by)
        unless @ranking_group_by
          warn "The supplied grouping by \"#{group_by}\" is neither a column nor an association of the model!"
        end
      end

      if @ranking_column
        self.scope :ranked, ->(direction: :asc) { where.not("#{field}": nil).order("#{field}": direction) }
        self.include Lexorank
        self.include InstanceMethods
      else
        warn "The supplied ranking column \"#{field}\" is not a column of the model!"
      end
    end

    private

    def check_column(column_name)
      return unless column_name
      # This requires an active connection... do we want this?
      if self.columns.map(&:name).include?(column_name.to_s)
        column_name
      # This requires rank! to be after the specific association
      elsif (association = self.reflect_on_association(column_name))
        association.foreign_key.to_sym
      end
    end

  end

  module InstanceMethods
    def move_to_top
      move_to(0)
    end

    def move_to(position)
      collection = self.class.ranked
      if self.class.ranking_group_by.present?
        collection = collection.where("#{self.class.ranking_group_by}": send(self.class.ranking_group_by))
      end

      # exceptions:
      #   move to the beginning (aka move to position 0)
      #   move to end (aka position = collection.size - 1)
      # when moving to the end of the collection the offset and limit statement automatically handles
      # that 'after' is nil which is the same like [collection.last, nil]
      before, after =
        if position == 0
          [nil, collection.first]
        else
          # if item is currently in front of the index we just use position otherwise position - 1
          # if the item has no rank we use position - 1
          position -= 1 if !self.send(self.class.ranking_column) || collection.map(&:id).index(self.id) > position
          collection.offset(position).limit(2)
        end

      rank =
        if self == after && self.send(self.class.ranking_column).present?
          self.send(self.class.ranking_column)
        else
          value_between(before&.send(self.class.ranking_column), after&.send(self.class.ranking_column))
        end

      self.send("#{self.class.ranking_column}=", rank)
    end

    def move_to!(position)
      move_to(position)
      save
    end

    def move_to_top!
      move_to!(0)
    end

  end

end
ActiveRecord::Base.send(:include, Lexorank::Rankable)

