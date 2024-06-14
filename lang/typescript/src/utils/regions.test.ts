import {getRegionConfig} from './regions';

describe('region yaml loader', () => {
  test('should load config without combined_address_format', () => {
    const config = getRegionConfig('US');
    expect(config).not.toBeNull();
    expect(config!.code).toEqual('US');
    expect(config!.combined_address_format).toBeUndefined();
  });

  test('should load config with combined_address_format and no decorator', () => {
    const config = getRegionConfig('TW');
    expect(config).not.toBeNull();
    expect(config!.code).toEqual('TW');
    expect(config!.combined_address_format).toEqual({
      address2: [{key: 'line2'}, {key: 'neighborhood'}],
    });
  });

  test('should load config with combined_address_format and decorator set', () => {
    const config = getRegionConfig('BR');
    expect(config).not.toBeNull();
    expect(config!.code).toEqual('BR');
    expect(config!.combined_address_format).toEqual({
      address1: [{key: 'streetName'}, {key: 'streetNumber', decorator: ', '}],
      address2: [{key: 'line2'}, {key: 'neighborhood', decorator: ', '}],
    });
  });

  test('should return null for undefined region', () => {
    const config = getRegionConfig('ZZZ');
    expect(config).toBeNull();
  });
});
