import {FieldConcatenationRule} from './regions';
import {RESERVED_DELIMITER, concatAddressField} from './address-fields';

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
