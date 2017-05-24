enc <- function(x, encoding = NULL) {
    stopifnot(is.character(x))
    if(is.null(encoding)) return(Encoding(x))
    i <- match(encoding, c("unknown","UTF-8","latin1"))
    valid.encoding <- !is.na(i)
    stopifnot(valid.encoding)
    x <- rawToChar(charToRaw(x))
    Encoding(x) <- encoding
    x
}
test_enc <- function() {
    enc("Maur\xEDcio")
    enc("Maur\xEDcio", NULL)
    try(enc("Maur\xEDcio", NA))
    try(enc("Maur\xEDcio", ""))
    enc("Maur\xEDcio", "unknown")
    enc("Maur\xEDcio", "latin1")
    enc("Maur\xC3\xADcio", "UTF-8")

}
