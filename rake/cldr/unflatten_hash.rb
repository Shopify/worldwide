# frozen_string_literal: true

module UnflattenHash
  NotHashError = Class.new(StandardError)

  class << self
    def run(hash)
      raise NotHashError unless hash.is_a?(Hash)

      hashes = hash.map do |keys, value|
        keys_value = [*keys, value]
        keys_value.reverse.inject { |inner_hash, key| { key => inner_hash } }
      end

      hashes.inject({}) do |output, h|
        output.deep_merge!(h)
      end
    end
  end
end
