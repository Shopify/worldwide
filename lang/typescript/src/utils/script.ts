/* eslint-disable @typescript-eslint/naming-convention */

export type Script =
  | 'Arabic'
  | 'Han'
  | 'Hangul'
  | 'Hiragana'
  | 'Katakana'
  | 'Latin'
  | 'Thai';

export const scriptRegexes: Record<Script, RegExp> = {
  Arabic: /\p{Script=Arabic}/u,
  Han: /\p{Script=Han}/u,
  Hangul: /\p{Script=Hangul}/u,
  Hiragana: /\p{Script=Hiragana}/u,
  Katakana: /\p{Script=Katakana}/u,
  Latin: /\p{Script=Latin}/u,
  Thai: /\p{Script=Thai}/u,
};

/**
 * Checks if a string contains the character set of a given script type.
 *
 * @example
 * ```js
 * stringUsesScript('你好', 'Han') // true
 * stringUsesScript('你好', 'Latin') // false
 * stringUsesScript('Hello 你好', 'Han') // true
 * stringUsesScript('Hello 你好', 'Latin') // true
 * ```
 *
 * @param value String to analyze
 * @param script Script to detect within the value string
 * @returns true if any characters of the specified script is found in the string
 */
export function stringUsesScript(value: string, script: Script): boolean {
  return scriptRegexes[script].test(value);
}
