#' Sanity Checks for Players Data
#'
#' Search for duplicated player IDs in a table and attach them to the input data.
#' The function automatically loops over the player ID variable names
#' `r cli::ansi_collapse(relevant_ids())` and searches for duplicated IDs in each
#' of these variables.
#'
#' @param data A data frame, tibble, or data.table consisting of player IDs.
#' The variable names must be one of `r cli::ansi_collapse(relevant_ids())`.
#' @param verbose If `TRUE`, will print success messages and a summary.
#'
#' @seealso [players_validate_extract_duplicated()] to extract tables of
#' duplicated IDs from attributes.
#'
#' @return Returns `data`. duplicated observations will be attached in attributes.
#' @export
players_validate <- function(data, verbose = FALSE){
  vars <- names(data)
  vars <- vars[vars %in% relevant_ids()] |> sort()

  for (check_id in vars) {
    mults <- identify_duplicated(data, check_id, verbose = FALSE)
    if (nrow(mults) == 0){
      if (isTRUE(verbose)) cli::cli_alert_success("No duplicated {.val {check_id}s} found, yay.")
    } else {
      attr_name <- paste0("duplicated_", check_id, "s")
      attr(data, attr_name) <- mults
      cli::cli_alert_warning(
        "There are duplicated {.val {check_id}s} in your data. \\
        Relevant rows are saved in the {.val {attr_name}} attribute.",
        wrap = TRUE
      )
    }
  }
  if (is_duplicated(data) && isTRUE(verbose)){
    cli::cli_alert_info(
      "You can extract relevant attributes with the helper function \\
      {.fun players_validate_extract_duplicated}",
      wrap = TRUE
    )
  }
  data
}

#' Extract Table of duplicated Data
#'
#' @param data A data frame that was checked with [players_validate]
#' @param id ID to extract a table of duplicates. Must be one of
#' `r cli::ansi_collapse(relevant_ids())`
#'
#' @return A table of duplicated IDs, sorted by value of `id`
#' @export
players_validate_extract_duplicated <- function(data,
                                                id = relevant_ids()){
  if (!is_duplicated(data)){
    cli::cli_alert_warning("There is no duplicated data in attributes of \\
                           {.arg data}. Do you need to run \\
                           {.fun players_validate}?",
                           wrap = TRUE)
    return(data)
  }
  id <- rlang::arg_match(id)
  attrs <- attributes(data)
  search_name <- paste0("duplicated_", id, "s")
  if (!search_name %in% names(attrs)){
    cli::cli_alert_warning("Can't extract duplicated {.val {id}s}")
    return(data)
  }
  attrs[[search_name]]
}

is_duplicated <- function(check_df){
  attributes(check_df) |>
    names() |>
    grepl("duplicated_", x = _) |>
    any()
}
