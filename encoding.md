# Encoding character strings in R
Maurício Collaça  
2017/05/23  

## Introduction
This document describes how to encode character strings in R by demonstrating `Encoding()`, `enc2native()`, `enc2utf8()`, `iconv()` and `iconvlist()`.

Finally, its coded the function `safe.iconvlist()` that returns safe encodings from `iconvlist()`.

## Session information

```r
sessionInfo()
```

```
R version 3.4.0 (2017-04-21)
Platform: x86_64-w64-mingw32/x64 (64-bit)
Running under: Windows 10 x64 (build 14393)

Matrix products: default

locale:
[1] LC_COLLATE=Portuguese_Brazil.1252  LC_CTYPE=Portuguese_Brazil.1252   
[3] LC_MONETARY=Portuguese_Brazil.1252 LC_NUMERIC=C                      
[5] LC_TIME=Portuguese_Brazil.1252    

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

loaded via a namespace (and not attached):
 [1] compiler_3.4.0  backports_1.0.5 magrittr_1.5    rprojroot_1.2  
 [5] tools_3.4.0     htmltools_0.3.6 yaml_2.1.14     Rcpp_0.12.10   
 [9] stringi_1.1.5   rmarkdown_1.5   knitr_1.16      stringr_1.2.0  
[13] digest_0.6.12   evaluate_0.10  
```
## Platform

```r
Sys.info()[1:5]
```

```
      sysname       release       version      nodename       machine 
    "Windows"      "10 x64" "build 14393"     "DESKTOP"      "x86-64" 
```
## Clarification about getOption("encoding")
This option is related to encoding connections (Files, URLs, etc) and not character vector encodings.  Its factory fresh setting is `"native.enc"` if it was not previosly changed with `options(enconding)` or in the initialization files `Rprofile.site` and `.Rprofile`.

```r
getOption("encoding")
```

```
[1] "native.enc"
```
## Current Locale

```r
Sys.getlocale("LC_ALL")
```

```
[1] "LC_COLLATE=Portuguese_Brazil.1252;LC_CTYPE=Portuguese_Brazil.1252;LC_MONETARY=Portuguese_Brazil.1252;LC_NUMERIC=C;LC_TIME=Portuguese_Brazil.1252"
```
From `help(locales)`: _For category = "LC_ALL" the details of the string are system-specific: it might be a single locale name or a set of locale names separated by "/" (Solaris, macOS) or ";" (Windows, Linux). For portability, it is best to query categories individually: it is not necessarily the case that the result of foo <- Sys.getlocale() can be used in Sys.setlocale("LC_ALL", locale = foo)._

Saving locale categories configuration individually.

```r
localeCategories <- c("LC_COLLATE","LC_CTYPE","LC_MONETARY","LC_NUMERIC","LC_TIME")
locales <- setNames(sapply(localeCategories, Sys.getlocale), localeCategories)
```
Restoring saved locale categories configuration.

```r
locales
```

```
              LC_COLLATE                 LC_CTYPE              LC_MONETARY 
"Portuguese_Brazil.1252" "Portuguese_Brazil.1252" "Portuguese_Brazil.1252" 
              LC_NUMERIC                  LC_TIME 
                     "C" "Portuguese_Brazil.1252" 
```

```r
sapply(names(locales), function(x) {Sys.setlocale(x, locales[[x]])})
```

```
              LC_COLLATE                 LC_CTYPE              LC_MONETARY 
"Portuguese_Brazil.1252" "Portuguese_Brazil.1252" "Portuguese_Brazil.1252" 
              LC_NUMERIC                  LC_TIME 
                     "C" "Portuguese_Brazil.1252" 
```
## Warning about Sys.setlocale("LC_CTYPE")
From `help(locales)`: _Attempts to change the character set by `Sys.setlocale("LC_CTYPE")` that implies a different character set during a session may not work and are likely to lead to some confusion because it may not affect the native encoding._
## Localization information
The function `l10n_info()` reports on localization returning a list with three logical and one integer components:

`MBCS`: if a multi-byte character set in use?  
`UTF-8`: Is this a UTF-8 locale?  
`Latin-1`: Is this a Latin-1 locale?  
`codepage`: the Windows codepage corresponding to the locale R is using (and not necessarily that Windows is using).

```r
l10n_info()
```

```
$MBCS
[1] FALSE

$`UTF-8`
[1] FALSE

$`Latin-1`
[1] TRUE

$codepage
[1] 1252
```
## Native encoding indication
The native encoding indication is reported by `l10n_info()` in one of the logical elements `UTF-8` and `Latin-1` which is `TRUE`.

Native encoding indication for the current platform:

```r
l10n_info()[2:3][(l10n_info()[2:3])==TRUE]
```

```
$`Latin-1`
[1] TRUE
```
## Current native encoding name
Character strings in R can be declared to be encoded in `"latin1"` or `"UTF-8"` or as `"bytes"`.
A programatic approach to deal with the current native encoding name in R functions is based on how character strings can be declared and the information reported by `l10n_info`.

```r
(native <- ifelse(l10n_info()[[2]], "UTF-8", ifelse(l10n_info()[[3]], "latin1", "unknown")))
```

```
[1] "latin1"
```
## Current foreign encoding name
A programatic approach to deal with a foreign encoding name in R functions is based on how character strings can be declared and the information reported by `l10n_info`.

```r
(native <- ifelse(l10n_info()[[2]], "UTF-8", ifelse(l10n_info()[[3]], "latin1", "unknown")))
```

```
[1] "latin1"
```

