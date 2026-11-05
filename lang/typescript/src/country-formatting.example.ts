/**
 * Example usage of the Country Formatting API
 * 
 * This file demonstrates how to use the getCountryFormatting API
 * to fetch and work with country-specific address formatting data.
 */

import {
  getCountryFormatting,
  hasCountryFormatting,
  getAvailableLocales,
} from './country-formatting';

async function examples() {
  console.log('=== Country Formatting API Examples ===\n');

  // Example 1: Get Canadian formatting in English
  console.log('Example 1: Canadian formatting (English)');
  const caEN = await getCountryFormatting('CA', 'en');
  console.log('Country:', caEN.name);
  console.log('Edit template:', caEN.format.edit);
  console.log('Province label:', caEN.labels.province);
  console.log('Postal code example:', caEN.zip_example);
  console.log('Number of provinces/territories:', caEN.zones?.length);
  console.log();

  // Example 2: Get Canadian formatting in French
  console.log('Example 2: Canadian formatting (French)');
  const caFR = await getCountryFormatting('CA', 'fr');
  console.log('Country:', caFR.name);
  console.log('Province label:', caFR.labels.province);
  const quebec = caFR.zones?.find(z => z.code === 'QC');
  console.log('Quebec name in French:', quebec?.name);
  console.log();

  // Example 3: Get Brazilian formatting
  console.log('Example 3: Brazilian formatting (Portuguese)');
  const brPT = await getCountryFormatting('BR', 'pt-br');
  console.log('Country:', brPT.name);
  console.log('Show template:', brPT.format.show);
  console.log('ZIP code label:', brPT.labels.zip);
  console.log('Neighborhood label:', brPT.labels.neighborhood);
  console.log('Uses split street fields:', brPT.additional_address_fields.street_name);
  console.log();

  // Example 4: Check available locales
  console.log('Example 4: Check available locales');
  const caLocales = await getAvailableLocales('CA');
  console.log('Canada locales:', caLocales);
  const brLocales = await getAvailableLocales('BR');
  console.log('Brazil locales:', brLocales);
  console.log();

  // Example 5: Check if formatting exists
  console.log('Example 5: Check if formatting exists');
  const hasCAEN = await hasCountryFormatting('CA', 'en');
  console.log('Has CA/en:', hasCAEN);
  const hasCAES = await hasCountryFormatting('CA', 'es');
  console.log('Has CA/es:', hasCAES);
  console.log();

  // Example 6: Work with zones
  console.log('Example 6: Working with zones');
  const ontario = caEN.zones?.find(z => z.code === 'ON');
  if (ontario) {
    console.log('Province:', ontario.name);
    console.log('Code:', ontario.code);
    console.log('Postal code prefixes:', ontario.zip_prefixes?.join(', '));
    console.log('Neighboring zones:', ontario.neighboring_zones?.join(', '));
  }
  console.log();

  // Example 7: Compare field requirements across countries
  console.log('Example 7: Field requirements comparison');
  console.log('Canada requires province:', caEN.additional_address_fields.province);
  console.log('Canada requires neighborhood:', caEN.additional_address_fields.neighborhood || false);
  console.log('Brazil requires province:', brPT.additional_address_fields.province);
  console.log('Brazil requires neighborhood:', brPT.additional_address_fields.neighborhood);
  console.log('Brazil uses street_name field:', brPT.additional_address_fields.street_name);
  console.log();

  // Example 8: Error handling
  console.log('Example 8: Error handling');
  try {
    await getCountryFormatting('XX', 'en');
  } catch (error) {
    console.log('Expected error:', (error as Error).message);
  }
}

// Run examples if this file is executed directly
if (require.main === module) {
  examples().catch(console.error);
}
