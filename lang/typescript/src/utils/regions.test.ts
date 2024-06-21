import {Address} from 'src/types/address';

import {
  FieldConcatenationRule,
  addressExclusivelyUsesScript,
  getConcatenationRules,
  getRegionConfig,
} from './regions';

describe('region yaml loader', () => {
  test('should load config without combined_address_format', () => {
    const config = getRegionConfig('US');
    expect(config).not.toBeNull();
    expect(config!.code).toEqual('US');
    expect(config!.combined_address_format).toBeUndefined();
  });

  test('should load config with combined_address_format and decorator set', () => {
    const config = getRegionConfig('BR');
    expect(config).not.toBeNull();
    expect(config!.code).toEqual('BR');
    expect(config!.combined_address_format).toEqual({
      default: {
        address1: [{key: 'streetName'}, {key: 'streetNumber', decorator: ', '}],
        address2: [{key: 'line2'}, {key: 'neighborhood', decorator: ', '}],
      },
    });
  });

  test('should load config overridden settings for specific languages', () => {
    const config = getRegionConfig('TW');
    expect(config).not.toBeNull();
    expect(config!.code).toEqual('TW');
    expect(config!.combined_address_format).toEqual({
      default: {address2: [{key: 'line2'}, {key: 'neighborhood'}]},
      // eslint-disable-next-line @typescript-eslint/naming-convention
      Latin: {
        address2: [{key: 'line2'}, {key: 'neighborhood', decorator: ', '}],
      },
    });
  });

  test('should return null for undefined region', () => {
    const config = getRegionConfig('ZZZ');
    expect(config).toBeNull();
  });
});

describe('getConcatenationRules', () => {
  describe('with address object', () => {
    test('returns undefined if combined_address_format is not defined', () => {
      const config = getRegionConfig('US');
      const address: Address = {
        countryCode: 'US',
        address2: 'Apt 1',
      };
      expect(config).not.toBeNull();
      expect(
        getConcatenationRules(config!, address, 'address2'),
      ).toBeUndefined();
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
        {key: 'neighborhood', decorator: ', '},
      ]);
    });

    test('returns default rules if script specifies rules are defined but script is not detected', () => {
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

    test('returns default rules if script specifies rules but multiple scripts detected', () => {
      const config = getRegionConfig('TW');
      const address: Address = {
        countryCode: 'TW',
        line2: 'No. 30號',
        neighborhood: 'Daija District 大甲區',
      };
      expect(config).not.toBeNull();
      expect(getConcatenationRules(config!, address, 'address2')).toEqual([
        {key: 'line2'},
        {key: 'neighborhood'},
      ]);
    });

    test('returns script specific rules if defined and only that script is detected', () => {
      const config = getRegionConfig('TW');
      const address: Address = {
        countryCode: 'TW',
        line2: 'No. 30',
        neighborhood: 'Daija District',
      };
      expect(config).not.toBeNull();
      expect(getConcatenationRules(config!, address, 'address2')).toEqual([
        {key: 'line2'},
        {key: 'neighborhood', decorator: ', '},
      ]);
    });
  });

  describe('with concatenated address string', () => {
    test('returns undefined if combined_address_format is not defined', () => {
      const config = getRegionConfig('US');
      const address = 'Apt 1';
      expect(config).not.toBeNull();
      expect(
        getConcatenationRules(config!, address, 'address2'),
      ).toBeUndefined();
    });

    test('returns default rules if no language specific rules are defined', () => {
      const config = getRegionConfig('BR');
      const address = 'dpto 4, \u2060Centro';
      expect(config).not.toBeNull();
      expect(getConcatenationRules(config!, address, 'address2')).toEqual([
        {key: 'line2'},
        {key: 'neighborhood', decorator: ', '},
      ]);
    });

    test('returns default rules if no language specific rules are defined but language is not detected', () => {
      const config = getRegionConfig('TW');
      const address = 'No. 30,\u00ADaija District';
      expect(config).not.toBeNull();
      expect(getConcatenationRules(config!, address, 'address2')).toEqual([
        {key: 'line2'},
        {key: 'neighborhood', decorator: ', '},
      ]);
    });

    test('returns language specific rules if defined and language is detected', () => {
      const config = getRegionConfig('TW');
      const address = '30號\u2060大甲區';
      expect(config).not.toBeNull();
      expect(getConcatenationRules(config!, address, 'address2')).toEqual([
        {key: 'line2'},
        {key: 'neighborhood'},
      ]);
    });
  });
});

describe('addressExclusivelyUsesScript', () => {
  test('returns true for Latin in US English examples', () => {
    const fieldDefinition: FieldConcatenationRule[] = [
      {key: 'streetNumber'},
      {key: 'streetName'},
    ];
    const fieldValues = {
      streetNumber: '123',
      streetName: 'Main',
    };

    expect(
      addressExclusivelyUsesScript(fieldDefinition, fieldValues, 'Latin'),
    ).toBe(true);
  });

  test('returns false for Latin in Taiwan Chinese examples', () => {
    const fieldDefinition: FieldConcatenationRule[] = [
      {key: 'line2'},
      {key: 'neighborhood'},
    ];
    const fieldValues = {
      line2: '30號',
      neighborhood: '大甲區',
    };

    expect(
      addressExclusivelyUsesScript(fieldDefinition, fieldValues, 'Latin'),
    ).toBe(false);
  });

  test('returns false for Latin in mixed Taiwan Chinese and English examples', () => {
    const fieldDefinition: FieldConcatenationRule[] = [
      {key: 'line2'},
      {key: 'neighborhood'},
    ];

    expect(
      addressExclusivelyUsesScript(
        fieldDefinition,
        {
          line2: 'No. 30',
          neighborhood: '大甲區',
        },
        'Latin',
      ),
    ).toBe(false);
    expect(
      addressExclusivelyUsesScript(
        fieldDefinition,
        {
          line2: '30號',
          neighborhood: 'Daija District',
        },
        'Latin',
      ),
    ).toBe(false);
    expect(
      addressExclusivelyUsesScript(
        fieldDefinition,
        {
          line2: 'No. 30號',
          neighborhood: 'Daija District 大甲區',
        },
        'Latin',
      ),
    ).toBe(false);
  });

  test('returns false for Latin in empty examples', () => {
    const fieldDefinition: FieldConcatenationRule[] = [
      {key: 'line2'},
      {key: 'neighborhood'},
    ];
    const fieldValues = {};

    expect(
      addressExclusivelyUsesScript(fieldDefinition, fieldValues, 'Latin'),
    ).toBe(false);
  });

  test('returns false for Latin if no fields are defined', () => {
    const fieldDefinition: FieldConcatenationRule[] = [];
    const fieldValues = {};

    expect(
      addressExclusivelyUsesScript(fieldDefinition, fieldValues, 'Latin'),
    ).toBe(false);
  });
});
