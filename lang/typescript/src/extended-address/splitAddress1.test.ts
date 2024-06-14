import {splitAddress1} from './splitAddress1';

describe('splitAddress1', () => {
  test('returns null when extended address is not defined for region', () => {
    expect(splitAddress1('US', '123 Main')).toBeNull();
  });

  test('returns empty object when extended address string is empty', () => {
    expect(splitAddress1('CL', '')).toEqual({});
    expect(splitAddress1('BR', '')).toEqual({});
  });

  test('returns address1 as street name when no delimiter is present', () => {
    expect(splitAddress1('CL', '123 Main')).toEqual({streetName: '123 Main'});
    expect(splitAddress1('BR', '123 Main')).toEqual({streetName: '123 Main'});
  });

  test('returns street number if string before delimiter is empty', () => {
    expect(splitAddress1('CL', '\u2060123')).toEqual({streetNumber: '123'});
    expect(splitAddress1('BR', '\u2060123')).toEqual({streetNumber: '123'});
  });

  test('returns full address object when separated by delimiter', () => {
    expect(splitAddress1('CL', 'Main \u2060123')).toEqual({
      streetName: 'Main',
      streetNumber: '123',
    });
  });

  test('returns full address object when separated by delimiter and decorator', () => {
    expect(splitAddress1('BR', 'Main, \u2060123')).toEqual({
      streetName: 'Main',
      streetNumber: '123',
    });
  });
});
