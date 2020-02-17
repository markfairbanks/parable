ts_model <- function(.data, ..., .safely = TRUE){
  nm <- map(enexprs(...), expr_text)
  models <- dots_list(...)

  if(length(models) == 0){
    abort("At least one model must be specified.")
  }
  if(!all(is_mdl <- map_lgl(models, inherits, "mdl_defn"))){
    abort(sprintf("Model definition(s) incorrectly created: %s
Check that specified model(s) are model definitions.", nm[which(!is_mdl)[1]]))
  }

  num_key <- n_keys(.data)
  num_mdl <- length(models)
  num_est <- num_mdl * num_key

  keys <- key(.data)
  .data <- fabletools:::nest_keys(.data, "lst_data")

  if(.safely){
    estimate <- function(dt, mdl){
      out <- safely(fabletools::estimate)(dt, mdl)
      if(is.null(out$result)){
        f <- quo(!!mdl$formula)
        f <- set_env(f, mdl$env)
        out$result <- estimate(dt, null_model(!!f))
      }
      out
    }
  }

  pb <- if(num_est > 1) dplyr::progress_estimated(num_est, min_time = 5) else NULL
  eval_models <- function(models, lst_data){
    map(models, function(model){
      map(lst_data, function(dt, mdl){
        out <- estimate(dt, mdl)
        if(!is.null(pb)){
          pb$tick()$print()
        }
        out
      }, model)
    })
  }

  fits <- eval_models(models, .data[["lst_data"]])
  names(fits) <- ifelse(nchar(names(models)), names(models), nm)

  # Report errors if estimated safely
  if(.safely){
    fits <- imap(fits, function(x, nm){
      err <- map_lgl(x, function(x) !is.null(x[["error"]]))
      if((tot_err <- sum(err)) > 0){
        err_msg <- table(map_chr(x[err], function(x) x[["error"]][["message"]]))
        warn(
          sprintf("%i error%s encountered for %s\n%s\n",
                  tot_err,
                  if(tot_err > 1) sprintf("s (%i unique)", length(err_msg)) else "",
                  nm,
                  paste0("[", err_msg, "] ", names(err_msg), collapse = "\n")
          )
        )
      }
      map(x, function(x) x[["result"]])
    })
  }

  fits <- map(fits, list_of_models)

  .data %>%
    transmute(
      !!!keys,
      !!!fits
    ) %>%
    fabletools::as_mable(keys, names(fits))
}

model_lhs <- function(model){
  f <- model$formula
  if(is_quosure(f)){
    f <- get_expr(f)
  }

  if(is.formula(f)){
    f_lhs(f)
  }
  else{
    f
  }
}

model_rhs <- function(model){
  if(is.formula(model$formula)){
    f_rhs(model$formula)
  }
  else{
    expr(NULL)
  }
}
