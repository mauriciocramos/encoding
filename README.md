# Encoding character strings in R
Maurício Collaça  
2017/05/23

The document [encoding.md](encoding.md) describes how to encode character strings in R by demonstrating `Encoding()`, `enc2native()`, `enc2utf8()`, `iconv()` and `iconvlist()`.

The function [`safe.iconvlist()`](safe.iconvlist.R) aims to list sucessfuly tested supported encodings from a source encoding to all suposedly supported encodings for the current platform by avoiding runtime errors and non-convertible strings.
