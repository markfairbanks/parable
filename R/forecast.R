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

  # If not a list of mables, split the data
  if (is_mable(.mbl)) {
    workers <- future::nbrOfWorkers()
    num_keys <- tsibble::n_keys(.ts)

    if (num_keys < workers)
      splits <- num_keys
    else
      splits <- workers

    .mbl <- .mbl %>%
      mutate(group_id = row_number() %% splits) %>%
      group_split(group_id, keep = FALSE)
  }

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
