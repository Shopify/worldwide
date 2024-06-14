import {FieldConcatenationRule} from './regions';
import {
  RESERVED_DELIMITER,
  concatAddressField,
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
      streetNumber: '123',
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
    test('splits address without defined decorator', () => {
      const fieldDefinition: FieldConcatenationRule[] = [
        {key: 'streetName'},
        {key: 'streetNumber', decorator: ','},
      ];
      const concatenatedAddress = 'Main';

      expect(splitAddressField(fieldDefinition, concatenatedAddress)).toEqual({
        streetName: 'Main',
      });
    });
    test('splits address without defined decorator 2', () => {
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
});
