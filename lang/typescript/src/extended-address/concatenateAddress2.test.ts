import {concatenateAddress2} from './concatenateAddress2';

describe('concatenateAddress2', () => {
  test('returns null if address2 is missing for standard region', () => {
    expect(
      concatenateAddress2({
        countryCode: 'US',
        line2: '#2',
        neighborhood: 'Centretown',
      }),
    ).toBeNull();
  });

  test('returns null if address2, line2, and neighborhood are missing for region with additional fields', () => {
    expect(
      concatenateAddress2({
        countryCode: 'BR',
      }),
    ).toBeNull();
    expect(
      concatenateAddress2({
        countryCode: 'CL',
      }),
    ).toBeNull();
  });

  test('returns address2 for regions without extended address format', () => {
    expect(
      concatenateAddress2({
        countryCode: 'US',
        address2: 'Centretown #2',
        line2: '#2',
        neighborhood: 'Centretown',
      }),
    ).toBe('Centretown #2');
  });

  test('returns concatenated address for regions with extended address format, ignoring address2', () => {
    expect(
      concatenateAddress2({
        countryCode: 'BR',
        address2: 'dpto 4 Centro',
        line2: 'dpto 4',
        neighborhood: 'Centro',
      }),
    ).toBe('dpto 4,\u00A0Centro');
    expect(
      concatenateAddress2({
        countryCode: 'CL',
        address2: 'dpto 4 Centro',
        line2: 'dpto 4',
        neighborhood: 'Centro',
      }),
    ).toBe('dpto 4\u00A0Centro');
  });

  test('returns address2 string if no additional address fields are found', () => {
    expect(
      concatenateAddress2({
        countryCode: 'US',
        address2: 'Centretown #2',
      }),
    ).toBe('Centretown #2');
    expect(
      concatenateAddress2({
        countryCode: 'BR',
        address2: 'dpto 4 Centro',
      }),
    ).toBe('dpto 4 Centro');
    expect(
      concatenateAddress2({
        countryCode: 'CL',
        address2: 'dpto 4 Centro',
      }),
    ).toBe('dpto 4 Centro');
  });

  test('returns concatenated address even if empty strings are provided', () => {
    expect(
      concatenateAddress2({
        countryCode: 'BR',
        address2: 'dpto 4 Centro',
        line2: 'dpto 4',
        neighborhood: '',
      }),
    ).toBe('dpto 4');
    expect(
      concatenateAddress2({
        countryCode: 'BR',
        address2: 'dpto 4 Centro',
        line2: '',
        neighborhood: 'Centro',
      }),
    ).toBe('\u00A0Centro');
    expect(
      concatenateAddress2({
        countryCode: 'BR',
        address2: 'dpto 4 Centro',
        line2: '',
        neighborhood: '',
      }),
    ).toBe('');
  });

  test('returns concatenated address in order specified by region config', () => {
    expect(
      concatenateAddress2({
        countryCode: 'BR',
        line2: 'dpto 4',
        neighborhood: 'Centro',
      }),
    ).toBe('dpto 4,\u00A0Centro');
    expect(
      concatenateAddress2({
        countryCode: 'BR',
        neighborhood: 'Centro',
        line2: 'dpto 4',
      }),
    ).toBe('dpto 4,\u00A0Centro');
  });

  test('returns concatenated address', () => {
    expect(
      concatenateAddress2({
        countryCode: 'CL',
        line2: 'dpto 4',
        neighborhood: 'Centro',
      }),
    ).toBe('dpto 4\u00A0Centro');
  });

  test('returns concatenated address with decorator', () => {
    expect(
      concatenateAddress2({
        countryCode: 'BR',
        line2: 'dpto 4',
        neighborhood: 'Centro',
      }),
    ).toBe('dpto 4,\u00A0Centro');
    expect(
      concatenateAddress2({
        countryCode: 'PH',
        line2: 'apt 4',
        neighborhood: '294',
      }),
    ).toBe('apt 4\u00A0294');
    expect(
      concatenateAddress2({
        countryCode: 'VN',
        line2: 'apt 4',
        neighborhood: 'Cầu Giấy',
      }),
    ).toBe('apt 4,\u00A0Cầu Giấy');
  });

  test('returns line2 with no delimiter or decorator if neighborhood is missing', () => {
    expect(
      concatenateAddress2({
        countryCode: 'BR',
        line2: 'dpto 4',
      }),
    ).toBe('dpto 4');
    expect(
      concatenateAddress2({
        countryCode: 'CL',
        line2: 'dpto 4',
      }),
    ).toBe('dpto 4');
  });

  test('returns neighborhood with prefixed delimiter and no decorator if line2 is missing', () => {
    expect(
      concatenateAddress2({
        countryCode: 'BR',
        neighborhood: 'Centro',
      }),
    ).toBe('\u00A0Centro');
    expect(
      concatenateAddress2({
        countryCode: 'CL',
        neighborhood: 'Centro',
      }),
    ).toBe('\u00A0Centro');
  });

  describe('language override', () => {
    test("returns default format if language override doesn't match", () => {
      expect(
        concatenateAddress2({
          countryCode: 'TW',
          line2: 'No. 30',
          neighborhood: 'Daija District',
        }),
      ).toBe('No. 30,\u00A0Daija District');
    });

    test('returns alternate language format if language override matches', () => {
      expect(
        concatenateAddress2({
          countryCode: 'TW',
          line2: '30號',
          neighborhood: '大甲區',
        }),
      ).toBe('30號\u2060大甲區');
    });
  });
});
