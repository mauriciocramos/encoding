safe.iconvlist <- function(x, from = Encoding(x)) {
    stopifnot(is.character(x))
    from <- switch(from, "unknown" = "", from)
    results <- 
        sapply(iconvlist(), 
               function(to) try(iconv(x, from = from, to = to), silent = TRUE))
    results <- results[(!is.na(results) & !grepl("^Error in iconv", results))]
    return(names(results))
}