import type {FieldConcatenationRule} from 'src/types/region-yaml-config';

import {
  RESERVED_DELIMITER,
  concatAddressField,
  regexSplitAddressField,
  splitAddressField,
} from './address-fields';

describe('RESERVED_DELIMITER', () => {
  test('is a non-breaking space', () => {
    // Word Joiner (U+2060)
    expect(RESERVED_DELIMITER).toBe('⁠');
    expect(RESERVED_DELIMITER).toBe('\u2060');

    // Non-breaking space (U+00A0)
    expect(RESERVED_DELIMITER).not.toBe(' ');
    expect(RESERVED_DELIMITER).not.toBe('\xA0');
    expect(RESERVED_DELIMITER).not.toBe('\u00A0');

    // Regular space
    expect(RESERVED_DELIMITER).not.toBe(' ');
    expect(RESERVED_DELIMITER).not.toBe('\x20');
  });
});

describe('concatAddressField', () => {
  test('creates a concatenated address field with reserved delimiter', () => {
    const fieldDefinition: FieldConcatenationRule[] = [
      {key: 'streetNumber'},
      {key: 'streetName'},
    ];
    const fieldValues = {
      streetNumber: '123',
      streetName: 'Main',
    };
    expect(concatAddressField(fieldDefinition, fieldValues)).toBe(
      '123\u2060Main',
    );
  });

  test('field definition order matters', () => {
    const fieldDefinitionNumberFirst: FieldConcatenationRule[] = [
      {key: 'streetNumber'},
      {key: 'streetName'},
    ];
    const fieldDefinitionNameFirst: FieldConcatenationRule[] = [
      {key: 'streetName'},
      {key: 'streetNumber'},
    ];
    const fieldValues = {
      streetNumber: '123',
      streetName: 'Main',
    };
    expect(concatAddressField(fieldDefinitionNumberFirst, fieldValues)).toBe(
      '123\u2060Main',
    );
    expect(concatAddressField(fieldDefinitionNameFirst, fieldValues)).toBe(
      'Main\u2060123',
    );
  });

  test('creates a concatenated string without fields required by the region config', () => {
    const fieldDefinition: FieldConcatenationRule[] = [
      {key: 'streetNumber'},
      {key: 'streetName'},
    ];
    const fieldValues = {
      streetNumber: '123',
      streetName: 'Main',
    };
    expect(concatAddressField(fieldDefinition, fieldValues)).toBe(
      '123\u2060Main',
    );
    expect(
      concatAddressField(fieldDefinition, {
        streetNumber: fieldValues.streetNumber,
      }),
    ).toBe('123');
    expect(
      concatAddressField(fieldDefinition, {
        streetName: fieldValues.streetName,
      }),
    ).toBe('\u2060Main');
    expect(concatAddressField(fieldDefinition, {})).toBe('');
  });

  describe('fields with decorators', () => {
    test('creates a concatenated address field with decorator', () => {
      const fieldDefinition: FieldConcatenationRule[] = [
        {key: 'streetName'},
        {key: 'streetNumber', decorator: ','},
      ];
      const fieldValues = {
        streetNumber: '123',
        streetName: 'Main',
      };
      expect(concatAddressField(fieldDefinition, fieldValues)).toBe(
        'Main,\u2060123',
      );
    });

    test("doesn't include decorator if previous field is empty", () => {
      const fieldDefinition: FieldConcatenationRule[] = [
        {key: 'streetName'},
        {key: 'streetNumber', decorator: ','},
      ];
      const fieldValues = {
        streetNumber: '123',
      };
      expect(concatAddressField(fieldDefinition, fieldValues)).toBe(
        '\u2060123',
      );
    });

    test("doesn't include decorator or delimiter if field is empty", () => {
      const fieldDefinition: FieldConcatenationRule[] = [
        {key: 'streetName'},
        {key: 'streetNumber', decorator: ','},
      ];
      const fieldValues = {
        streetName: 'Main',
      };
      expect(concatAddressField(fieldDefinition, fieldValues)).toBe('Main');
    });
  });
});

