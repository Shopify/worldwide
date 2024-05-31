import {getRegionConfig} from './regions';

describe('yaml loading', () => {
  test('US', async () => {
    const config = await getRegionConfig('US');
    expect(config).not.toBeNull();
    expect(config!.combined_address_format).toBeUndefined();
  });

  test('BR', async () => {
    const config = await getRegionConfig('BR');
    expect(config).not.toBeNull();
    expect(config!.combined_address_format).not.toBeNull();
    expect(config!.combined_address_format).toEqual({
      address1: [{key: 'streetName'}, {key: 'streetNumber', decorator: ','}],
      address2: [{key: 'line2'}, {key: 'neighborhood', decorator: ','}],
    });
  });
});