```r
(foreign <- switch(native, "latin1"="UTF-8", "UTF-8"="latin1", "UTF-8"))
```

```
[1] "UTF-8"
```
## Base R functions to declare or convert encodings
`Encoding()` returns the encoding mark as `"latin1"`, `"UTF-8"`, `"bytes"` or `"unknown"`.  
`Encoding()<-` sets the encoding mark without translating the character string.  
`enc2native()` and `enc2utf8()` convert elements of character vectors to the native encoding or UTF-8 respectively, taking any marked encoding into account.  
`iconv()` uses system facilities to convert a character vector between encoding. The names of encodings and which ones are available are platform-dependent. All R platforms support `""` (for the encoding of the current locale), `"latin1"` and `"UTF-8"`.  Any encoding bits on elements of x are ignored: they will always be translated as if from encoding `from` even if declared otherwise.

There are other ways for character strings to acquire a declared encodings.  Some of them have an `encoding` argument that is used to declare encodings.  Most character manipulation functions will set the encoding on output strings if it was declared on the corresponding input.  These have changed as R has evolved and are mentioned in `help(Encoding)`.  There are also external packages but are out of the scope of this document.
### Custom function to display details about a string

```r
details <- function(x) {
    details <-
        list(x=x,encoding=Encoding(x),bytes=nchar(x,"b"),chars=nchar(x,"c"),
             width=nchar(x,"w"),raw=paste(charToRaw(x),collapse=":"))
    print(t(as.matrix(details)))
}
```
## Character vector encoding
Character strings in R can be declared to be encoded in `"latin1"` or `"UTF-8"` or as `"bytes"`.

An encoded character string contains characters beyond the basic ASCII characters. For instance, the string `"Maurício"` contains an _**i-acute**_.

When assigning an string to a name, it is marked with the native encoding indicated in `l10n_info()`, except for ASCII strings which are allways marked as `"unknown"`.

```r
x <- "Maurício"
c(x, Encoding(x))
```

```
[1] "Maurício" "latin1"  
```
### ASCII strings
ASCII strings will never be marked with a declared encoding, since their representation is the same in all supported encodings. 

```r
x <- "ABC"
Encoding(c(x, enc2native(x), enc2utf8(x)))
```

```
[1] "unknown" "unknown" "unknown"
```
### Escaped strings
The string `"Maurício"` is escaped `"Maur\xEDcio"` if intended to be in `"latin1"` encoding and `"Maur\xC3\xADcio"` if intended to be in `"UTF-8"` encoding, therefore, they should be marked accordingly with `Encoding()<-` to let them portable between different encoding locales.

If your native encoding is `"latin1"`

```r
x <- "Maur\xC3\xADcio"
Encoding(x) <- "UTF-8"
details(x)
```

```
     x          encoding bytes chars width raw                         
[1,] "Maurício" "UTF-8"  9     8     8     "4d:61:75:72:c3:ad:63:69:6f"
```
If your native encoding is `"UTF-8"`.

```r
x <- "Maur\xEDcio"
Encoding(x) <- "latin1"
details(x)
```

```
     x          encoding bytes chars width raw                      
[1,] "Maurício" "latin1" 8     8     8     "4d:61:75:72:ed:63:69:6f"
```
### Converting encoded strings
Base R provides `enc2native()` and `enc2utf8()` but doesn't provide an `"enc2latin1()"`.  Therefore, one can use `iconv()` but must use the `from` argument with careful because it must match the correct encoding mark of the input string, doesn't accept `"unknown"` and be aware that its result is platform dependent.  More details in `help(iconv)`.

From `"latin1"` to `"UTF-8"`.

```r
x <- "Maur\xEDcio"
Encoding(x) <- "latin1"
details(x)
```

```
     x          encoding bytes chars width raw                      
[1,] "Maurício" "latin1" 8     8     8     "4d:61:75:72:ed:63:69:6f"
```

```r
x <- enc2utf8(x)
details(x)
```

```
     x          encoding bytes chars width raw                         
[1,] "Maurício" "UTF-8"  9     8     8     "4d:61:75:72:c3:ad:63:69:6f"
```

From `"UTF-8"` to `"latin1"`.

```r
x <- "Maur\xC3\xADcio"
Encoding(x) <- "UTF-8"
details(x)
```

```
     x          encoding bytes chars width raw                         
[1,] "Maurício" "UTF-8"  9     8     8     "4d:61:75:72:c3:ad:63:69:6f"
```

```r
x <- iconv(x, from=Encoding(x), to="latin1", sub="byte")
details(x)
```

```
     x          encoding bytes chars width raw                      
[1,] "Maurício" "latin1" 8     8     8     "4d:61:75:72:ed:63:69:6f"
```
## Internationalization Convertion Test
From `help(iconvlist)`: On most platforms iconvlist provides an alphabetical list of the supported encodings. On others, the information is on the man page for iconv(5) or elsewhere in the man pages (but beware that the system command iconv may not support the same set of encodings as the C functions R calls). Unfortunately, the names are rarely supported across all platforms.  Value for iconvlist(), a character vector (typically of a few hundred elements) of known encoding names.

Number of suposed supported encodings.

```r
(encodings <- length(iconvlist()))
```

```
[1] 374
```
Number of unique supported encodings may be differ.

```r
length(unique(iconvlist()))
```

```
[1] 365
```
### Test string "Maurício" as "latin1"

```r
x <- "Maur\xEDcio"
Encoding(x) <- "latin1"
details(x)
```

```
     x          encoding bytes chars width raw                      
[1,] "Maurício" "latin1" 8     8     8     "4d:61:75:72:ed:63:69:6f"
```
Trying to convert the string in 374 supposedly supported target encodings.

