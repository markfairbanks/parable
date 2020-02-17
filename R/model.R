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

  if (!is_attached("package:future")) abort("future is not loaded")

  workers <- future::nbrOfWorkers()

  if (workers == 1)
    abort("Only 1 core is being used. \n Please run plan(multiprocess) to enable more cores")

  num_keys <- n_keys(.ts)

  if (num_keys < workers)
    splits <- num_keys
  else
    splits <- workers

  key_names <- key_vars(.ts)
  model_names <- names(enexprs(...))

  results_mbl <- suppressWarnings(
    .ts %>%
      group_by_key() %>%
      mutate(group_id = group_indices() %% splits) %>%
      ungroup() %>%
      group_split(group_id, keep = FALSE) %>%
      future.apply::future_lapply(fabletools::model, ...) %>%
      bind_rows() %>%
      as_mable(key = all_of(key_names), models = all_of(model_names))
  )

  list_cols <- colnames(results_mbl)[map_lgl(results_mbl, is_list)]

  for (col in list_cols) {
    results_mbl[[col]] <- new_vctr(results_mbl[[col]], "lst_mdl")
  }

  future:::ClusterRegistry("stop")
  invisible(gc())

  results_mbl
}
