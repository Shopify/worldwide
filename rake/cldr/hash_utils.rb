# frozen_string_literal: true

class HashUtils
  class << self
    def to_dotted_hash(hash, cur_key = "")
      hash.each_with_object({}) do |(k, v), ret|
        key = cur_key + k.to_s
        if v.is_a?(Hash)
          ret.merge!(to_dotted_hash(v, key + "."))
        else
          ret[key] = v
        end
      end
    end

    def to_nested_hash(hash)
      ret = {}
      hash.each do |k, v|
        cur_hash = ret
        parts = k.to_s.split(".")
        parts[0..-2].each do |part|
          unless cur_hash[part].is_a?(Hash)
            cur_hash[part] = {}
          end
          cur_hash = cur_hash[part]
        end

        cur_hash[parts[-1]] = v
      end

      ret
    end
  end
end