```r
results <- 
    sapply(iconvlist(),
           function(to)
               try(iconv(x, from = Encoding(x), to = to), silent = TRUE))
```
### Target locales that produce R runtime errors

```r
sum(isErrors <- grepl("^Error in iconv", results))
```

```
[1] 48
```

```r
errors <- results[isErrors]
names(errors)
```

```
 [1] "CP-GR"          "CP-IS"          "cp1025"         "CP1125"        
 [5] "CP1133"         "CP1200"         "CP12000"        "CP12001"       
 [9] "CP1201"         "CP154"          "CP367"          "CP819"         
[13] "CP853"          "CSPTCP154"      "CYRILLIC-ASIAN" "EUC-CN"        
[17] "EUCCN"          "IBM-CP1133"     "PT154"          "PTCP154"       
[21] "UCS-2"          "UCS-2BE"        "UCS-2LE"        "UCS-4"         
[25] "UCS-4BE"        "UCS-4BE"        "UCS-4LE"        "UCS-4LE"       
[29] "UCS2"           "UCS2BE"         "UCS2LE"         "UCS4"          
[33] "UCS4BE"         "UCS4LE"         "unicodeFFFE"    "UTF-16"        
[37] "UTF-16BE"       "UTF-16LE"       "UTF-32"         "UTF-32BE"      
[41] "UTF-32LE"       "UTF16"          "UTF16BE"        "UTF16LE"       
[45] "UTF32"          "UTF32BE"        "UTF32LE"        "x-Europa"      
```
Runtime error messages

```r
errors <-
    gsub("Error in iconv\\(x, from = Encoding\\(x), to = to) : \n  |\n",
         "", errors)
cat(errors, fill = TRUE, labels=paste0(names(errors), ": "))
```

```
CP-GR:  unsupported conversion from 'latin1' to 'CP-GR' in codepage 1252 
CP-IS:  unsupported conversion from 'latin1' to 'CP-IS' in codepage 1252 
cp1025:  unsupported conversion from 'latin1' to 'cp1025' in codepage 1252 
CP1125:  unsupported conversion from 'latin1' to 'CP1125' in codepage 1252 
CP1133:  unsupported conversion from 'latin1' to 'CP1133' in codepage 1252 
CP1200:  embedded nul in string: 'M\0a\0u\0r\0í\0c\0i\0o\0' 
CP12000:  embedded nul in string: 'M\0\0\0a\0\0\0u\0\0\0r\0\0\0í\0\0\0c\0\0\0i\0\0\0o\0\0\0' 
CP12001:  embedded nul in string: '\0\0\0M\0\0\0a\0\0\0u\0\0\0r\0\0\0í\0\0\0c\0\0\0i\0\0\0o' 
CP1201:  embedded nul in string: '\0M\0a\0u\0r\0í\0c\0i\0o' 
CP154:  unsupported conversion from 'latin1' to 'CP154' in codepage 1252 
CP367:  unsupported conversion from 'latin1' to 'CP367' in codepage 1252 
CP819:  unsupported conversion from 'latin1' to 'CP819' in codepage 1252 
CP853:  unsupported conversion from 'latin1' to 'CP853' in codepage 1252 
CSPTCP154:  unsupported conversion from 'latin1' to 'CSPTCP154' in codepage 1252 
CYRILLIC-ASIAN:  unsupported conversion from 'latin1' to 'CYRILLIC-ASIAN' in codepage 1252 
EUC-CN:  unsupported conversion from 'latin1' to 'EUC-CN' in codepage 1252 
EUCCN:  unsupported conversion from 'latin1' to 'EUCCN' in codepage 1252 
IBM-CP1133:  unsupported conversion from 'latin1' to 'IBM-CP1133' in codepage 1252 
PT154:  unsupported conversion from 'latin1' to 'PT154' in codepage 1252 
PTCP154:  unsupported conversion from 'latin1' to 'PTCP154' in codepage 1252 
UCS-2:  embedded nul in string: 'þÿ\0M\0a\0u\0r\0í\0c\0i\0o' 
UCS-2BE:  embedded nul in string: '\0M\0a\0u\0r\0í\0c\0i\0o' 
UCS-2LE:  embedded nul in string: 'M\0a\0u\0r\0í\0c\0i\0o\0' 
UCS-4:  embedded nul in string: '\0\0þÿ\0\0\0M\0\0\0a\0\0\0u\0\0\0r\0\0\0í\0\0\0c\0\0\0i\0\0\0o' 
UCS-4BE:  embedded nul in string: '\0\0\0M\0\0\0a\0\0\0u\0\0\0r\0\0\0í\0\0\0c\0\0\0i\0\0\0o' 
UCS-4BE:  embedded nul in string: '\0\0\0M\0\0\0a\0\0\0u\0\0\0r\0\0\0í\0\0\0c\0\0\0i\0\0\0o' 
UCS-4LE:  embedded nul in string: 'M\0\0\0a\0\0\0u\0\0\0r\0\0\0í\0\0\0c\0\0\0i\0\0\0o\0\0\0' 
UCS-4LE:  embedded nul in string: 'M\0\0\0a\0\0\0u\0\0\0r\0\0\0í\0\0\0c\0\0\0i\0\0\0o\0\0\0' 
UCS2:  embedded nul in string: 'þÿ\0M\0a\0u\0r\0í\0c\0i\0o' 
UCS2BE:  embedded nul in string: '\0M\0a\0u\0r\0í\0c\0i\0o' 
UCS2LE:  embedded nul in string: 'M\0a\0u\0r\0í\0c\0i\0o\0' 
UCS4:  embedded nul in string: '\0\0þÿ\0\0\0M\0\0\0a\0\0\0u\0\0\0r\0\0\0í\0\0\0c\0\0\0i\0\0\0o' 
UCS4BE:  embedded nul in string: '\0\0\0M\0\0\0a\0\0\0u\0\0\0r\0\0\0í\0\0\0c\0\0\0i\0\0\0o' 
UCS4LE:  embedded nul in string: 'M\0\0\0a\0\0\0u\0\0\0r\0\0\0í\0\0\0c\0\0\0i\0\0\0o\0\0\0' 
unicodeFFFE:  embedded nul in string: '\0M\0a\0u\0r\0í\0c\0i\0o' 
UTF-16:  embedded nul in string: 'þÿ\0M\0a\0u\0r\0í\0c\0i\0o' 
UTF-16BE:  embedded nul in string: '\0M\0a\0u\0r\0í\0c\0i\0o' 
UTF-16LE:  embedded nul in string: 'M\0a\0u\0r\0í\0c\0i\0o\0' 
UTF-32:  embedded nul in string: '\0\0þÿ\0\0\0M\0\0\0a\0\0\0u\0\0\0r\0\0\0í\0\0\0c\0\0\0i\0\0\0o' 
UTF-32BE:  embedded nul in string: '\0\0\0M\0\0\0a\0\0\0u\0\0\0r\0\0\0í\0\0\0c\0\0\0i\0\0\0o' 
UTF-32LE:  embedded nul in string: 'M\0\0\0a\0\0\0u\0\0\0r\0\0\0í\0\0\0c\0\0\0i\0\0\0o\0\0\0' 
UTF16:  embedded nul in string: 'þÿ\0M\0a\0u\0r\0í\0c\0i\0o' 
UTF16BE:  embedded nul in string: '\0M\0a\0u\0r\0í\0c\0i\0o' 
UTF16LE:  embedded nul in string: 'M\0a\0u\0r\0í\0c\0i\0o\0' 
UTF32:  embedded nul in string: '\0\0þÿ\0\0\0M\0\0\0a\0\0\0u\0\0\0r\0\0\0í\0\0\0c\0\0\0i\0\0\0o' 
UTF32BE:  embedded nul in string: '\0\0\0M\0\0\0a\0\0\0u\0\0\0r\0\0\0í\0\0\0c\0\0\0i\0\0\0o' 
UTF32LE:  embedded nul in string: 'M\0\0\0a\0\0\0u\0\0\0r\0\0\0í\0\0\0c\0\0\0i\0\0\0o\0\0\0' 
x-Europa:  unsupported conversion from 'latin1' to 'x-Europa' in codepage 1252
```
### Target locales that cannot convert all bytes
It is due to character strings that cannot be converted because of any of their bytes that cannot be represented in the target encoding, producing `NA` results.

