# frozen_string_literal: true

class Lexorank::Ranking
  include Lexorank

  attr_reader :record_class, :field, :group_by, :advisory_lock_config

  def initialize(record_class:, field:, group_by:, advisory_lock:)
    @record_class = record_class
    @field = field
    @group_by = process_group_by_column_name(group_by)
    @advisory_lock_config = { enabled: record_class.respond_to?(:with_advisory_lock) }.merge(advisory_lock)
  end

  def validate!
    if advisory_lock_config[:enabled] && !record_class.respond_to?(:with_advisory_lock)
      raise(
        Lexorank::InvalidConfigError,
        "Cannot enable advisory lock if #{record_class.name} does not respond to #with_advisory_lock. " \
        "Consider installing the with_advisory_lock gem (https://rubygems.org/gems/with_advisory_lock)."
      )
    end

    unless field
      raise(
        Lexorank::InvalidConfigError,
        'The supplied ":field" option cannot be "nil"!'
      )
    end
  end

  def move_to(instance, position, **options)
    if block_given? && advisory_locks_enabled?
      return with_lock_if_enabled(instance, **options.fetch(:advisory_lock, {})) do
        move_to(instance, position, **options)
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

  def with_lock_if_enabled(instance, **options, &)
    if advisory_locks_enabled?
      advisory_lock_options = advisory_lock_config.except(:enabled, :lock_name).merge(options)

      record_class.with_advisory_lock(advisory_lock_name(instance), **advisory_lock_options, &)
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

  def process_group_by_column_name(name)
    # This requires rank! to be after the specific association
    if name && (association = record_class.reflect_on_association(name))
      association.foreign_key.to_sym
    else
      name
    end
  end
end
