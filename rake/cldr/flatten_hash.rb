# frozen_string_literal: true

module FlattenHash
  NotHashError = Class.new(StandardError)

  class << self
    def run(hash, output = {}, parent_key = [])
      raise NotHashError unless hash.is_a?(Hash)

      return {} if hash.empty? && parent_key.empty?

      if hash.empty?
        output[parent_key] = hash
      else
        hash.keys.each do |key|
          current_key = parent_key + [key]

          if hash[key].is_a?(Hash)
            run(hash[key], output, current_key)
          else
            output[current_key] = hash[key]
          end
        end
      end

      output
    end
  end
end