```r
sum(isNAs <- is.na(results))
```

```
[1] 84
```

```r
names(results[isNAs])
```

```
 [1] "ANSI_X3.4-1968"          "ANSI_X3.4-1986"         
 [3] "ASCII"                   "ASMO-708"               
 [5] "CP1255"                  "CP1256"                 
 [7] "CP1257"                  "CP1361"                 
 [9] "CP50221"                 "CP737"                  
[11] "CP775"                   "CP864"                  
[13] "CP874"                   "cp875"                  
[15] "CSASCII"                 "CSIBM864"               
[17] "csISO2022JP"             "CSPC775BALTIC"          
[19] "DOS-720"                 "hz-gb-2312"             
[21] "IBM-Thai"                "IBM290"                 
[23] "IBM367"                  "IBM420"                 
[25] "IBM423"                  "IBM424"                 
[27] "ibm737"                  "ibm775"                 
[29] "IBM775"                  "IBM864"                 
[31] "IBM864"                  "IBM880"                 
[33] "iso-2022-jp"             "iso-2022-jp"            
[35] "ISO-2022-JP"             "ISO-2022-JP-MS"         
[37] "iso-2022-kr"             "ISO-IR-6"               
[39] "ISO_646.IRV:1991"        "ISO2022-JP"             
[41] "ISO2022-JP-MS"           "iso2022-kr"             
[43] "ISO646-US"               "Johab"                  
[45] "JOHAB"                   "maccyrillic"            
[47] "macgreek"                "macthai"                
[49] "macukraine"              "macukrainian"           
[51] "MS-ARAB"                 "MS-HEBR"                
[53] "MS50221"                 "US"                     
[55] "US-ASCII"                "WINBALTRIM"             
[57] "windows-1255"            "windows-1256"           
[59] "windows-1257"            "WINDOWS-50221"          
[61] "windows-874"             "x-Chinese_CNS"          
[63] "x-cp20001"               "x-cp20003"              
[65] "x-cp20004"               "x-cp20005"              
[67] "x-cp20269"               "x-cp50227"              
[69] "x-EBCDIC-KoreanExtended" "x-iscii-as"             
[71] "x-iscii-be"              "x-iscii-de"             
[73] "x-iscii-gu"              "x-iscii-ka"             
[75] "x-iscii-ma"              "x-iscii-or"             
[77] "x-iscii-pa"              "x-iscii-ta"             
[79] "x-iscii-te"              "x-mac-cyrillic"         
[81] "x-mac-greek"             "x-mac-thai"             
[83] "x-mac-ukrainian"         "x_Chinese-Eten"         
```
Here it is used the `sub = "byte"` argument to replace any non-convertible byte in the input with its hex code indicated with `"<xx>"` in order to inspect which bytes in the input are non-convertible.

