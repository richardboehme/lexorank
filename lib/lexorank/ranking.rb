# frozen_string_literal: true

class Lexorank::Ranking
  include Lexorank

  attr_reader :record_class, :original_field, :field, :original_group_by, :group_by, :advisory_lock_config

  def initialize(record_class:, field:, group_by:, advisory_lock:)
    @record_class = record_class
    @original_field = field
    @field = process_column_name(field)
    @original_group_by = group_by
    @group_by = process_group_by_column_name(group_by)
    @advisory_lock_config = { enabled: record_class.respond_to?(:with_advisory_lock) }.merge(advisory_lock)
  end

  def validate!
    if advisory_lock_config[:enabled] && !record_class.respond_to?(:with_advisory_lock)
      raise(
        Lexorank::InvalidConfigError,
        "Cannot enable advisory lock if #{record_class.name} does not respond to #with_advisory_lock. " \
        'Consider installing the with_advisory_lock gem (https://rubygems.org/gems/with_advisory_lock).'
      )
    end

    unless @field
      # TODO: Make this raise an error. Supplying an invalid column should raise.
      warn "The supplied ranking column \"#{@original_field}\" is not a column of the model!"
    end

    if original_group_by && !group_by
      warn "The supplied grouping by \"#{original_group_by}\" is neither a column nor an association of the model!"
    end
  end

  def move_to(instance, position)
    if block_given? && advisory_locks_enabled?
      return with_lock_if_enabled(instance) do
        move_to(instance, position)
        yield
      end
    end

    collection = record_class.ranked
    if group_by.present?
      collection = collection.where("#{group_by}": instance.send(group_by))
    end

    # exceptions:
    #   move to the beginning (aka move to position 0)
    #   move to end (aka position = collection.size - 1)
    # when moving to the end of the collection the offset and limit statement automatically handles
    # that 'after' is nil which is the same like [collection.last, nil]
    before, after =
      if position == :last
        [collection.last, nil]
      elsif position.zero?
        [nil, collection.first]
      else
        collection.where.not(id: instance.id).offset(position - 1).limit(2)
      end

    # If position >= collection.size both `before` and `after` will be nil. In this case
    # we set before to the last element of the collection
    if before.nil? && after.nil?
      before = collection.last
    end

    rank =
      if (self == after && send(field).present?) || (before == self && after.nil?)
        send(field)
      else
        value_between(before&.send(field), after&.send(field))
      end

    instance.send(:"#{field}=", rank)

    if block_given?
      yield
    else
      rank
    end
  end

  def with_lock_if_enabled(instance, &block)
    if advisory_locks_enabled?
      advisory_lock_options = advisory_lock_config.except(:enabled, :lock_name)

      record_class.with_advisory_lock(advisory_lock_name(instance), **advisory_lock_options, &block)
    else
      yield
    end
  end

  def advisory_lock_name(instance)
    if advisory_lock_config[:lock_name].present?
      advisory_lock_config[:lock_name].(instance)
    else
      "#{record_class.table_name}_update_#{field}".tap do |name|
        if group_by.present?
          name << "_group_#{instance.send(group_by)}"
        end
      end
    end
  end

  def advisory_locks_enabled?
    record_class.respond_to?(:with_advisory_lock) && advisory_lock_config[:enabled]
  end

  private

  def process_column_name(name)
    return unless name

    # This requires an active connection... do we want this?
    if record_class.columns.map(&:name).include?(name.to_s)
      name
    end
  end

  def process_group_by_column_name(name)
    processed_name = process_column_name(name)

    # This requires rank! to be after the specific association
    if name && !processed_name && (association = record_class.reflect_on_association(name))
      association.foreign_key.to_sym
    else
      processed_name
    end
  end
end
