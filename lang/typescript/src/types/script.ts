/**
 * Character sets of languages that we support. This is a subset of the unicode
 * scripts list, not meant to be exhaustive or match that list. It should match
 * the ruby implementation.
 *
 * @see https://www.regular-expressions.info/unicode.html#script
 * @see https://github.com/Shopify/worldwide/blob/main/lib/worldwide/scripts.rb
 */
export type Script =
  | 'Arabic'
  | 'Han'
  | 'Hangul'
  | 'Hiragana'
  | 'Katakana'
  | 'Latin'
  | 'Thai';