describe('splitAddressField', () => {
  test('creates an address object from string with reserved delimiter', () => {
    const fieldDefinition: FieldConcatenationRule[] = [
      {key: 'streetNumber'},
      {key: 'streetName'},
    ];
    const concatenatedAddress = '123\u2060Main';

    expect(splitAddressField(fieldDefinition, concatenatedAddress)).toEqual({
      streetNumber: '123',
      streetName: 'Main',
    });
  });

  test('field definition order matters', () => {
    const fieldDefinitionNumberFirst: FieldConcatenationRule[] = [
      {key: 'streetNumber'},
      {key: 'streetName'},
    ];
    const fieldDefinitionNameFirst: FieldConcatenationRule[] = [
      {key: 'streetName'},
      {key: 'streetNumber'},
    ];
    const concatenatedAddress = '123\u2060Main';
    expect(
      splitAddressField(fieldDefinitionNumberFirst, concatenatedAddress),
    ).toEqual({
      streetNumber: '123',
      streetName: 'Main',
    });
    expect(
      splitAddressField(fieldDefinitionNameFirst, concatenatedAddress),
    ).toEqual({
      streetName: '123',
      streetNumber: 'Main',
    });
  });

  test('creates an address object from string with partial data', () => {
    const fieldDefinition: FieldConcatenationRule[] = [
      {key: 'streetNumber'},
      {key: 'streetName'},
    ];
    expect(splitAddressField(fieldDefinition, '123')).toEqual({
      streetNumber: '123\u2060',
    });
    expect(splitAddressField(fieldDefinition, '\u2060Main')).toEqual({
      streetName: 'Main',
    });
  });

  describe('fields with decorators', () => {
    test('splits address with decorator', () => {
      const fieldDefinition: FieldConcatenationRule[] = [
        {key: 'streetName'},
        {key: 'streetNumber', decorator: ','},
      ];
      const concatenatedAddress = 'Main,\u2060123';

      expect(splitAddressField(fieldDefinition, concatenatedAddress)).toEqual({
        streetName: 'Main',
        streetNumber: '123',
      });
    });

    test('splits address without defined decorator if no delimiter is found', () => {
      const fieldDefinition: FieldConcatenationRule[] = [
        {key: 'streetName'},
        {key: 'streetNumber', decorator: ','},
      ];
      const concatenatedAddress = 'Main';

      expect(splitAddressField(fieldDefinition, concatenatedAddress)).toEqual({
        streetName: 'Main\u2060',
      });
    });

    test('splits address without defined decorator if leading delimiter is found', () => {
      const fieldDefinition: FieldConcatenationRule[] = [
        {key: 'streetName'},
        {key: 'streetNumber', decorator: ','},
      ];
      const concatenatedAddress = '\u2060123';

      expect(splitAddressField(fieldDefinition, concatenatedAddress)).toEqual({
        streetNumber: '123',
      });
    });
  });

  describe('regexSplitAddressField', () => {
    test('creates an address object from string matching one of the defined regexes', () => {
      const fieldDefinition: FieldConcatenationRule[] = [
        {key: 'streetName'},
        {key: 'streetNumber'},
      ];
      const regexPatterns = [
        new RegExp('^(?<streetNumber>\\d+) (?<streetName>[^\\d]+)$'),
        new RegExp('^(?<streetName>[^\\d]+) (?<streetNumber>\\d+)$'),
      ];
      const address = 'Main 123';

      expect(
        regexSplitAddressField(fieldDefinition, regexPatterns, address),
      ).toEqual({
        streetName: 'Main',
        streetNumber: '123',
      });
    });

    test('creates an address object from string matching multiple of the defined regexes', () => {
      const fieldDefinition: FieldConcatenationRule[] = [
        {key: 'streetName'},
        {key: 'streetNumber'},
      ];
      const regexPatterns = [
        new RegExp('^(?<streetName>[^\\d]+) (?<streetNumber>\\d+)$'),
        new RegExp('^(?<dupName>[^\\d]+) (?<dupNumber>\\d+)$'),
      ];
      const address = 'Main 123';

      expect(
        regexSplitAddressField(fieldDefinition, regexPatterns, address),
      ).toEqual({
        streetName: 'Main',
        streetNumber: '123',
      });
    });

    test('creates a partial address object from string that does not match one of the defined regexes', () => {
      const fieldDefinition: FieldConcatenationRule[] = [
        {key: 'streetName'},
        {key: 'streetNumber'},
      ];
      const regexPatterns = [
        new RegExp('^(?<streetNumber>\\d+) (?<streetName>[^\\d]+)$'),
      ];
      const address = 'Main 123';

      expect(
        regexSplitAddressField(fieldDefinition, regexPatterns, address),
      ).toEqual({
        streetName: 'Main 123',
      });
    });

    test('field definition order matters', () => {
      const fieldDefinitionNumberFirst: FieldConcatenationRule[] = [
        {key: 'streetNumber'},
        {key: 'streetName'},
      ];
      const fieldDefinitionNameFirst: FieldConcatenationRule[] = [
        {key: 'streetName'},
        {key: 'streetNumber'},
      ];
      const regexPatterns = [
        new RegExp('^(?<streetName>[^\\d]+) (?<streetNumber>\\d+)$'),
      ];
      const address = 'Main';
      expect(
        regexSplitAddressField(
          fieldDefinitionNumberFirst,
          regexPatterns,
          address,
        ),
      ).toEqual({
        streetNumber: 'Main',
      });
      expect(
        regexSplitAddressField(
          fieldDefinitionNameFirst,
          regexPatterns,
          address,
        ),
      ).toEqual({
        streetName: 'Main',
      });
    });
  });
});
