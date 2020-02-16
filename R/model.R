#' Model
#'
#' @description Model in parallel
#'
#' @param .ts A tsibble
#' @param ... Parameters to pass to `fabletools::model()`
#'
#' @md
#' @export
#'
#' @examples
parallel_model <- function(.ts, ...) {

  if (class(.ts)[1] != "tbl_ts") abort(".ts must be a tsibble")

  # Add check to see if future/furrr is loaded
  workers <- future::nbrOfWorkers()
  num_keys <- tsibble::n_keys(.ts)

  if (num_keys < workers)
    splits <- num_keys
  else
    splits <- workers

  results <- .ts %>%
    group_by_key() %>%
    mutate(group_id = dplyr::group_indices() %% splits) %>%
    ungroup() %>%
    group_split(group_id, keep = FALSE) %>%
    future_map(fabletools::model, ...)

  future:::ClusterRegistry("stop")
  invisible(gc())

  results
}
