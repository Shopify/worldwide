import {generateAddress2} from './generateAddress2';

describe('generateAddress2', () => {
  test('returns null if address2 is missing for standard region', async () => {
    expect(
      await generateAddress2('US', {line2: '#2', neighborhood: 'Centretown'}),
    ).toBeNull();
    expect(
      await generateAddress2('US', {line2: '#2', neighborhood: 'Centretown'}),
    ).toBeNull();
  });

  test('returns null if address2 is missing for region with additional fields', async () => {
    expect(await generateAddress2('BR', {})).toBeNull();
    expect(await generateAddress2('CL', {})).toBeNull();
  });

  test('returns address2 if defined', async () => {
    expect(
      await generateAddress2('US', {
        address2: 'Centretown #2',
        line2: '#2',
        neighborhood: 'Centretown',
      }),
    ).toBe('Centretown #2');
    expect(
      await generateAddress2('BR', {
        address2: 'dpto 4 Centro',
        line2: 'dpto 4',
        neighborhood: 'Centro',
      }),
    ).toBe('dpto 4 Centro');
    expect(
      await generateAddress2('CL', {
        address2: 'dpto 4 Centro',
        line2: 'dpto 4',
        neighborhood: 'Centro',
      }),
    ).toBe('dpto 4 Centro');
  });

  test('returns address2 string if no additional address fields are found', async () => {
    expect(await generateAddress2('US', {address2: 'Centretown #2'})).toBe(
      'Centretown #2',
    );
  });

  test('returns concatenated address in order specified by region config', async () => {
    expect(
      await generateAddress2('BR', {line2: 'dpto 4', neighborhood: 'Centro'}),
    ).toBe('dpto 4,\u00A0Centro');
    expect(
      await generateAddress2('BR', {neighborhood: 'Centro', line2: 'dpto 4'}),
    ).toBe('dpto 4,\u00A0Centro');
  });

  test('returns concatenated address', async () => {
    expect(
      await generateAddress2('CL', {line2: 'dpto 4', neighborhood: 'Centro'}),
    ).toBe('dpto 4\u00A0Centro');
  });

  test('returns concatenated address with decorator', async () => {
    expect(
      await generateAddress2('BR', {line2: 'dpto 4', neighborhood: 'Centro'}),
    ).toBe('dpto 4,\u00A0Centro');
    expect(
      await generateAddress2('PH', {line2: 'apt 4', neighborhood: '294'}),
    ).toBe('apt 4 Barangay\u00A0294');
    expect(
      await generateAddress2('VN', {line2: 'apt 4', neighborhood: 'Cầu Giấy'}),
    ).toBe('apt 4, Quận\u00A0Cầu Giấy');
  });

  test('returns line2 with no delimeter or decorator if neighborhood is missing', async () => {
    expect(await generateAddress2('BR', {line2: 'dpto 4'})).toBe('dpto 4');
    expect(await generateAddress2('CL', {line2: 'dpto 4'})).toBe('dpto 4');
  });

  test('returns neighborhood with prefixed delimeter and no decorator if line2 is missing', async () => {
    expect(await generateAddress2('BR', {neighborhood: 'Centro'})).toBe(
      '\u00A0Centro',
    );
    expect(await generateAddress2('CL', {neighborhood: 'Centro'})).toBe(
      '\u00A0Centro',
    );
  });
});
