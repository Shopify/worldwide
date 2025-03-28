import {splitAddress2} from './splitAddress2';

describe('splitAddress2', () => {
  test('returns null when extended address is not defined for region', () => {
    expect(splitAddress2('US', '#2, Centretown')).toBeNull();
  });

  test('returns empty object when extended address string is empty', () => {
    expect(splitAddress2('CL', '')).toEqual({});
    expect(splitAddress2('BR', '')).toEqual({});
  });

  test('returns an empty object when no delimiter is present', () => {
    expect(splitAddress2('CL', 'dpto 4')).toEqual({});
    expect(splitAddress2('BR', 'dpto 4')).toEqual({});
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
    expect(splitAddress2('CL', 'dpto 4 \u2060Centro')).toEqual({
      line2: 'dpto 4',
      neighborhood: 'Centro',
    });
  });

  test('returns full address object when separated by delimiter and decorator', () => {
    expect(splitAddress2('BR', 'dpto 4, \u2060Centro')).toEqual({
      line2: 'dpto 4',
      neighborhood: 'Centro',
    });
  });

  test('splits the address on the first delimiter', () => {
    expect(splitAddress2('CL', 'dpto 4 \u2060Centro\u2060abc')).toEqual({
      line2: 'dpto 4',
      neighborhood: 'Centro\u2060abc',
    });
  });

  describe('language override', () => {
    test("returns default format if language override doesn't match", () => {
      expect(splitAddress2('TW', '30號\u2060大甲區')).toEqual({
        line2: '30號',
        neighborhood: '大甲區',
      });
    });

    test('returns alternate language format if language override matches', () => {
      expect(splitAddress2('TW', 'No. 30, \u2060Daija District')).toEqual({
        line2: 'No. 30',
        neighborhood: 'Daija District',
      });
    });
  });
});
