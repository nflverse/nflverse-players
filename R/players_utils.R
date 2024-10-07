# strip nflverse attributes for tests because timestamp and version cause failures
# .internal.selfref is a data.table attribute that is not necessary in this case
strip_nflverse_attributes <- function(df){
  input_attrs <- names(attributes(df))
  input_remove <- input_attrs[grepl("nflverse|.internal.selfref", input_attrs)]
  attributes(df)[input_remove] <- NULL
  df
}

remove_replicated <- function(df,
                              id = relevant_ids(),
                              verbose = FALSE){
  id <- rlang::arg_match(id)
  mults <- identify_replicated(df = df, id = id, verbose = verbose)
  df |>
    dplyr::filter(!is.na(.data[[id]])) |>
    dplyr::filter(dplyr::n() == 1, .by = {{ id }})
}

identify_replicated <- function(df,
                                id = relevant_ids(),
                                verbose = TRUE){
  id <- rlang::arg_match(id)
  mults <- df |>
    dplyr::filter(!is.na(.data[[id]])) |>
    dplyr::filter(dplyr::n() > 1, .by = {{ id }}) |>
    dplyr::arrange(.data[[id]])
  if (nrow(mults) > 0 && isTRUE(verbose)){
    cli::cli_alert_warning("Found replicated {.val {id}s}")
    print(mults)
  }
  invisible(mults)
}

relevant_ids <- function() c("gsis_id", "pfr_id", "pff_id", "otc_id")
