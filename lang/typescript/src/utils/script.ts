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

export function stringUsesScript(value: string, script: Script): boolean {
  return scriptRegexes[script].test(value);
}
