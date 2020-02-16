#' Forecast
#'
#' @description Forecast in parallel
#'
#' @param .mbl A mable or list of mables
#' @param ... Parameters to pass to `fabletools::forecast()`
#'
#' @md
#' @export
#'
#' @examples
parallel_forecast <- function(.mbl, ...) {

  workers <- future::nbrOfWorkers()
  num_keys <- tsibble::n_keys(.mbl)

  if (num_keys < workers)
    splits <- num_keys
  else
    splits <- workers

  mable_names <- names(.mbl)
  mable_keys <- key_vars(.mbl)
  mable_models <- mable_names[!mable_names %in% mable_keys]

  .mbl <- .mbl %>%
    mutate(group_id = row_number() %% splits) %>%
    group_split(group_id, keep = FALSE) %>%
    map(as_mable, key = all_of(mable_keys), models = all_of(mable_models))

  results <- suppressWarnings(
    future.apply::future_lapply(.mbl, fabletools::forecast, ...) %>%
      map(as_tibble) %>%
      bind_rows() %>%
      mutate(.sd = map_dbl(.distribution, ~ .x[[2]])) %>%
      select(-.distribution)
  )

  future:::ClusterRegistry("stop")
  invisible(gc())

  results
}
