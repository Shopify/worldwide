import {z} from 'zod';

import type {ValidYamlType} from './yaml';

const addressFieldEnum = z.enum(
  [
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
  ],
  {
    errorMap: (issue, ctx) =>
      issue.code === 'invalid_enum_value'
        ? {
            message: `Invalid key, found '${issue.received}'. Expected: ${issue.options.map((opt) => `'${opt}'`).join(' | ')}`,
          }
        : {message: ctx.defaultError},
  },
);
const extendableFieldEnum = addressFieldEnum.extract(['address1', 'address2'], {
  message: 'Invalid extended address field, must be address1 or address2',
});
const fieldConcatenationRuleSchema = z
  .object({
    key: addressFieldEnum,
    decorator: z.string().optional(),
  })
  .strict();
const combinedAddressFormatSchema = z
  .record(extendableFieldEnum, z.array(fieldConcatenationRuleSchema))
  .refine((format) => format.address1 || format.address2, {
    message: 'Must include address1, address2, or both',
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
    .strict()
    .optional(),
});
export type RegionYaml = z.infer<typeof regionYamlSchema>;

export class RegionYamlValidationError extends Error {
  constructor(fileName: string, message: string) {
    super(`\nInvalid Region YAML ${fileName}: \n${message}`);
    this.name = 'RegionYamlValidationError';
  }
}

/**
 * Validate the region yaml is in the right format with Zod. Will throw
 * `RegionYamlValidationError` if issues are found.
 *
 * @param fileName Name of the region yaml file
 * @param yamlData Parsed yaml content as a JS object
 * @returns Zod-validated region config data
 */
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

  return regionYaml;
}

export type MinimalRegionYaml = Pick<RegionYaml, 'combined_address_format'>;

/**
 * Strip the YAML data down to only what we need to keep the resulting JS
 * output size to a minimum
 */
export function transformRegionYaml(regionYaml: RegionYaml): MinimalRegionYaml {
  return {
    combined_address_format: regionYaml.combined_address_format,
  };
}