```r
results2 <- 
    sapply(iconvlist(),
           function(to)
               try(iconv(x, from = Encoding(x), to = to, sub = "byte"),
                   silent = TRUE))
```

```r
nonconvertibles <- results2[isNAs]
```
Contingency table of non-convertible strings.

```r
table(nonconvertibles)
```

```
nonconvertibles
<4d><61><75><72><ed><63><69><6f>                      Maur<ed>cio 
                              14                               62 
                     Ô¤<ed>                      Ôb´<ed>dqw 
                               7                                1 
```
Target locales grouped by non-convertible strings

```r
split(names(nonconvertibles), nonconvertibles)
```

```
$`<4d><61><75><72><ed><63><69><6f>`
 [1] "hz-gb-2312"  "iso-2022-kr" "iso2022-kr"  "x-cp50227"   "x-iscii-as" 
 [6] "x-iscii-be"  "x-iscii-de"  "x-iscii-gu"  "x-iscii-ka"  "x-iscii-ma" 
[11] "x-iscii-or"  "x-iscii-pa"  "x-iscii-ta"  "x-iscii-te" 

$`Maur<ed>cio`
 [1] "ANSI_X3.4-1968"   "ANSI_X3.4-1986"   "ASCII"           
 [4] "ASMO-708"         "CP1255"           "CP1256"          
 [7] "CP1257"           "CP1361"           "CP50221"         
[10] "CP737"            "CP775"            "CP864"           
[13] "CP874"            "CSASCII"          "CSIBM864"        
[16] "csISO2022JP"      "CSPC775BALTIC"    "DOS-720"         
[19] "IBM367"           "ibm737"           "ibm775"          
[22] "IBM775"           "IBM864"           "IBM864"          
[25] "iso-2022-jp"      "iso-2022-jp"      "ISO-2022-JP"     
[28] "ISO-2022-JP-MS"   "ISO-IR-6"         "ISO_646.IRV:1991"
[31] "ISO2022-JP"       "ISO2022-JP-MS"    "ISO646-US"       
[34] "Johab"            "JOHAB"            "maccyrillic"     
[37] "macgreek"         "macthai"          "macukraine"      
[40] "macukrainian"     "MS-ARAB"          "MS-HEBR"         
[43] "MS50221"          "US"               "US-ASCII"        
[46] "WINBALTRIM"       "windows-1255"     "windows-1256"    
[49] "windows-1257"     "WINDOWS-50221"    "windows-874"     
[52] "x-Chinese_CNS"    "x-cp20001"        "x-cp20003"       
[55] "x-cp20004"        "x-cp20005"        "x-cp20269"       
[58] "x-mac-cyrillic"   "x-mac-greek"      "x-mac-thai"      
[61] "x-mac-ukrainian"  "x_Chinese-Eten"  

$`Ô¤<ed>`
[1] "cp875"                   "IBM-Thai"               
[3] "IBM420"                  "IBM423"                 
[5] "IBM424"                  "IBM880"                 
[7] "x-EBCDIC-KoreanExtended"

$`Ôb´<ed>dqw`
[1] "IBM290"
```
### Target locales that encoded "unknown"

```r
sum(isUnknown <- !isNAs & !isErrors & Encoding(results) == "unknown")
```

```
[1] 238
```

```r
names(unknown <- results[isUnknown])
```

