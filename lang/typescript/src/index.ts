export const UNIVERSAL_DELIMETER = '\xA0';

/**
 * Temp placeholder during project setup
 */
export function tempConcatStrings(...args: string[]) {
  return args.join(UNIVERSAL_DELIMETER);
}
