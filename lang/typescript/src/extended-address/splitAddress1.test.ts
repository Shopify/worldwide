import {splitAddress1} from './splitAddress1';

describe('splitAddress1', () => {
  test('returns null when extended address is not defined for region', () => {
    expect(splitAddress1('US', '123 Main', false)).toBeNull();
    expect(splitAddress1('US', '', false)).toBeNull();
    expect(splitAddress1('US', '123 Main', true)).toBeNull();
    expect(splitAddress1('US', '', true)).toBeNull();
  });

  test('returns empty object when extended address string is empty', () => {
    expect(splitAddress1('CL', '', false)).toEqual({});
    expect(splitAddress1('BR', '', false)).toEqual({});
    expect(splitAddress1('CL', '', true)).toEqual({});
    expect(splitAddress1('BR', '', true)).toEqual({});
  });

  test('returns address1 as street name when no delimiter is present and tryRegexFallback is false', () => {
    expect(splitAddress1('CL', '123 Main', false)).toEqual({
      streetName: '123 Main',
    });
    expect(splitAddress1('BR', '123 Main', false)).toEqual({
      streetName: '123 Main',
    });
  });

  test('returns address1 as street name when no delimiter is present, tryRegexFallback is true, and regex is not defined', () => {
    expect(splitAddress1('CL', '123 Main', true)).toEqual({
      streetName: '123 Main',
    });
    expect(splitAddress1('BR', '123 Main', true)).toEqual({
      streetName: '123 Main',
    });
  });

  test.each([
    {
      country: 'NL',
      address: 'Kempenaar 25 11',
      expected: {streetName: 'Kempenaar 25 11'},
    },
    {
      country: 'NL',
      address: '40 Baandersstraat',
      expected: {streetName: '40 Baandersstraat'},
    },
    {
      country: 'BR',
      address: 'Main, 123, Apt 2',
      expected: {streetName: 'Main, 123, Apt 2'},
    },
  ])(
    'returns address1 as street name when no delimiter is present, tryRegexFallback is true, and address does not match regex',
    ({country, address, expected}) => {
      expect(splitAddress1(country, address, true)).toEqual(expected);
    },
  );

  test('returns street number if string before delimiter is empty', () => {
    expect(splitAddress1('CL', '\u2060123', false)).toEqual({
      streetNumber: '123',
    });
    expect(splitAddress1('BR', '\u2060123', false)).toEqual({
      streetNumber: '123',
    });
    expect(splitAddress1('CL', '\u2060123', true)).toEqual({
      streetNumber: '123',
    });
    expect(splitAddress1('BR', '\u2060123', true)).toEqual({
      streetNumber: '123',
    });
  });

  test('returns full address object when separated by delimiter', () => {
    expect(splitAddress1('CL', 'Main \u2060123', false)).toEqual({
      streetName: 'Main',
      streetNumber: '123',
    });
    expect(splitAddress1('CL', 'Main \u2060123', true)).toEqual({
      streetName: 'Main',
      streetNumber: '123',
    });
  });

  test('returns full address object when separated by delimiter and decorator', () => {
    expect(splitAddress1('BR', 'Main, \u2060123', false)).toEqual({
      streetName: 'Main',
      streetNumber: '123',
    });
    expect(splitAddress1('BR', 'Main, \u2060123', true)).toEqual({
      streetName: 'Main',
      streetNumber: '123',
    });
  });

  test.each([
    {
      country: 'NL',
      address: 'Mercuriusstraat 26',
      expected: {streetName: 'Mercuriusstraat', streetNumber: '26'},
    },
    {
      country: 'NL',
      address: 'Bloemgracht 41B',
      expected: {streetName: 'Bloemgracht', streetNumber: '41B'},
    },
    {
      country: 'NL',
      address: 'Bloemgracht 41b',
      expected: {streetName: 'Bloemgracht', streetNumber: '41b'},
    },
    {
      country: 'NL',
      address: 'Meester Arendstraat 48 B',
      expected: {streetName: 'Meester Arendstraat', streetNumber: '48 B'},
    },
  ])(
    'returns full address object when not separated by delimiter, tryRegexFallback is true and address matches regex',
    ({country, address, expected}) => {
      expect(splitAddress1(country, address, true)).toEqual(expected);
    },
  );
});
