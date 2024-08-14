# frozen_string_literal: true

require 'test_helper'

class AdvisoryLockTest < ActiveSupport::TestCase
  should 'raise if model does not respond to #with_advisory_lock and explicitly enabled' do
    error =
      assert_raises Lexorank::InvalidConfigError do
        class Page1 < ActiveRecord::Base
          self.table_name = 'pages'

          rank!(advisory_lock: { enabled: true })
        end
      end

    assert_equal(
      'Cannot enable advisory lock if AdvisoryLockTest::Page1 does not respond to #with_advisory_lock. ' \
      'Consider installing the with_advisory_lock gem (https://rubygems.org/gems/with_advisory_lock).',
      error.message
    )
  end

  should 'disable advisory locks if the model does not respond to #with_advisory_lock' do
    class Page2 < ActiveRecord::Base
      self.table_name = 'pages'

      rank!
    end
    assert_not Page2.lexorank_ranking.advisory_lock_config[:enabled]

    # This should not raise a NoMethodError
    Page2.new.move_to_top!
  end

  should 'enable advisory locks if model responds to #with_advisory_lock' do
    assert Page.lexorank_ranking.advisory_lock_config[:enabled]

    assert_advisory_locked Page do
      Page.new.move_to_top!
    end
  end

  should 'allow arbitrary options passed to #with_advisory_lock' do
    class Page3 < Base
      self.table_name = 'pages'

      rank!(advisory_lock: { foo: 'bar', bar: 1 })
    end

    assert_equal({ enabled: true, foo: 'bar', bar: 1 }, Page3.lexorank_ranking.advisory_lock_config)

    instance = Page3.new
    assert_nil Page3.advisory_locked_with
    instance.move_to_top!
    _name, options = Page3.advisory_locked_with
    assert_equal({ foo: 'bar', bar: 1 }, options)
  end

  should 'be able to overwrite advisory lock name' do
    class Page4 < Base
      self.table_name = 'pages'

      rank!(advisory_lock: { lock_name: ->(instance) { "my_custom_lock_name_#{instance.id}" } })
    end

    instance = Page4.new
    assert_advisory_locked_with Page4, ["my_custom_lock_name_#{instance.id}"] do
      instance.move_to_top!
    end
  end
end
