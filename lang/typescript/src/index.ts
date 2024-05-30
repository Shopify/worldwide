export const RESERVED_DELIMETER = '\xA0';

/**
 * Temp placeholder during project setup
 */
export function tempConcatStrings(...args: string[]) {
  return args.join(RESERVED_DELIMETER);
}
