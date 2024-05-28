import {getRegionConfig} from './regions';

describe('yaml loading', () => {
  //   test('US', () => {
  //     const config = getRegionConfig('US');
  //     expect(config).not.toBeNull();
  //     expect(config!.additional_address_fields).toBeNull();
  //   });

  test('BR', () => {
    const config = getRegionConfig('BR');
    expect(config).not.toBeNull();
    expect(config!.additional_address_fields).not.toBeNull();
    expect(config!.additional_address_fields).toEqual({
      address1: [
        {key: 'streetName', required: true},
        {key: 'streetNumber', required: true, decorator: ','},
      ],
      address2: [
        {key: 'line2', required: false},
        {key: 'neighborhood', required: false, decorator: ','},
      ],
    });
  });
});
