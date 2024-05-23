import {UNIVERSAL_DELIMETER, tempConcatStrings} from './index';

test('universal delimeter is non-breaking space', () => {
  expect(UNIVERSAL_DELIMETER).toBe(' ');
  expect(UNIVERSAL_DELIMETER).toBe('\xA0');
  expect(UNIVERSAL_DELIMETER).toBe('\u00A0');
  expect(UNIVERSAL_DELIMETER).not.toBe('\x20');
  expect(UNIVERSAL_DELIMETER).not.toBe(' ');
});

test('concat strings using universal delimeter', () => {
  expect(tempConcatStrings('123', 'Main')).toBe('123 Main');
  expect(tempConcatStrings('123', 'Main')).toBe('123\xA0Main');
  expect(tempConcatStrings('123', 'Main')).toBe('123\u00A0Main');
  expect(tempConcatStrings('123', 'Main')).not.toBe('123 Main');
});
