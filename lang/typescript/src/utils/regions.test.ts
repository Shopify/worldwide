import {Address} from 'src/types/address';

import {
  FieldConcatenationRule,
  addressUsesScript,
  getConcatenationRules,
  getRegionConfig,
  getSplitRules,
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
      default: {
        address1: [{key: 'streetName'}, {key: 'streetNumber', decorator: ','}],
        address2: [{key: 'line2'}, {key: 'neighborhood', decorator: ','}],
      },
    });
  });

  test('should load config overridden settigns for specific languages', () => {
    const config = getRegionConfig('TW');
    expect(config).not.toBeNull();
    expect(config!.code).toEqual('TW');
    expect(config!.combined_address_format).toEqual({
      default: {address2: [{key: 'line2'}, {key: 'neighborhood'}]},
      // eslint-disable-next-line @typescript-eslint/naming-convention
      Latin: {
        address2: [{key: 'line2'}, {key: 'neighborhood', decorator: ','}],
      },
    });
  });

  test('should return null for undefined region', () => {
    const config = getRegionConfig('ZZZ');
    expect(config).toBeNull();
  });
});

describe('getConcatenationRules', () => {
  test('returns undefined if no combined_address_format is not defined', () => {
    const config = getRegionConfig('US');
    const address: Address = {
      countryCode: 'US',
      address2: 'Apt 1',
    };
    expect(config).not.toBeNull();
    expect(getConcatenationRules(config!, address, 'address2')).toBeUndefined();
  });

  test('returns default rules if no language specific rules are defined', () => {
    const config = getRegionConfig('BR');
    const address: Address = {
      countryCode: 'BR',
      line2: 'dpto 4',
      neighborhood: 'Centro',
    };
    expect(config).not.toBeNull();
    expect(getConcatenationRules(config!, address, 'address2')).toEqual([
      {key: 'line2'},
      {key: 'neighborhood', decorator: ','},
    ]);
  });

  test('returns default rules if no language specific rules are defined but language is not detected', () => {
    const config = getRegionConfig('TW');
    const address: Address = {
      countryCode: 'TW',
      line2: 'No. 30',
      neighborhood: 'Daija District',
    };
    expect(config).not.toBeNull();
    expect(getConcatenationRules(config!, address, 'address2')).toEqual([
      {key: 'line2'},
      {key: 'neighborhood', decorator: ','},
    ]);
  });

  test('returns language specific rules if defined and language is detected', () => {
    const config = getRegionConfig('TW');
    const address: Address = {
      countryCode: 'TW',
      line2: '30號',
      neighborhood: '大甲區',
    };
    expect(config).not.toBeNull();
    expect(getConcatenationRules(config!, address, 'address2')).toEqual([
      {key: 'line2'},
      {key: 'neighborhood'},
    ]);
  });
});

describe('getSplitRules', () => {
  test('returns undefined if no combined_address_format is not defined', () => {
    const config = getRegionConfig('US');
    const address = 'Apt 1';
    expect(config).not.toBeNull();
    expect(getSplitRules(config!, address, 'address2')).toBeUndefined();
  });

  test('returns default rules if no language specific rules are defined', () => {
    const config = getRegionConfig('BR');
    const address = 'dpto 4,\u00A0Centro';
    expect(config).not.toBeNull();
    expect(getSplitRules(config!, address, 'address2')).toEqual([
      {key: 'line2'},
      {key: 'neighborhood', decorator: ','},
    ]);
  });

  test('returns default rules if no language specific rules are defined but language is not detected', () => {
    const config = getRegionConfig('TW');
    const address = 'No. 30,\u00A0Daija District';
    expect(config).not.toBeNull();
    expect(getSplitRules(config!, address, 'address2')).toEqual([
      {key: 'line2'},
      {key: 'neighborhood', decorator: ','},
    ]);
  });

  test('returns language specific rules if defined and language is detected', () => {
    const config = getRegionConfig('TW');
    const address = '30號\u00A0大甲區';
    expect(config).not.toBeNull();
    expect(getSplitRules(config!, address, 'address2')).toEqual([
      {key: 'line2'},
      {key: 'neighborhood'},
    ]);
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
      line2: '30號',
      neighborhood: '大甲區',
    };

    expect(addressUsesScript(fieldDefinition, fieldValues, 'Han')).toBe(true);
  });

  test('returns true for Han in mixed Taiwan Chinese and English examples', () => {
    const fieldDefinition: FieldConcatenationRule[] = [
      {key: 'line2'},
      {key: 'neighborhood'},
    ];
    const fieldValues = {
      line2: 'No. 30',
      neighborhood: '大甲區',
    };

    expect(addressUsesScript(fieldDefinition, fieldValues, 'Han')).toBe(true);
  });

  test('returns false for Han in empty examples', () => {
    const fieldDefinition: FieldConcatenationRule[] = [
      {key: 'line2'},
      {key: 'neighborhood'},
    ];
    const fieldValues = {};

    expect(addressUsesScript(fieldDefinition, fieldValues, 'Han')).toBe(false);
  });
});
