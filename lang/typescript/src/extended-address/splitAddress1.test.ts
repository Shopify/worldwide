import {splitAddress1} from './splitAddress1';

describe('splitAddress1', () => {
  test('returns null when extended address is not defined for region', () => {
    expect(splitAddress1('US', '123 Main', false)).toBeNull();
    expect(splitAddress1('US', '', false)).toBeNull();
    expect(splitAddress1('US', '123 Main', true)).toBeNull();
    expect(splitAddress1('US', '', true)).toBeNull();
  });

  test('returns empty object when extended address string is empty', () => {
    expect(splitAddress1('CL', '', false)).toEqual({});
    expect(splitAddress1('BR', '', false)).toEqual({});
    expect(splitAddress1('CL', '', true)).toEqual({});
    expect(splitAddress1('BR', '', true)).toEqual({});
  });

  test('returns address1 as street name when no delimiter is present and tryRegexFallback is false', () => {
    expect(splitAddress1('CL', '123 Main', false)).toEqual({
      streetName: '123 Main',
    });
    expect(splitAddress1('BR', '123 Main', false)).toEqual({
      streetName: '123 Main',
    });
  });

  test('returns address1 as street name when no delimiter is present, tryRegexFallback is true, and regex is not defined', () => {
    expect(splitAddress1('CL', '123 Main', true)).toEqual({
      streetName: '123 Main',
    });
    expect(splitAddress1('BR', '123 Main', true)).toEqual({
      streetName: '123 Main',
    });
  });

  test.each([
    {
      country: 'NL',
      address: 'Kempenaar 25 11',
      expected: {streetName: 'Kempenaar 25 11'},
    },
    {
      country: 'NL',
      address: '40 Baandersstraat',
      expected: {streetName: '40 Baandersstraat'},
    },
    {
      country: 'BR',
      address: 'Main, 123, Apt 2',
      expected: {streetName: 'Main, 123, Apt 2'},
    },
  ])(
    'returns address1 as street name when no delimiter is present, tryRegexFallback is true, and address does not match regex',
    ({country, address, expected}) => {
      expect(splitAddress1(country, address, true)).toEqual(expected);
    },
  );

  test('returns street number if string before delimiter is empty', () => {
    expect(splitAddress1('CL', '\u2060123', false)).toEqual({
      streetNumber: '123',
    });
    expect(splitAddress1('BR', '\u2060123', false)).toEqual({
      streetNumber: '123',
    });
    expect(splitAddress1('CL', '\u2060123', true)).toEqual({
      streetNumber: '123',
    });
    expect(splitAddress1('BR', '\u2060123', true)).toEqual({
      streetNumber: '123',
    });
  });

  test('returns full address object when separated by delimiter', () => {
    expect(splitAddress1('CL', 'Main \u2060123', false)).toEqual({
      streetName: 'Main',
      streetNumber: '123',
    });
    expect(splitAddress1('CL', 'Main \u2060123', true)).toEqual({
      streetName: 'Main',
      streetNumber: '123',
    });
  });

  test('returns full address object when separated by delimiter and decorator', () => {
    expect(splitAddress1('BR', 'Main, \u2060123', false)).toEqual({
      streetName: 'Main',
      streetNumber: '123',
    });
    expect(splitAddress1('BR', 'Main, \u2060123', true)).toEqual({
      streetName: 'Main',
      streetNumber: '123',
    });
  });

  test.each([
    {
      address: 'Mercuriusstraat 26',
      expected: {streetName: 'Mercuriusstraat', streetNumber: '26'},
    },
    {
      address: 'Bloemgracht 41B',
      expected: {streetName: 'Bloemgracht', streetNumber: '41B'},
    },
    {
      address: 'Bloemgracht 41b',
      expected: {streetName: 'Bloemgracht', streetNumber: '41b'},
    },
    {
      address: 'Meester Arendstraat 48 B',
      expected: {streetName: 'Meester Arendstraat', streetNumber: '48 B'},
    },
  ])(
    'returns full address object when not separated by delimiter, tryRegexFallback is true and address matches regex for NL',
    ({address, expected}) => {
      expect(splitAddress1('NL', address, true)).toEqual(expected);
    },
  );

  test.each([
    {
      address: 'Ziegeleiweg 3',
      expected: {streetName: 'Ziegeleiweg', streetNumber: '3'},
    },
    {
      address: 'Sexauerstraße 3a',
      expected: {streetName: 'Sexauerstraße', streetNumber: '3a'},
    },
    {
      address: 'Straße des Friedens 6 A',
      expected: {streetName: 'Straße des Friedens', streetNumber: '6 A'},
    },
    {
      address: 'Ladenspelderstr. 52',
      expected: {streetName: 'Ladenspelderstr.', streetNumber: '52'},
    },
    {
      address: 'Marktstr.32',
      expected: {streetName: 'Marktstr.', streetNumber: '32'},
    },
    {
      address: 'Ringstraße, 16',
      expected: {streetName: 'Ringstraße', streetNumber: '16'},
    },
    {
      address: 'Ringstraße,16',
      expected: {streetName: 'Ringstraße', streetNumber: '16'},
    },
    {
      address: 'Lorbeerstr., 25',
      expected: {streetName: 'Lorbeerstr.', streetNumber: '25'},
    },
  ])(
    'returns full address object when not separated by delimiter, tryRegexFallback is true and address matches regex for DE',
    ({address, expected}) => {
      expect(splitAddress1('DE', address, true)).toEqual(expected);
    },
  );

  test.each([
    {
      address: 'Doornbergstraat 30',
      expected: {streetName: 'Doornbergstraat', streetNumber: '30'},
    },
    {
      address: 'Moeskouterlaan, 29',
      expected: {streetName: 'Moeskouterlaan', streetNumber: '29'},
    },
    {
      address: 'Rue le Marais 6A',
      expected: {streetName: 'Rue le Marais', streetNumber: '6A'},
    },
    {
      address: 'Kiezelstraat 4a',
      expected: {streetName: 'Kiezelstraat', streetNumber: '4a'},
    },
    {
      address: 'Rue Grand Peine 12 C',
      expected: {streetName: 'Rue Grand Peine', streetNumber: '12 C'},
    },
    {
      address: '85 Rue des Floralies',
      expected: {streetName: 'Rue des Floralies', streetNumber: '85'},
    },
    {
      address: '39, rue de Grass',
      expected: {streetName: 'rue de Grass', streetNumber: '39'},
    },
    {
      address: '84 a Rue du merlo',
      expected: {streetName: 'Rue du merlo', streetNumber: '84 a'},
    },
    {
      address: '84A Rue du merlo',
      expected: {streetName: 'Rue du merlo', streetNumber: '84A'},
    },
  ])(
    'returns full address object when not separated by delimiter, tryRegexFallback is true and address matches regex for BE',
    ({address, expected}) => {
      expect(splitAddress1('BE', address, true)).toEqual(expected);
    },
  );

  test.each([
    {
      address: 'Alberto Risopatrón 2714',
      expected: {streetName: 'Alberto Risopatrón', streetNumber: '2714'},
    },
    {
      address: 'avenida nelson pereira, 1741',
      expected: {streetName: 'avenida nelson pereira', streetNumber: '1741'},
    },
    {
      address: 'Rancho las Cabras 9A',
      expected: {streetName: 'Rancho las Cabras', streetNumber: '9A'},
    },
    {
      address: 'Callejón Torreblanca 355 B',
      expected: {streetName: 'Callejón Torreblanca', streetNumber: '355 B'},
    },
    {
      address: 'Quebrada de Vitor #1234',
      expected: {streetName: 'Quebrada de Vitor', streetNumber: '#1234'},
    },
    {
      address: 'Barros Arana # 1298',
      expected: {streetName: 'Barros Arana', streetNumber: '# 1298'},
    },
    {
      address: 'Calle Amalia Errazuriz Nº956',
      expected: {streetName: 'Calle Amalia Errazuriz', streetNumber: 'Nº956'},
    },
    {
      address: 'Calle Amalia Errazuriz Nº 956',
      expected: {streetName: 'Calle Amalia Errazuriz', streetNumber: 'Nº 956'},
    },
    {
      address: 'Calle Amalia Errazuriz nº956',
      expected: {streetName: 'Calle Amalia Errazuriz', streetNumber: 'nº956'},
    },
    {
      address: 'Calle Amalia Errazuriz nº 956',
      expected: {streetName: 'Calle Amalia Errazuriz', streetNumber: 'nº 956'},
    },
    {
      address: 'Calle Amalia Errazuriz no956',
      expected: {streetName: 'Calle Amalia Errazuriz', streetNumber: 'no956'},
    },
    {
      address: 'Calle Amalia Errazuriz no 956',
      expected: {streetName: 'Calle Amalia Errazuriz', streetNumber: 'no 956'},
    },
    {
      address: 'Calle Amalia Errazuriz No956',
      expected: {streetName: 'Calle Amalia Errazuriz', streetNumber: 'No956'},
    },
    {
      address: 'Calle Amalia Errazuriz No 956',
      expected: {streetName: 'Calle Amalia Errazuriz', streetNumber: 'No 956'},
    },
    {
      address: 'Calle Amalia Errazuriz no.956',
      expected: {streetName: 'Calle Amalia Errazuriz', streetNumber: 'no.956'},
    },
    {
      address: 'Calle Amalia Errazuriz no. 956',
      expected: {streetName: 'Calle Amalia Errazuriz', streetNumber: 'no. 956'},
    },
    {
      address: 'Calle Amalia Errazuriz No.956',
      expected: {streetName: 'Calle Amalia Errazuriz', streetNumber: 'No.956'},
    },
    {
      address: 'Calle Amalia Errazuriz No. 956',
      expected: {streetName: 'Calle Amalia Errazuriz', streetNumber: 'No. 956'},
    },
    {
      address: 'Calle Amalia Errazuriz número 956',
      expected: {
        streetName: 'Calle Amalia Errazuriz',
        streetNumber: 'número 956',
      },
    },
    {
      address: 'Calle Amalia Errazuriz Número 956',
      expected: {
        streetName: 'Calle Amalia Errazuriz',
        streetNumber: 'Número 956',
      },
    },
  ])(
    'returns full address object when not separated by delimiter, tryRegexFallback is true and address matches regex for CL, MX, ES',
    ({address, expected}) => {
      expect(splitAddress1('CL', address, true)).toEqual(expected);
      expect(splitAddress1('MX', address, true)).toEqual(expected);
      expect(splitAddress1('ES', address, true)).toEqual(expected);
    },
  );

  test.each([
    {
      address: 'פטישן 22',
      expected: {streetName: 'פטישן', streetNumber: '22'},
    },
    {
      address: 'שבזי שלום 9',
      expected: {streetName: 'שבזי שלום', streetNumber: '9'},
    },
    {
      address: 'חרצית, 5',
      expected: {streetName: 'חרצית', streetNumber: '5'},
    },
    {
      address: 'חרצית, 500',
      expected: {streetName: 'חרצית', streetNumber: '500'},
    },
    {
      address: '21, הדקל',
      expected: {streetName: 'הדקל', streetNumber: '21'},
    },
    {
      address: '1, קיבוץ גבים',
      expected: {streetName: 'קיבוץ גבים', streetNumber: '1'},
    },
    {
      address: '47/2, המגינים',
      expected: {streetName: 'המגינים', streetNumber: '47/2'},
    },
    {
      address: 'רבי יהודה הנשיא 30/16',
      expected: {streetName: 'רבי יהודה הנשיא', streetNumber: '30/16'},
    },
    {
      address: 'St. Ben Ami 24',
      expected: {streetName: 'St. Ben Ami', streetNumber: '24'},
    },
    {
      address: 'Shevet Zvulun, 2',
      expected: {streetName: 'Shevet Zvulun', streetNumber: '2'},
    },
  ])(
    'returns full address object when not separated by delimiter, tryRegexFallback is true and address matches regex for IL',
    ({address, expected}) => {
      expect(splitAddress1('IL', address, true)).toEqual(expected);
    },
  );

  test.each([
    {
      address: 'Rua Santo Antônio 722',
      expected: {streetName: 'Rua Santo Antônio', streetNumber: '722'},
    },
    {
      address: 'Rua Santo Antônio, 722',
      expected: {streetName: 'Rua Santo Antônio', streetNumber: '722'},
    },
    {
      address: 'Rua Santo Antônio,722',
      expected: {streetName: 'Rua Santo Antônio', streetNumber: '722'},
    },
    {
      address: 'Rua Corumbá 47 A',
      expected: {streetName: 'Rua Corumbá', streetNumber: '47 A'},
    },
    {
      address: 'Rua Corumbá 47A',
      expected: {streetName: 'Rua Corumbá', streetNumber: '47A'},
    },
    {
      address: 'Rua Corumbá 47A',
      expected: {streetName: 'Rua Corumbá', streetNumber: '47A'},
    },
    {
      address: 'Rua Nair Costa Baldoino - número: 449',
      expected: {streetName: 'Rua Nair Costa Baldoino - número: 449'},
    },
  ])(
    'returns full address object when not separated by delimiter, tryRegexFallback is true and address matches regex for BR',
    ({address, expected}) => {
      expect(splitAddress1('BR', address, true)).toEqual(expected);
    },
  );
});
