# frozen_string_literal: true

class Base < ActiveRecord::Base
  self.abstract_class = true

  class << self
    attr_accessor :advisory_locked_with

    def with_advisory_lock(*args)
      @advisory_locked_with = args
      yield
    end
  end
end
