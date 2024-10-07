#' Replace Player IDs with Custom IDs
#'
#' This function replaces player IDs in `players_df` with IDs in `manual_ids`.
#' It replaces the values of the variables `ids_to_replace` in `players_df` with
#' their values in `manual_ids`. Replacement is only done in the value in
#' `manual_ids` is NOT `NA`. Both `players_df` and `manual_ids` require the
#' variable `gsis_id` for the replacement.
#'
#' @param players_df A data.frame with the variables `gsis_id` and at least the
#' variables listed in `ids_to_replace`
#' @param manual_ids A data.frame with the variables `gsis_id` and at least the
#' variables listed in `ids_to_replace`. This defaults to the output of
#' [players_fetch_manual_ids()].
#' @param ids_to_replace Variable names where replacement should be performed
#'
#' @return Returns `players_df` with new values from `manual_ids`
#' @export
players_manual_overwrite <- function(players_df,
                                     manual_ids = players_fetch_manual_ids(),
                                     ids_to_replace = c("pff_id", "pfr_id", "otc_id")){
  for (id_name in ids_to_replace) {
    original <- players_df[[id_name]] |> rlang::set_names(players_df[["gsis_id"]])
    replacement <- manual_ids[[id_name]] |> rlang::set_names(manual_ids[["gsis_id"]])
    players_df[[id_name]] <- overwrite(original, replacement)
  }
  players_df
}

#' Load a JSON File of Manually Maintained Player IDs
#'
#' Parse json file maintained for manual overwrites of player IDs.
#'
#' @details
#' The function searches for the file `players_manual_overwrite.json` in the
#' installed packafe directory. If the file doesn't exist for some reason, the
#' function will download the file from
#' <https://github.com/nflverse/nflverse-players/raw/refs/heads/master/inst/players_manual_overwrite.json>
#'
#' @export
players_fetch_manual_ids <- function(){
  local_file <- system.file("players_manual_overwrite.json", package = "nflverse.players")
  if (file.exists(local_file)) {
    return(jsonlite::read_json(local_file, simplifyVector = TRUE))
  }
  cli::cli_alert_warning("Can't find {.path {local_file}}. Going to fetch \\
                         from GitHub.")
  temp_file <- tempfile("players_json", fileext = "json")
  on.exit(unlink(temp_file))
  curl::curl_fetch_disk(
    url = "https://github.com/nflverse/nflverse-players/raw/refs/heads/master/inst/players_manual_overwrite.json",
    path = temp_file
  )
  jsonlite::read_json(temp_file, simplifyVector = TRUE)
}

overwrite <- function(original_vec, replacement_vec){
  # IF THE REPLACEMENT VALUE IS NOT NA, THEN WE USE THE REPLACEMENT VALUE
  # OTEHRWISE WE STICK WITH THE ORIGINAL VALUE
  unname(replacement_vec[names(original_vec)]) %ifna% original_vec
}

# IF LHS IS NA, THEN USE RHS. ELSE USE LHS
`%ifna%` <- function(lhs, rhs) data.table::fifelse(is.na(lhs), rhs, lhs)
