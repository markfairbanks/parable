#' Accuracy
#'
#' @description Get accuracies in parallel
#'
#' @param .mbl A mable or list of mables
#' @param ... Parameters to pass to `fabletools::accuracy()`
#'
#' @md
#' @export
#'
#' @examples
parallel_accuracy <- function(.mbl, ...) {

  # If not a list of mables, split the data
  if (!is.list(.mbl)) {
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

  results <- bind_rows(future_map(.mbl, fabletools::accuracy, ...))

  future:::ClusterRegistry("stop")
  invisible(gc())

  results
}
