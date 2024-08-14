# frozen_string_literal: true

require 'lexorank'
require 'active_support/concern'

module Lexorank::Rankable
  extend ActiveSupport::Concern

  module ClassMethods
    attr_reader :ranking_column, :ranking_group_by, :ranking_advisory_lock_config

    def rank!(field: :rank, group_by: nil, advisory_lock: {})
      @ranking_column = check_column(field)
      @ranking_advisory_lock_config = { enabled: respond_to?(:with_advisory_lock) }.merge(advisory_lock)

      if ranking_advisory_lock_config[:enabled] && !respond_to?(:with_advisory_lock)
        raise Lexorank::InvalidConfigError, "Cannot enable advisory lock if #{name} does not respond to #with_advisory_lock. Consider installing the with_advisory_lock gem (https://rubygems.org/gems/with_advisory_lock)."
      end

      if group_by
        @ranking_group_by = check_column(group_by)
        unless @ranking_group_by
          warn "The supplied grouping by \"#{group_by}\" is neither a column nor an association of the model!"
        end
      end

      if @ranking_column
        scope :ranked, ->(direction: :asc) { where.not("#{field}": nil).order("#{field}": direction) }
        include Lexorank
        include InstanceMethods
      else
        warn "The supplied ranking column \"#{field}\" is not a column of the model!"
      end
    end

    private

    def check_column(column_name)
      return unless column_name

      # This requires an active connection... do we want this?
      if columns.map(&:name).include?(column_name.to_s)
        column_name
      # This requires rank! to be after the specific association
      elsif (association = reflect_on_association(column_name))
        association.foreign_key.to_sym
      end
    end
  end

  module InstanceMethods
    def move_to_top(&block)
      move_to(0, &block)
    end

    def move_to(position)
      if block_given? && lexorank_advisory_locks_enabled?
        advisory_lock_options = self.class.ranking_advisory_lock_config.except(:enabled, :lock_name)

        return self.class.with_advisory_lock(lexorank_advisory_lock_name, **advisory_lock_options) do
          move_to(position)
          yield
        end
      end

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
        if position.zero?
          [nil, collection.first]
        else
          collection.where.not(id: id).offset(position - 1).limit(2)
        end

      # If position >= collection.size both `before` and `after` will be nil. In this case
      # we set before to the last element of the collection
      if before.nil? && after.nil?
        before = collection.last
      end

      rank =
        if (self == after && send(self.class.ranking_column).present?) || (before == self && after.nil?)
          send(self.class.ranking_column)
        else
          value_between(before&.send(self.class.ranking_column), after&.send(self.class.ranking_column))
        end

      send(:"#{self.class.ranking_column}=", rank)

      if block_given?
        yield
      else
        rank
      end
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
      !send(self.class.ranking_column)
    end

    private

    def lexorank_advisory_locks_enabled?
      self.class.respond_to?(:with_advisory_lock) && self.class.ranking_advisory_lock_config[:enabled]
    end

    def lexorank_advisory_lock_name
      if self.class.ranking_advisory_lock_config[:lock_name].present?
        self.class.ranking_advisory_lock_config[:lock_name].(self)
      else
        "#{self.class.table_name}_update_#{self.class.ranking_column}".tap do |name|
          if self.class.ranking_group_by.present?
            name << "_group_#{send(self.class.ranking_group_by)}"
          end
        end
      end
    end
  end
end

ActiveRecord::Base.include Lexorank::Rankable
