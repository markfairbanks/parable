# These functions are for internal use only
# Customized versions of those found in rlang

map <- function(.x, .f, ...) {
  .f <- anon_x(.f)

  lapply(.x, .f, ...)
}

map_lgl <- function(.x, .f, ...) {
  .f <- anon_x(.f)

  vapply(.x, .f, logical(1), ...)
}

map_int <- function(.x, .f, ...) {
  .f <- anon_x(.f)

  vapply(.x, .f, integer(1), ...)
}

map_dbl <- function(.x, .f, ...) {
  .f <- anon_x(.f)

  vapply(.x, .f, double(1), ...)
}

map_chr <- function(.x, .f, ...) {
  .f <- anon_x(.f)

  vapply(.x, .f, character(1), ...)
}

map_dfc <- function(.x, .f, ...) {
  .f <- anon_x(.f)
  result_list <- map(.x, .f, ...)
  bind_cols(result_list)
}

map_dfr <- function(.x, .f, ..., .id = NULL) {
  .f <- anon_x(.f)

  result_list<- map(.x, .f, ...)

  bind_rows(result_list, .id = .id)
}

map2 <- function(.x, .y, .f, ...) {
  .f <- anon_xy(.f)

  mapply(.f, .x, .y, MoreArgs = list(...), SIMPLIFY = FALSE)
}

map2_lgl <- function(.x, .y, .f, ...) {
  .f <- anon_xy(.f)

  as.logical(map2(.x, .y, .f, ...))
}

map2_int <- function(.x, .y, .f, ...) {
  .f <- anon_xy(.f)

  as.integer(map2(.x, .y, .f, ...))
}

map2_dbl <- function(.x, .y, .f, ...) {
  .f <- anon_xy(.f)

  as.double(map2(.x, .y, .f, ...))
}

map2_chr <- function(.x, .y, .f, ...) {
  .f <- anon_xy(.f)

  as.character(map2(.x, .y, .f, ...))
}


map2_dfc <- function(.x, .y, .f, ...) {
  .f <- anon_xy(.f)

  result_list <- map2(.x, .y, .f, ...)
  bind_cols(result_list)
}

map2_dfr <- function(.x, .y, .f, ..., .id = NULL) {
  .f <- anon_xy(.f)

  result_list <- map2(.x, .y, .f, ...)
  bind_rows(result_list, .id = .id)
}

anon_x <- function(fn) {
  if (is_formula(fn)) {
    fn %>%
      deparse() %>%
      str_replace("^~", "function(.x)") %>%
      parse_expr() %>%
      eval()
  } else {
    fn
  }
}

anon_xy <- function(fn) {
  if (is_formula(fn)) {
    fn %>%
      deparse() %>%
      str_replace("^~", "function(.x,.y)") %>%
      parse_expr() %>%
      eval()
  } else {
    fn
  }
}
