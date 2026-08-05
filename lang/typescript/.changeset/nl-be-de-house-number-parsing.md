---
"@shopify/worldwide": patch
---

Fix `splitAddress1` for NL/BE/DE so house numbers with uppercase unit letters (`Voltastraat 2 A`), hyphenated ranges (`Philippusweg 3-5`), roman-numeral suffixes (`Kerkstraat 12-II`), and NL streets starting with an ordinal (`1e Helmersstraat 5`) split correctly instead of dumping the whole value into `streetName`.
