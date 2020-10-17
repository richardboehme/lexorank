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

  MIN_CHAR = '0'.freeze
  MAX_CHAR = 'z'.freeze

  def value_between(before, after)
    before = before || MIN_CHAR
    after = after || MAX_CHAR

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

    rank >= after ? before : rank
  end

  def mid(prev, after)
    middle_ascii = ((prev.ord + after.ord) / 2).round
    middle_ascii.chr
  end

  def get_char(str, i, default_char)
    i >= str.length ? default_char : str[i]
  end

end