```
  [1] "437"                 "850"                 "852"                
  [4] "855"                 "857"                 "860"                
  [7] "861"                 "862"                 "863"                
 [10] "865"                 "866"                 "869"                
 [13] "BIG-5"               "BIG-FIVE"            "big5"               
 [16] "BIG5"                "big5-hkscs"          "BIG5-HKSCS"         
 [19] "big5hkscs"           "BIG5HKSCS"           "CP1250"             
 [22] "CP1251"              "CP1253"              "CP1254"             
 [25] "CP1258"              "CP437"               "CP51932"            
 [28] "CP65001"             "CP850"               "CP852"              
 [31] "CP855"               "CP857"               "CP858"              
 [34] "CP860"               "CP861"               "CP862"              
 [37] "CP863"               "CP865"               "cp866"              
 [40] "CP866"               "CP869"               "CP932"              
 [43] "CP936"               "CP949"               "CP950"              
 [46] "CSIBM855"            "CSIBM857"            "CSIBM860"           
 [49] "CSIBM861"            "CSIBM863"            "CSIBM865"           
 [52] "CSIBM866"            "CSIBM869"            "CSISOLATIN1"        
 [55] "CSPC850MULTILINGUAL" "CSPC862LATINHEBREW"  "CSPC8CODEPAGE437"   
 [58] "CSPCP852"            "CSWINDOWS31J"        "DOS-862"            
 [61] "euc-jp"              "euc-kr"              "EUC-KR"             
 [64] "eucjp"               "euckr"               "GB18030"            
 [67] "gb2312"              "GBK"                 "IBM00858"           
 [70] "IBM00924"            "IBM01047"            "IBM01140"           
 [73] "IBM01141"            "IBM01142"            "IBM01143"           
 [76] "IBM01144"            "IBM01145"            "IBM01146"           
 [79] "IBM01147"            "IBM01148"            "IBM01149"           
 [82] "IBM037"              "IBM1026"             "IBM273"             
 [85] "IBM277"              "IBM278"              "IBM280"             
 [88] "IBM284"              "IBM285"              "IBM297"             
 [91] "IBM437"              "IBM437"              "IBM500"             
 [94] "IBM819"              "ibm850"              "IBM850"             
 [97] "ibm852"              "IBM852"              "IBM855"             
[100] "IBM855"              "ibm857"              "IBM857"             
[103] "IBM860"              "IBM860"              "ibm861"             
[106] "IBM861"              "IBM862"              "IBM863"             
[109] "IBM863"              "IBM865"              "IBM865"             
[112] "IBM866"              "ibm869"              "IBM869"             
[115] "IBM870"              "IBM871"              "IBM905"             
[118] "ISO-8859-1"          "iso-8859-13"         "iso-8859-15"        
[121] "iso-8859-2"          "iso-8859-3"          "iso-8859-4"         
[124] "iso-8859-5"          "iso-8859-6"          "iso-8859-7"         
[127] "iso-8859-8"          "iso-8859-8-i"        "iso-8859-9"         
[130] "ISO-IR-100"          "iso_8859-1"          "ISO_8859-1:1987"    
[133] "iso_8859-13"         "iso_8859-15"         "iso_8859-2"         
[136] "iso_8859-3"          "iso_8859-4"          "iso_8859-5"         
[139] "iso_8859-6"          "iso_8859-7"          "iso_8859-8"         
[142] "iso_8859-8-i"        "iso_8859-9"          "iso_8859_1"         
[145] "iso_8859_13"         "iso_8859_15"         "iso_8859_2"         
[148] "iso_8859_3"          "iso_8859_4"          "iso_8859_5"         
[151] "iso_8859_6"          "iso_8859_7"          "iso_8859_8"         
[154] "iso_8859_8-i"        "iso_8859_9"          "iso8859-1"          
[157] "ISO8859-1"           "iso8859-13"          "iso8859-15"         
[160] "iso8859-2"           "iso8859-3"           "iso8859-4"          
[163] "iso8859-5"           "iso8859-6"           "iso8859-7"          
[166] "iso8859-8"           "iso8859-8-i"         "iso8859-9"          
[169] "koi8-r"              "koi8-u"              "ks_c_5601-1987"     
[172] "L1"                  "latin-9"             "LATIN1"             
[175] "latin2"              "latin3"              "latin4"             
[178] "latin5"              "latin7"              "latin9"             
[181] "mac"                 "mac-centraleurope"   "mac-is"             
[184] "macarabic"           "maccentraleurope"    "maccroatian"        
[187] "machebrew"           "maciceland"          "macintosh"          
[190] "macis"               "macroman"            "macromania"         
[193] "macturkish"          "MS-ANSI"             "MS-CYRL"            
[196] "MS-EE"               "MS-GREEK"            "MS-TURK"            
[199] "MS51932"             "MS932"               "MS936"              
[202] "SHIFFT_JIS"          "SHIFFT_JIS-MS"       "shift-jis"          
[205] "shift_jis"           "SJIS"                "SJIS-MS"            
[208] "SJIS-OPEN"           "SJIS-WIN"            "UHC"                
[211] "windows-1250"        "windows-1251"        "windows-1252"       
[214] "windows-1253"        "windows-1254"        "windows-1258"       
[217] "WINDOWS-31J"         "WINDOWS-51932"       "WINDOWS-932"        
[220] "WINDOWS-936"         "x-cp20261"           "x-cp20936"          
[223] "x-cp20949"           "x-IA5"               "x-IA5-German"       
[226] "x-IA5-Norwegian"     "x-IA5-Swedish"       "x-mac-arabic"       
[229] "x-mac-ce"            "x-mac-chinesesimp"   "x-mac-chinesetrad"  
[232] "x-mac-croatian"      "x-mac-hebrew"        "x-mac-icelandic"    
[235] "x-mac-japanese"      "x-mac-korean"        "x-mac-romanian"     
[238] "x-mac-turkish"      
```
Contingency table of results encoded "unknown"

```r
table(unknown)
```

```
unknown
 Maur¡cio Maur¨ªcio  Maurcio MaurÃ­cio MaurÂicio  Mauricio  Maurício 
       42         8        20         1         1        94        47 
 Ô¤U 
       25 
```
Target locales grouped by results encoded "unknown"

```r
split(names(unknown), unknown)
```

