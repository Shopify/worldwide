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

export function identifyScripts(value: string): Script[] {
  return (
    Object.entries(scriptRegexes)
      .filter(([, regex]) => regex.test(value))
      // Type assertion here because Object.entries doesn't guarantee the keys
      // are of the right type, but we know here they are
      .map(([script]) => script as Script)
  );
}

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

/**
 * Checks if a string contains the character set of a given script type, and only
 * of that type.
 *
 * @example
 * ```js
 * stringUsesScript('你好', 'Han') // true
 * stringUsesScript('你好', 'Latin') // false
 * stringUsesScript('Hello 你好', 'Han') // false
 * stringUsesScript('Hello 你好', 'Latin') // false
 * ```
 *
 * @param value String to analyze
 * @param script Script to detect within the value string
 * @returns true if all characters of the specified script is found in the string
 */
export function stringExclusivelyUsesScript(
  value: string,
  script: Script,
): boolean {
  const scriptsDetected = identifyScripts(value);
  console.log(value, script, scriptsDetected);
  return scriptsDetected.length === 1 && scriptsDetected[0] === script;
}
