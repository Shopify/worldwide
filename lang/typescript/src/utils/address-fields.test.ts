import {FieldConcatenationRule} from './regions';
import {
  RESERVED_DELIMITER,
  concatAddressField,
  splitAddressField,
} from './address-fields';

describe('RESERVED_DELIMITER', () => {
  test('is a non-breaking space', () => {
    expect(RESERVED_DELIMITER).toBe(' ');
    expect(RESERVED_DELIMITER).toBe('\xA0');
    expect(RESERVED_DELIMITER).toBe('\u00A0');
    expect(RESERVED_DELIMITER).not.toBe('\x20');
    expect(RESERVED_DELIMITER).not.toBe(' ');
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
      '123\u00A0Main',
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
      '123\u00A0Main',
    );
    expect(concatAddressField(fieldDefinitionNameFirst, fieldValues)).toBe(
      'Main\u00A0123',
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
      '123\u00A0Main',
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
    ).toBe('\u00A0Main');
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
        'Main,\u00A0123',
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
        '\u00A0123',
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
    const concatenatedAddress = '123\u00A0Main';

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
    const concatenatedAddress = '123\u00A0Main';
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
    expect(splitAddressField(fieldDefinition, '\u00A0Main')).toEqual({
      streetName: 'Main',
    });
  });

  describe('fields with decorators', () => {
    test('splits address with decorator', () => {
      const fieldDefinition: FieldConcatenationRule[] = [
        {key: 'streetName'},
        {key: 'streetNumber', decorator: ','},
      ];
      const concatenatedAddress = 'Main,\u00A0123';

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
      const concatenatedAddress = '\u00A0123';

      expect(splitAddressField(fieldDefinition, concatenatedAddress)).toEqual({
        streetNumber: '123',
      });
    });
  });
});
