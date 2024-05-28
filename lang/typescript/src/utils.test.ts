import {AdditionalAddressField} from './regions';
import {RESERVED_DELIMETER, concatAddressField} from './utils';

describe('RESERVED_DELIMETER', () => {
  test('is a non-breaking space', () => {
    expect(RESERVED_DELIMETER).toBe(' ');
    expect(RESERVED_DELIMETER).toBe('\xA0');
    expect(RESERVED_DELIMETER).toBe('\u00A0');
    expect(RESERVED_DELIMETER).not.toBe('\x20');
    expect(RESERVED_DELIMETER).not.toBe(' ');
  });
});

describe('concatAddressField', () => {
  test('creates a concatenated address field with reserved delimeter', () => {
    const fieldDefinition: AdditionalAddressField[] = [
      {key: 'streetNumber', required: false},
      {key: 'streetName', required: false},
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
    const fieldDefinitionNumberFirst: AdditionalAddressField[] = [
      {key: 'streetNumber', required: false},
      {key: 'streetName', required: false},
    ];
    const fieldDefinitionNameFirst: AdditionalAddressField[] = [
      {key: 'streetName', required: false},
      {key: 'streetNumber', required: false},
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

  // TODO: Do we care about the required field for concatenation or just when we do actual field validation on the UI/Atlas?
  test('creates a concatenated string without fields required by the region config', () => {
    const fieldDefinition: AdditionalAddressField[] = [
      {key: 'streetNumber', required: true},
      {key: 'streetName', required: true},
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
      const fieldDefinition: AdditionalAddressField[] = [
        {key: 'streetName', required: false},
        {key: 'streetNumber', required: false, decorator: ','},
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
      const fieldDefinition: AdditionalAddressField[] = [
        {key: 'streetName', required: false},
        {key: 'streetNumber', required: false, decorator: ','},
      ];
      const fieldValues = {
        streetNumber: '123',
      };
      expect(concatAddressField(fieldDefinition, fieldValues)).toBe(
        '\u00A0123',
      );
    });
    test("doesn't include decorator or delimeter if field is empty", () => {
      const fieldDefinition: AdditionalAddressField[] = [
        {key: 'streetName', required: false},
        {key: 'streetNumber', required: false, decorator: ','},
      ];
      const fieldValues = {
        streetName: 'Main',
      };
      expect(concatAddressField(fieldDefinition, fieldValues)).toBe('Main');
    });
  });
});