```
$`Maur¡cio`
 [1] "437"                 "850"                 "852"                
 [4] "857"                 "860"                 "861"                
 [7] "862"                 "865"                 "CP437"              
[10] "CP850"               "CP852"               "CP857"              
[13] "CP858"               "CP860"               "CP861"              
[16] "CP862"               "CP865"               "CSIBM857"           
[19] "CSIBM860"            "CSIBM861"            "CSIBM865"           
[22] "CSPC850MULTILINGUAL" "CSPC862LATINHEBREW"  "CSPC8CODEPAGE437"   
[25] "CSPCP852"            "DOS-862"             "IBM00858"           
[28] "IBM437"              "IBM437"              "ibm850"             
[31] "IBM850"              "ibm852"              "IBM852"             
[34] "ibm857"              "IBM857"              "IBM860"             
[37] "IBM860"              "ibm861"              "IBM861"             
[40] "IBM862"              "IBM865"              "IBM865"             

$`Maur¨ªcio`
[1] "CP936"             "GB18030"           "gb2312"           
[4] "GBK"               "MS936"             "WINDOWS-936"      
[7] "x-cp20936"         "x-mac-chinesesimp"

$`Maurcio`
 [1] "mac"               "mac-centraleurope" "mac-is"           
 [4] "macarabic"         "maccentraleurope"  "maccroatian"      
 [7] "machebrew"         "maciceland"        "macintosh"        
[10] "macis"             "macroman"          "macromania"       
[13] "macturkish"        "x-mac-arabic"      "x-mac-ce"         
[16] "x-mac-croatian"    "x-mac-hebrew"      "x-mac-icelandic"  
[19] "x-mac-romanian"    "x-mac-turkish"    

$`MaurÃ­cio`
[1] "CP65001"

$MaurÂicio
[1] "x-cp20261"

$Mauricio
 [1] "855"               "863"               "866"              
 [4] "869"               "BIG-5"             "BIG-FIVE"         
 [7] "big5"              "BIG5"              "big5-hkscs"       
[10] "BIG5-HKSCS"        "big5hkscs"         "BIG5HKSCS"        
[13] "CP1251"            "CP1253"            "CP51932"          
[16] "CP855"             "CP863"             "cp866"            
[19] "CP866"             "CP869"             "CP932"            
[22] "CP949"             "CP950"             "CSIBM855"         
[25] "CSIBM863"          "CSIBM866"          "CSIBM869"         
[28] "CSWINDOWS31J"      "euc-jp"            "euc-kr"           
[31] "EUC-KR"            "eucjp"             "euckr"            
[34] "IBM855"            "IBM855"            "IBM863"           
[37] "IBM863"            "IBM866"            "ibm869"           
[40] "IBM869"            "iso-8859-13"       "iso-8859-5"       
[43] "iso-8859-6"        "iso-8859-7"        "iso-8859-8"       
[46] "iso-8859-8-i"      "iso_8859-13"       "iso_8859-5"       
[49] "iso_8859-6"        "iso_8859-7"        "iso_8859-8"       
[52] "iso_8859-8-i"      "iso_8859_13"       "iso_8859_5"       
[55] "iso_8859_6"        "iso_8859_7"        "iso_8859_8"       
[58] "iso_8859_8-i"      "iso8859-13"        "iso8859-5"        
[61] "iso8859-6"         "iso8859-7"         "iso8859-8"        
[64] "iso8859-8-i"       "koi8-r"            "koi8-u"           
[67] "ks_c_5601-1987"    "latin7"            "MS-CYRL"          
[70] "MS-GREEK"          "MS51932"           "MS932"            
[73] "SHIFFT_JIS"        "SHIFFT_JIS-MS"     "shift-jis"        
[76] "shift_jis"         "SJIS"              "SJIS-MS"          
[79] "SJIS-OPEN"         "SJIS-WIN"          "UHC"              
[82] "windows-1251"      "windows-1253"      "WINDOWS-31J"      
[85] "WINDOWS-51932"     "WINDOWS-932"       "x-cp20949"        
[88] "x-IA5"             "x-IA5-German"      "x-IA5-Norwegian"  
[91] "x-IA5-Swedish"     "x-mac-chinesetrad" "x-mac-japanese"   
[94] "x-mac-korean"     

$Maurício
 [1] "CP1250"          "CP1254"          "CP1258"         
 [4] "CSISOLATIN1"     "IBM819"          "ISO-8859-1"     
 [7] "iso-8859-15"     "iso-8859-2"      "iso-8859-3"     
[10] "iso-8859-4"      "iso-8859-9"      "ISO-IR-100"     
[13] "iso_8859-1"      "ISO_8859-1:1987" "iso_8859-15"    
[16] "iso_8859-2"      "iso_8859-3"      "iso_8859-4"     
[19] "iso_8859-9"      "iso_8859_1"      "iso_8859_15"    
[22] "iso_8859_2"      "iso_8859_3"      "iso_8859_4"     
[25] "iso_8859_9"      "iso8859-1"       "ISO8859-1"      
[28] "iso8859-15"      "iso8859-2"       "iso8859-3"      
[31] "iso8859-4"       "iso8859-9"       "L1"             
[34] "latin-9"         "LATIN1"          "latin2"         
[37] "latin3"          "latin4"          "latin5"         
[40] "latin9"          "MS-ANSI"         "MS-EE"          
[43] "MS-TURK"         "windows-1250"    "windows-1252"   
[46] "windows-1254"    "windows-1258"   

$`Ô¤U`
 [1] "IBM00924" "IBM01047" "IBM01140" "IBM01141" "IBM01142" "IBM01143"
 [7] "IBM01144" "IBM01145" "IBM01146" "IBM01147" "IBM01148" "IBM01149"
[13] "IBM037"   "IBM1026"  "IBM273"   "IBM277"   "IBM278"   "IBM280"  
[19] "IBM284"   "IBM285"   "IBM297"   "IBM500"   "IBM870"   "IBM871"  
[25] "IBM905"  
```
### Target locales that encoded as native "latin1"

```r
sum(isUnchanged <- !isNAs & !isErrors & Encoding(results) == native)
```

```
[1] 2
```

```r
names(unchanged <- results[isUnchanged])
```

```
[1] "CP1252"     "ISO_8859-1"
```
Contingency table of results encoded as native "latin1"

```r
table(unchanged)
```

```
unchanged
Maurício 
       2 
```
Target locales grouped by results encoded as native "latin1"

```r
split(names(unchanged), unchanged)
```

```
$Maurício
[1] "CP1252"     "ISO_8859-1"
```
### Target locales that produced new encodings different from "unknown"

```r
sum(isRemarked <- !isNAs & !isErrors & Encoding(results) != native
    & Encoding(results) != "unknown")
```

```
[1] 2
```

```r
names(remarked <- results[isRemarked])
```

```
[1] "UTF-8" "UTF8" 
```
Contingency table of results with new encoding

```r
table(remarked)
```

