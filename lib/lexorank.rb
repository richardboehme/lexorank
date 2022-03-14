# frozen_string_literal: true

require 'lexorank/version'

# Inspired by https://github.com/DevStarSJ/LexoRank/blob/master/lexo_rank.rb licensed under
# MIT License
#
# Copyright (c) 2019 SeokJoon.Yun
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
module Lexorank
  class InvalidRankError < StandardError; end

  MIN_CHAR = '0'
  MAX_CHAR = 'z'

  def value_between(before_, after_)
    before = before_ || MIN_CHAR
    after = after_ || MAX_CHAR

    rank = ''

    (before.length + after.length).times do |i|
      prev_char = get_char(before, i, MIN_CHAR)
      after_char = get_char(after, i, MAX_CHAR)

      if prev_char == after_char
        rank += prev_char
        next
      end

      mid_char = mid(prev_char, after_char)
      if mid_char == prev_char || mid_char == after_char
        rank += prev_char
        next
      end

      rank += mid_char
      break
    end

    # Problem: If we try to get a rank before the character '0' or after 'z' the algorithm would return the same char
    # This first of all breaks a possible unique constraint and of course makes no sense when ordering the items.
    #
    # Thoughts: I think this issue will never happen with the Lexorank::Rankable module
    # Why? Let's look at '0' as a rank:
    # Because the algorithm always chooses the char in between two other chars, '0' can only happen when before is nil and after is '1'
    # In this case the algorithm will return '0U' though. This means there will never be an item with rank '0' which is why this condition
    # should never equal to true.
    #
    # Please report if you have another opinion about that or if you reached the exception! (of course you can force it by using `value_between(nil, '0')`)
    if rank >= after
      raise InvalidRankError,
        'This rank should not be achievable using the Lexorank::Rankable module! ' \
        'Please report to https://github.com/richardboehme/lexorank/issues! ' \
        "The supplied ranks were #{before_.inspect} and #{after_.inspect}. Please include those in the issue description."
    end
    rank
  end

  def mid(prev, after)
    middle_ascii = ((prev.ord + after.ord) / 2).round
    middle_ascii.chr
  end

  def get_char(string, index, default_char)
    index >= string.length ? default_char : string[index]
  end
end
