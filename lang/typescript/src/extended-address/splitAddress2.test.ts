import {splitAddress2} from './splitAddress2';

describe('splitAddress2', () => {
  test('returns null when extended address is not defined for region', () => {
    expect(splitAddress2('US', '#2, Centretown')).toBeNull();
  });

  test('returns empty object when extended address string is empty', () => {
    expect(splitAddress2('CL', '')).toEqual({});
    expect(splitAddress2('BR', '')).toEqual({});
  });

  test('returns address2 as line2 when no delimiter is present', () => {
    expect(splitAddress2('CL', 'dpto 4')).toEqual({line2: 'dpto 4'});
    expect(splitAddress2('BR', 'dpto 4')).toEqual({line2: 'dpto 4'});
  });

  test('returns neighborhood if string before delimiter is empty', () => {
    expect(splitAddress2('CL', '\u2060Centro')).toEqual({
      neighborhood: 'Centro',
    });
    expect(splitAddress2('BR', '\u2060Centro')).toEqual({
      neighborhood: 'Centro',
    });
  });

  test('returns full address object when separated by delimiter', () => {
    expect(splitAddress2('CL', 'dpto 4\u2060Centro')).toEqual({
      line2: 'dpto 4',
      neighborhood: 'Centro',
    });
  });

  test('returns full address object when separated by delimiter and decorator', () => {
    expect(splitAddress2('BR', 'dpto 4,\u2060Centro')).toEqual({
      line2: 'dpto 4',
      neighborhood: 'Centro',
    });
  });
});
