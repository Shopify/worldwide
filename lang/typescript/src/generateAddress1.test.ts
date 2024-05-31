import {generateAddress1} from './generateAddress1';

describe('generateAddress1', () => {
  test('returns null if address1 is missing for standard region', async () => {
    expect(
      await generateAddress1('US', {streetName: 'Main', streetNumber: '123'}),
    ).toBeNull();
    expect(
      await generateAddress1('US', {streetName: 'Main', streetNumber: '123'}),
    ).toBeNull();
  });

  test('returns null if address1 is missing for region with additional fields', async () => {
    expect(await generateAddress1('BR', {})).toBeNull();
    expect(await generateAddress1('CL', {})).toBeNull();
  });

  test('returns address1 if defined', async () => {
    expect(
      await generateAddress1('US', {
        address1: '123 Main',
        streetName: 'Main',
        streetNumber: '123',
      }),
    ).toBe('123 Main');
    expect(
      await generateAddress1('BR', {
        address1: 'Main 123',
        streetName: 'Main',
        streetNumber: '123',
      }),
    ).toBe('Main 123');
    expect(
      await generateAddress1('CL', {
        address1: 'Main 123',
        streetName: 'Main',
        streetNumber: '123',
      }),
    ).toBe('Main 123');
  });

  test('returns address1 string if no additional address fields are found', async () => {
    expect(await generateAddress1('US', {address1: '123 Main'})).toBe(
      '123 Main',
    );
  });

  test('returns concatenated address in order specified by region config', async () => {
    expect(
      await generateAddress1('BR', {streetName: 'Main', streetNumber: '123'}),
    ).toBe('Main,\u00A0123');
    expect(
      await generateAddress1('BR', {streetNumber: '123', streetName: 'Main'}),
    ).toBe('Main,\u00A0123');
  });

  test('returns concatenated address', async () => {
    expect(
      await generateAddress1('CL', {streetName: 'Main', streetNumber: '123'}),
    ).toBe('Main\u00A0123');
  });

  test('returns concatenated address with decorator', async () => {
    expect(
      await generateAddress1('BR', {streetName: 'Main', streetNumber: '123'}),
    ).toBe('Main,\u00A0123');
  });

  test('returns street name with no delimeter or decorator if street number is missing', async () => {
    expect(await generateAddress1('BR', {streetName: 'Main'})).toBe('Main');
    expect(await generateAddress1('CL', {streetName: 'Main'})).toBe('Main');
  });

  test('returns street number with prefixed delimeter and no decorator if street name is missing', async () => {
    expect(await generateAddress1('BR', {streetNumber: '123'})).toBe(
      '\u00A0123',
    );
    expect(await generateAddress1('CL', {streetNumber: '123'})).toBe(
      '\u00A0123',
    );
  });
});
