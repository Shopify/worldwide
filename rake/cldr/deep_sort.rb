# frozen_string_literal: true

# Copied from https://github.com/mcrossen/deepsort/blob/786fe3dd35980f028c0842797d25b27e53cd95f8/lib/deepsort.rb
# MIT licensed

# -----
#
# MIT License
#
# Copyright (c) 2016 Mark Crossen
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
#
# -----

module DeepSort
  module DeepSortHash
    def deep_sort(options = {})
      deep_sort_by(options) { |obj| obj }
    end

    def deep_sort!(options = {})
      deep_sort_by!(options) { |obj| obj }
    end

    def deep_sort_by(options = {}, &block)
      hash = map do |key, value|
        [
          if key.respond_to?(:deep_sort_by)
            key.deep_sort_by(options, &block)
          else
            key
          end,

          if value.respond_to?(:deep_sort_by)
            value.deep_sort_by(options, &block)
          else
            value
          end,
        ]
      end

      Hash[options[:hash] == false ? hash : hash.sort_by(&block)]
    end

    def deep_sort_by!(options = {}, &block)
      hash = map do |key, value|
        [
          if key.respond_to?(:deep_sort_by!)
            key.deep_sort_by!(options, &block)
          else
            key
          end,

          if value.respond_to?(:deep_sort_by!)
            value.deep_sort_by!(options, &block)
          else
            value
          end,
        ]
      end
      replace(Hash[options[:hash] == false ? hash : hash.sort_by!(&block)])
    end

    # comparison for hashes is ill-defined. this performs array or string comparison if the normal comparison fails.
    def <=>(other)
      super(other) || to_a <=> other.to_a || to_s <=> other.to_s
    end
  end
end

Hash.send(:include, DeepSort::DeepSortHash)
