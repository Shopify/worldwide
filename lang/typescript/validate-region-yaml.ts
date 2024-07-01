import {z} from 'zod';

import {RegionYamlConfig} from './src/utils/regions';
import {type ValidYamlType} from './src/types/yaml';

export class RegionYamlValidationError extends Error {
  constructor(fileName: string, message: string) {
    super(`\nInvalid Region YAML ${fileName}: \n${message}`);
    this.name = 'RegionYamlValidationError';
  }
}

const addressFieldSchema = z.enum([
  'firstName',
  'lastName',
  'company',
  'address1',
  'address2',
  'zip',
  'city',
  'provinceCode',
  'countryCode',
  'phone',
  'streetName',
  'streetNumber',
  'line2',
  'neighborhood',
]);
const fieldConcatenationRuleSchema = z.object({
  key: addressFieldSchema,
  decorator: z.string().optional(),
});
const combinedAddressFormatSchema = z.object({
  address1: z.array(fieldConcatenationRuleSchema).optional(),
  address2: z.array(fieldConcatenationRuleSchema).optional(),
});
const regionYamlSchema = z.object({
  code: z
    .string({
      message: 'Must include property `code` that is a two-letter country code',
    })
    .length(2),
  combined_address_format: z
    .object({
      default: combinedAddressFormatSchema,
      /* eslint-disable @typescript-eslint/naming-convention */
      Arabic: combinedAddressFormatSchema.optional(),
      Han: combinedAddressFormatSchema.optional(),
      Hangul: combinedAddressFormatSchema.optional(),
      Hiragana: combinedAddressFormatSchema.optional(),
      Katakana: combinedAddressFormatSchema.optional(),
      Latin: combinedAddressFormatSchema.optional(),
      Thai: combinedAddressFormatSchema.optional(),
      /* eslint-enable @typescript-eslint/naming-convention */
    })

    .optional(),
});
// extract the inferred type
export type RegionYaml = z.infer<typeof regionYamlSchema>;

export function validateRegionYaml(
  fileName: string,
  yamlData: ValidYamlType,
): RegionYaml {
  const countryCode = fileName.replace(/\.yml$/, '');

  const result = regionYamlSchema.safeParse(yamlData);
  if (!result.success) {
    throw new RegionYamlValidationError(
      fileName,
      `${result.error.issues.map((issue) => `- ${issue.path.join('.')}: ${issue.message}`).join('\n')}`,
    );
  }

  const regionYaml: RegionYaml = result.data;
  if (regionYaml.code !== countryCode) {
    throw new RegionYamlValidationError(
      fileName,
      `Property \`code\` must match filename, is currently "${regionYaml.code}"`,
    );
  }

  if (regionYaml.combined_address_format) {
    if (
      regionYaml.combined_address_format.default.address1 === undefined &&
      regionYaml.combined_address_format.default.address2 === undefined
    ) {
      throw new RegionYamlValidationError(
        fileName,
        `Property \`combined_address_format.default\` must include address1 or address2`,
      );
    }
  }

  return regionYaml;
}

export function transformRegionYaml(regionYaml: RegionYaml): RegionYamlConfig {
  const config: RegionYamlConfig = {
    // TODO: Fix type cast
    combined_address_format:
      regionYaml.combined_address_format as RegionYamlConfig['combined_address_format'],
    // combined_address_format: regionYaml.combined_address_format
    //   ? {
    //       /* eslint-disable @typescript-eslint/naming-convention */
    //       Arabic: regionYaml.combined_address_format.Arabic,
    //       Han: regionYaml.combined_address_format.Han,
    //       Hangul: regionYaml.combined_address_format.Hangul,
    //       Hiragana: regionYaml.combined_address_format.Hiragana,
    //       Katakana: regionYaml.combined_address_format.Katakana,
    //       Latin: regionYaml.combined_address_format.Latin,
    //       Thai: regionYaml.combined_address_format.Thai,
    //       /* eslint-enable @typescript-eslint/naming-convention */
    //       default: regionYaml.combined_address_format.default,
    //     }
    //   : undefined,
  };

  return config;
}
