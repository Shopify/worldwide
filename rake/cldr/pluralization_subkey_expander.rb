# frozen_string_literal: true

require "yaml"

class PluralizationSubkeyExpander
  ORDINAL_PLURALIZATION_CONTEXT_INDICATOR = "ordinal"

  class MissingOtherKey < StandardError; end

  class << self
    def expand_file(filename, locale, output_filename: nil)
      output_filename ||= begin
        extension = File.extname(filename)
        File.join(File.dirname(filename), "#{File.basename(filename, extension)}_expanded#{extension}")
      end

      translations = YAML.load(File.read(filename), permitted_classes: [Symbol])
      expanded = expand(translations, locale)

      File.write(output_filename, YAML.dump(expanded)) if translations != expanded
    end

    def expand(translations, locale)
      translations = FlattenHash.run(translations)

      parents_of_leaves = translations.group_by do |key, _value|
        key[0...-1]
      end

      parents_and_children = parents_of_leaves.transform_values do |child_translations|
        child_translations.to_h { |child_key, child_value| [child_key.last, child_value] }
      end

      expanded_translations = parents_and_children.each do |parent, children|
        expand_pluralization_children!(parent, children, locale) if cardinal_pluralization_context?(parent, children, locale)
      end

      result = expanded_translations.flat_map do |parent, children|
        children.map { |child_key, child_value| [parent + [child_key], child_value] }
      end.to_h

      UnflattenHash.run(result)
    end

    private

    def cardinal_pluralization_context?(parent, children, locale)
      # We are in a cardinal pluralization context if any of the children are valid
      # pluralization keys for the language. We can do this only
      # because we have declared cardinal pluralization keys to be reserved keywords.
      #
      # There is an exception: When the parent is `ordinal`, since the ordinal
      # pluralization keywords collide with the cardinal pluralization keywords.
      required_keys_for_locale = Worldwide::Plurals.keys(locale).map(&:to_s)
      !ordinal_pluralization_context?(parent) &&
        (required_keys_for_locale & children.keys).present?
    end

    def ordinal_pluralization_context?(parent)
      parent[-1] == ORDINAL_PLURALIZATION_CONTEXT_INDICATOR
    end

    def expand_pluralization_children!(parent, children, locale)
      required_keys_for_locale = Worldwide::Plurals.keys(locale).map(&:to_s)
      missing_keys = (required_keys_for_locale - children.keys).sort
      if missing_keys.present?
        missing_keys.each do |missing_key|
          new_value = value_from_parent_locale(locale, parent + [missing_key]) ||
            value_from_siblings(locale, missing_key, children)
          children[missing_key] = new_value
        end
      end
      children
    end

    # Fallback through the other parent locales that are "the same language"
    # e.g., `se-FI` will check `se`, but not `root` (next in fallback chain) nor `en` (via custom_exception_handler)
    def value_from_parent_locale(locale, missing_key)
      missing_key = missing_key[1..] if missing_key.first == locale.to_s

      parts = locale.to_s.split("-")
      fallback_chain = Worldwide::Cldr.fallbacks[locale].drop(1).select { |fb| fb.to_s.start_with?(parts[0]) }

      fallback_chain.find do |fb|
        value = I18n.t(missing_key.join("."), locale: fb, exception_handler: proc {}, fallback: false)
        break value if value
      end
    end

    def value_from_siblings(locale, missing_key, siblings)
      required_keys_for_locale = Worldwide::Plurals.keys(locale).map(&:to_s)
      found_keys = (required_keys_for_locale & siblings.keys).sort
      priority_copy_order = plural_key_fallback_priority(locale)
      key_to_copy = found_keys.sort_by { |key| priority_copy_order.index(key) || -1 }.last
      siblings.fetch(key_to_copy)
    end

    # Given a locale and a missing pluralization key, which pluralization keys are most likely to
    # produce a grammatically correct string if we were to copy their value?
    # i.e., which pluralization key should we use fall back to if we are missing one?
    # Note: this is only a question for languages with at least 3 pluralization keys.
    # Lowest indices are lower priority.
    def plural_key_fallback_priority(locale)
      possible_fallbacks = Worldwide::Plurals.keys(locale).map(&:to_s)
      possible_fallbacks.sort_by { |k| [k == "other" ? 1 : 0, k] } # Simple, prefer `other`, then arbitrary order after

      # Research idea: This could be computed by checking all the translations that have all of
      # their pluralizations if the values for a given pluralization key typically match the
      # missing key, then we use that over the one. This should give us slighty better chance
      # than random guess at getting a gramattically correct string.
      # FALLBACK_PRIORITY_GRAPH[locale].nodes[missing_plural_key].edges.sort_by(&:weight)
    end
  end
end
