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

  if (!is_tsibble(.ts)) abort(".ts must be a tsibble")

  # Add check to see if future/furrr is loaded
  workers <- future::nbrOfWorkers()
  num_keys <- tsibble::n_keys(.ts)

  if (num_keys < workers)
    splits <- num_keys
  else
    splits <- workers

  key_names <- key_vars(.ts)
  model_names <- names(enexprs(...))

  results_mbl <- suppressWarnings(
    .ts %>%
      group_by_key() %>%
      mutate(group_id = dplyr::group_indices() %% splits) %>%
      ungroup() %>%
      group_split(group_id, keep = FALSE) %>%
      future.apply::future_lapply(fabletools::model, ...) %>%
      bind_rows() %>%
      as_mable(key = all_of(key_names), models = model_names)
  )

  list_cols <- colnames(results_mbl)[map_lgl(results_mbl, is_list)]

  for (col in list_cols) {
    results_mbl[[col]] <- fabletools:::add_class(results_mbl[[col]], "lst_mdl")
  }

  future:::ClusterRegistry("stop")
  invisible(gc())

  results_mbl
}
