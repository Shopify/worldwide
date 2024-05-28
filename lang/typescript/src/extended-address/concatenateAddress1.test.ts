import {concatenateAddress1} from './concatenateAddress1';

describe('concatenateAddress1', () => {
  test('returns null if address1 is missing for standard region', () => {
    expect(
      concatenateAddress1({
        countryCode: 'US',
        streetName: 'Main',
        streetNumber: '123',
      }),
    ).toBeNull();
  });

  test('returns null if address1, streetName, and streetNumber are missing for region with additional fields', () => {
    expect(concatenateAddress1({countryCode: 'BR'})).toBeNull();
    expect(concatenateAddress1({countryCode: 'CL'})).toBeNull();
  });

  test('returns address1 for regions without extended address format', () => {
    expect(
      concatenateAddress1({
        countryCode: 'US',
        address1: '123 Main',
        streetName: 'Main',
        streetNumber: '123',
      }),
    ).toBe('123 Main');
  });

  test('returns concatenated address for regions with extended address format, ignoring address1', () => {
    expect(
      concatenateAddress1({
        countryCode: 'BR',
        address1: 'Main 123',
        streetName: 'Main',
        streetNumber: '123',
      }),
    ).toBe('Main,\u00A0123');
    expect(
      concatenateAddress1({
        countryCode: 'CL',
        address1: 'Main 123',
        streetName: 'Main',
        streetNumber: '123',
      }),
    ).toBe('Main\u00A0123');
  });

  test('returns address1 string if no additional address fields are found', () => {
    expect(
      concatenateAddress1({
        countryCode: 'US',
        address1: '123 Main',
      }),
    ).toBe('123 Main');
    expect(
      concatenateAddress1({
        countryCode: 'BR',
        address1: 'Main 123',
      }),
    ).toBe('Main 123');
    expect(
      concatenateAddress1({
        countryCode: 'CL',
        address1: 'Main 123',
      }),
    ).toBe('Main 123');
  });

  test('returns concatenated address even if empty strings are provided', () => {
    expect(
      concatenateAddress1({
        countryCode: 'BR',
        address1: 'Main 123',
        streetName: 'Main',
        streetNumber: '',
      }),
    ).toBe('Main');
    expect(
      concatenateAddress1({
        countryCode: 'BR',
        address1: 'Main 123',
        streetName: '',
        streetNumber: '123',
      }),
    ).toBe('\u00A0123');
    expect(
      concatenateAddress1({
        countryCode: 'BR',
        address1: 'Main 123',
        streetName: '',
        streetNumber: '',
      }),
    ).toBe('');
  });

  test('returns concatenated address in order specified by region config', () => {
    expect(
      concatenateAddress1({
        countryCode: 'BR',
        streetName: 'Main',
        streetNumber: '123',
      }),
    ).toBe('Main,\u00A0123');
    expect(
      concatenateAddress1({
        countryCode: 'BR',
        streetNumber: '123',
        streetName: 'Main',
      }),
    ).toBe('Main,\u00A0123');
  });

  test('returns concatenated address', () => {
    expect(
      concatenateAddress1({
        countryCode: 'CL',
        streetName: 'Main',
        streetNumber: '123',
      }),
    ).toBe('Main\u00A0123');
  });

  test('returns concatenated address with decorator', () => {
    expect(
      concatenateAddress1({
        countryCode: 'BR',
        streetName: 'Main',
        streetNumber: '123',
      }),
    ).toBe('Main,\u00A0123');
  });

  test('returns street name with no delimiter or decorator if street number is missing', () => {
    expect(
      concatenateAddress1({
        countryCode: 'BR',
        streetName: 'Main',
      }),
    ).toBe('Main');
    expect(
      concatenateAddress1({
        countryCode: 'CL',
        streetName: 'Main',
      }),
    ).toBe('Main');
  });

  test('returns street number with prefixed delimiter and no decorator if street name is missing', () => {
    expect(
      concatenateAddress1({
        countryCode: 'BR',
        streetNumber: '123',
      }),
    ).toBe('\u00A0123');
    expect(
      concatenateAddress1({
        countryCode: 'CL',
        streetNumber: '123',
      }),
    ).toBe('\u00A0123');
  });
});