```
remarked
Maurício 
       2 
```
Target locales grouped by new encodings different from "unknown"

```r
split(names(remarked), remarked)
```

```
$Maurício
[1] "UTF-8" "UTF8" 
```
### Function to list real supported encodings 
As one can see through the tests above, `iconvlist()` returns an unsafe list of encodings that may even `stop()` your R code.  All these tests made possible to develop a wrapper function to list the really supported encodings from a source encoding (defaults to `from=Encoding(x)`) to all suposedly supported encodings for the current platform by avoiding runtime errors and non-convertible strings.

```r
safe.iconvlist <- function(x, from = Encoding(x)) {
    stopifnot(is.character(x))
    from <- switch(from, "unknown" = "", from)
    results <- 
        sapply(iconvlist(), 
               function(to) try(iconv(x, from = from, to = to), silent = TRUE))
    results <- results[(!is.na(results) & !grepl("^Error in iconv", results))]
    return(names(results))
}
```
#### safe.iconvlist() test for latin1 characters strings
The test strings are defined by the ISO-8859-1 codepoints: https://en.wikipedia.org/wiki/ISO/IEC_8859-1

```r
ISO88591 <- list(
    alphabetic = c(65:90,97:122),
    numeric = c(48:57),
    punctuation = c(32:47, 58:64, 91:96, 123:126, 178:179, 185),
    extended.punctuation = c(160:169, 171:177, 180, 182:184, 187:191, 215, 247),
    international = c(170, 181, 186, 192:214, 216:246, 248:255),
    undefined = c(0:31, 127:159))
```
Number of ISO-8859-1 codepoints

```r
sapply(ISO88591, length)
```

```
          alphabetic              numeric          punctuation 
                  52                   10                   36 
extended.punctuation        international            undefined 
                  28                   65                   65 
```

```r
sum(sapply(ISO88591, length))
```

```
[1] 256
```
Character strings created from raw vectors are marked "unknown"

```r
ISO88591 <- lapply(ISO88591, function(x)
    paste0(rawToChar(as.raw(x), multiple = TRUE), collapse = ""))
sapply(ISO88591, function(x) Encoding(x))
```

```
          alphabetic              numeric          punctuation 
           "unknown"            "unknown"            "unknown" 
extended.punctuation        international            undefined 
           "unknown"            "unknown"            "unknown" 
```
Therefore they should be marked as "latin1" wherever possible for the test

```r
ISO88591 <- lapply(ISO88591, function(x) { Encoding(x) <- "latin1"; x })
sapply(ISO88591, function(x) Encoding(x))
```

```
          alphabetic              numeric          punctuation 
           "unknown"            "unknown"             "latin1" 
extended.punctuation        international            undefined 
            "latin1"             "latin1"             "latin1" 
```
Number of real supported encodings for the test strings.

```r
sapply(ISO88591, function(x) length(safe.iconvlist(x)))
```

```
          alphabetic              numeric          punctuation 
                 312                  312                  211 
extended.punctuation        international            undefined 
                  81                  121                  103 
```
A merged test string shows real supported encondings for the full ISO-88591 character set.

```r
safe.iconvlist(paste0(ISO88591, collapse=""))
```

```
 [1] "CP65001"         "CSISOLATIN1"     "GB18030"        
 [4] "IBM01047"        "IBM037"          "IBM273"         
 [7] "IBM277"          "IBM278"          "IBM280"         
[10] "IBM284"          "IBM285"          "IBM297"         
[13] "IBM500"          "IBM871"          "ISO-8859-1"     
[16] "ISO-IR-100"      "iso_8859-1"      "ISO_8859-1"     
[19] "ISO_8859-1:1987" "iso_8859_1"      "iso8859-1"      
[22] "ISO8859-1"       "L1"              "LATIN1"         
[25] "UTF-8"           "UTF8"           
```
#### safe.iconvlist() test for UTF-8 character strings
The test strings are based on Basic Multilingual Plane (BMP) which contains characters for almost all modern languages, and a large number of symbols. Most of the assigned code points in the BMP are used to encode Chinese, Japanese, and Korean (CJK) characters. https://en.wikipedia.org/wiki/UTF-8.  

```r
UTF8 <- list(
    onebyte.BMP.ASCII = c(0x0000:0x007F),
    twobytes.BMP = c(0x0080:0x07FF), 
    threebytes.BMP = c(0x0800:0x085F, 0x08A0:0x1C8F, 0x1CC0:0x2FDF,
                       0x2FF0:0xD7FF, 0xF900:0xFFFF))
```
There is large number of assigned UTF-8 codepoints:

```r
sapply(UTF8, length)
```

```
onebyte.BMP.ASCII      twobytes.BMP    threebytes.BMP 
              128              1920             54912 
```

```r
sum(sapply(UTF8, length))
```

```
[1] 56960
```
The only test string encoded "unknown" is the ASCII string as expected.

```r
UTF8 <- lapply(UTF8, intToUtf8)
sapply(UTF8, function(x) Encoding(x))
```

```
onebyte.BMP.ASCII      twobytes.BMP    threebytes.BMP 
        "unknown"           "UTF-8"           "UTF-8" 
```
Number of real supported encodings for the test strings.

```r
sapply(UTF8, function(x) length(safe.iconvlist(x)))
```

```
onebyte.BMP.ASCII      twobytes.BMP    threebytes.BMP 
              292                 4                 4 
```
A merged test string shows real supported encondings for the full UTF-8 character set.

```r
safe.iconvlist(paste0(UTF8, collapse=""))
```

```
[1] "CP65001" "GB18030" "UTF-8"   "UTF8"   
```
