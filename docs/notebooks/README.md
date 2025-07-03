# Japan Postal Code Prefix Validator

This notebook validates Japanese postal codes against their expected prefecture-specific prefixes using real shipping data and the Worldwide library's Japanese region configuration.

## Overview

The `jp-prefix-validator.ipynb` notebook is a data analysis tool that validates the accuracy of Japanese postal codes by checking whether they use the correct prefixes for their corresponding prefectures/provinces. This validation helps ensure data quality and identifies potential issues in address datasets.

## What It Does

The validator performs the following operations:

1. **Data Loading**: Loads shipping data from a CSV file containing postal codes and province information
2. **Configuration Loading**: Imports Japanese postal code prefix mappings from YAML configuration files
3. **Province Mapping**: Creates mappings between province names (in multiple languages/formats) and standardized zone codes
4. **Postal Code Validation**: Validates that each postal code's prefix matches the expected prefixes for its province
5. **Error Reporting**: Provides detailed statistics on validation results and identifies invalid postal codes

## How Japanese Postal Codes Work

Japanese postal codes (郵便番号) follow a 7-digit format: `XXX-XXXX`. The first 2-3 digits serve as prefixes that correspond to specific prefectures and regions within Japan. Each prefecture has one or more designated prefixes, and postal codes must use the correct prefix for their geographic location.

## Dependencies

Before running the notebook, ensure you have the following Python packages installed:

```bash
pip install pandas
pip install python-dotenv
pip install PyYAML
```

## Required Files

The notebook expects the following files to be present:

1. **`data.csv`**: A CSV file containing shipping data with at least these columns:

   - `shipping_postal_code`: Japanese postal codes in XXX-XXXX format
   - `shipping_province`: Prefecture names (can be in English, Japanese, or romanized formats)

2. **`zip_prefixes.yaml`**: YAML configuration file containing Japanese region data with zip prefixes (from the Worldwide library's region data). You can also have a .env file in the same directory and specify with PATH_TO_YAML the path to the the yaml file.

## Environment Configuration

Create a `.env` file to specify the path to your YAML configuration:

```bash
PATH_TO_YAML=path/to/your/zip_prefixes.yaml
```

If not specified, the notebook will look for `zip_prefixes.yaml` in the current directory.

## Usage

1. **Prepare your data**: Ensure your CSV file contains the required columns with Japanese postal codes and prefecture names

2. **Set up configuration**: Place the Japanese region configuration YAML file in the appropriate location

3. **Run the notebook**: Execute all cells in sequence:
   - Cell 0: Install dependencies
   - Cell 1: Load and clean data
   - Cell 2: Load YAML configuration
   - Cell 3: Create province name mappings
   - Cell 4: Create prefix mappings
   - Cell 5: Filter and prepare data
   - Cell 6: Validate postal codes and generate report

## Output Interpretation

The validation results include:

- **Total rows processed**: Number of valid postal code records analyzed
- **Total invalid prefixes**: Count of postal codes that don't match expected prefixes
- **Total unique invalid prefixes**: Count of distinct invalid postal codes
- **Percentage of invalid prefixes**: Error rate as a percentage
- **Detailed invalid prefixes**: Breakdown by prefecture showing specific invalid postal codes

### Example Output

```
Total rows: 80748
Total invalid prefixes: 398
Total unique invalid prefixes: 381
Percentage of invalid prefixes: 0.49%
```

## Context Within Worldwide

This validator is part of the [Worldwide gem](../../README.md), an internationalization and localization library that provides:

- Address validation and formatting
- Postal code validation by country and region
- Multi-language support for region names
- Comprehensive geographic data from Unicode CLDR

The Japanese postal code validation logic tested here powers the production address validation features in the Worldwide library.

## Technical Details

### Supported Prefecture Formats

The validator recognizes multiple name formats for Japanese prefectures:

- **English**: "Tokyo", "Osaka", "Hokkaido"
- **Japanese**: "東京都", "大阪府", "北海道"
- **Romanized**: "Tokyo-to", "Osaka-fu", "Hokkaido"
- **ISO codes**: "JP-13", "JP-27", "JP-01"

### Validation Logic

For each postal code, the validator:

1. Extracts the prefecture from the shipping data
2. Maps the prefecture name to a standardized zone code
3. Looks up the allowed prefixes for that zone
4. Checks if the postal code starts with any allowed prefix
5. Reports mismatches as validation errors

### Data Quality Insights

Common sources of validation errors include:

- **Data entry errors**: Typos in postal codes or province names
- **Outdated postal codes**: Historical codes that have been reassigned
- **Cross-border addresses**: Addresses near prefecture boundaries
- **Special postal codes**: Corporate or institutional codes with different rules
