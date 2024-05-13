# Address format strings

## Introduction <!-- omit in toc -->

Worldwide defines different address format strings that control the layout of address elements for each country region.

Each format string has a different syntax, and is meant for use in different scenarios.

This page aims to document these syntaxes, their usage and limitations for those who need to create/edit them.

**⚠️ Warning:** You shouldn't parse these format strings yourself, but instead make use of the higher-level libraries that already consume these strings. This document is meant for those creating the higher-level libraries, or for those who need to make changes to these format strings.

## Table of Contents <!-- omit in toc -->

- [Address format strings](#address-format-strings)
  - [`edit`](#edit)
    - [English description](#english-description)
    - [Grammar](#grammar)
  - [`show`](#show)
    - [English description](#english-description-1)
    - [Grammar](#grammar-1)
    - [Limitations](#limitations)
      - [No escaping of special characters](#no-escaping-of-special-characters)
      - [No space-less formats](#no-space-less-formats)
      - [No free-standing prefix/suffix characters](#no-free-standing-prefixsuffix-characters)
      - [No special concatenation characters](#no-special-concatenation-characters)

## `edit`

The `edit` address format string controls the layout of elements within an address input form for a country region.

e.g., `{company}_{address1}_{address2}_{city}_{country}{province}{zip}_{phone}`

![Example address input form formatted using the `edit` address format](images/edit.png)

**⚠️ Warning:** There's a lot more to creating an address form than just the layout of the fields (error messages, optionality, placeholders, etc.) You probably shouldn't parse `edit` yourself; use a pre-existing, higher-level library instead. This document is meant for those creating the higher-level libraries.

### English description

1. Fields are specified by wrapping the field name in curly braces: `{field_name}`
2. Lines of fields are separated by an underscore `_`

### Grammar

Below is the EBNF ([extended Backus-Naur form](https://en.wikipedia.org/wiki/Extended_Backus-Naur_form)) for `edit` address format strings:

```
EditFormatString ::= Lines
Lines ::= Line (LineSeparator Lines)?
LineSeparator ::= '_'
Line ::= Field+
Field ::= '{' Identifier '}'
Identifier ::= [a-zA-Z0-9_]+
```

## `show`

The `show` address format string controls how addresses should be rendered as part of a UI.

e.g., `{firstName} {lastName}_{company}_{address1}_{address2}_{city} {province} {zip}_{country}_{phone}`

![Example address formatted using the `show` address format](images/show.png)

### English description

1. Fields are specified by wrapping the field name in curly braces: `{field_name}`
2. Lines of fields are separated by an underscore `_`
3. Fields are separated by an space character
4. Other characters are permitted as prefixes/suffixes of a field
   * Note: the prefix of a field is separated from the suffix of a preceding field by the space character separating the fields

### Grammar

Below is the EBNF ([extended Backus-Naur form](https://en.wikipedia.org/wiki/Extended_Backus-Naur_form)) for `show` address format strings:

```
ShowFormatString ::= Lines
Lines ::= Line (LineSeparator Lines)?
LineSeparator ::= '_'
Line ::= PrefixedSuffixedField (FieldSeparator PrefixedSuffixedField)*
FieldSeparator ::= ' '
PrefixedSuffixedField ::= (Prefix? Field Suffix?)
Field ::= '{' Identifier '}'
Identifier ::= [a-zA-Z0-9_]+
Prefix ::= Text
Suffix ::= Text
Text ::= [^_{} ]+
```

### Limitations

There are a number of limitations to the `show` syntax that cannot cover the complexity of the world's address formatting.

#### No escaping of special characters

There is no support for escaping special characters: `{`, `}`, `_`, `<space>`

#### No space-less formats

Since the fields are space-separated, there is no way to specify a non-separator space character.
However, many languages (e.g., English) are space-delimited, so libraries using the `show` string end up concatenatiing the fields together using spaces, even if the language doesn't require spaces (e.g., Japanese).

#### No free-standing prefix/suffix characters

There is no way to specify prefix/suffix characters that will be included regardless of the provided values.
Any characters besides a field name are either prefixes or suffixes of a field, and therefore if a value for the field is not provided, the associated prefix/suffix characters are also not provided.

#### No special concatenation characters

There is no way to specify characters other than space characters for concatenating two fields.
For example, in Brazil, when the `city` and `province` fields are formatted adjacent to one another, instead of a space between the fields, ` - ` should be used. These concatenation characters are neither a prefix nor a suffix of either field, so cannot be specified in this format's syntax.
