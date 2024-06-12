import {
  FieldConcatenationRule,
  addressUsesScript,
  getRegionConfig,
} from './regions';

describe('region yaml loader', () => {
  test('should load config without combined_address_format', () => {
    const config = getRegionConfig('US');
    expect(config).not.toBeNull();
    expect(config!.code).toEqual('US');
    expect(config!.combined_address_format).toBeUndefined();
  });

  test('should load config with combined_address_format', () => {
    const config = getRegionConfig('BR');
    expect(config).not.toBeNull();
    expect(config!.code).toEqual('BR');
    expect(config!.combined_address_format).toEqual({
      address1: [{key: 'streetName'}, {key: 'streetNumber', decorator: ','}],
      address2: [{key: 'line2'}, {key: 'neighborhood', decorator: ','}],
    });
  });

  test('should load config overridden settigns for specific languages', () => {
    const config = getRegionConfig('TW');
    expect(config).not.toBeNull();
    expect(config!.code).toEqual('TW');
    expect(config!.combined_address_format).toEqual({
      address2: [{key: 'line2'}, {key: 'neighborhood', decorator: ','}],
      // eslint-disable-next-line @typescript-eslint/naming-convention
      'zh-TW': {
        address2: [{key: 'line2'}, {key: 'neighborhood'}],
      },
    });
  });

  test('should return null for undefined region', () => {
    const config = getRegionConfig('ZZZ');
    expect(config).toBeNull();
  });
});

describe('addressUsesScript', () => {
  test('returns false for Han in US English examples', () => {
    const fieldDefinition: FieldConcatenationRule[] = [
      {key: 'streetNumber'},
      {key: 'streetName'},
    ];
    const fieldValues = {
      streetNumber: '123',
      streetName: 'Main',
    };

    expect(addressUsesScript(fieldDefinition, fieldValues, 'Han')).toBe(false);
  });

  test('returns true for Han in Taiwan Chinese examples', () => {
    const fieldDefinition: FieldConcatenationRule[] = [
      {key: 'line2'},
      {key: 'neighborhood'},
    ];
    const fieldValues = {
      line2: '黎明里',
      neighborhood: '黎明里',
    };

    expect(addressUsesScript(fieldDefinition, fieldValues, 'Han')).toBe(true);
  });
});
