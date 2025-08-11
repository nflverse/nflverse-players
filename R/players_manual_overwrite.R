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
#' [players_manual_ids_fetch()].
#' @param ids_to_replace Variable names where replacement should be performed.
#' Defaults to `r cli::ansi_collapse(relevant_ids())`
#'
#' @return Returns `players_df` with new values from `manual_ids`
#' @export
players_manual_overwrite <- function(players_df,
                                     manual_ids = players_manual_ids_fetch(),
                                     ids_to_replace = overwrite_ids()){
  for (id_name in ids_to_replace) {
    original <- players_df[[id_name]] |> rlang::set_names(players_df[["gsis_id"]])
    replacement <- manual_ids[[id_name]] |> rlang::set_names(manual_ids[["gsis_id"]])
    players_df[[id_name]] <- overwrite(original, replacement)
  }
  attr(players_df, "manual_overwrite") <- TRUE
  players_df
}

#' Load a JSON File of Manually Maintained Player IDs
#'
#' Parse json file maintained for manual overwrites of player IDs.
#'
#' @details
#' The function searches for the file `players_manual_overwrite.json` in the
#' installed package directory. If the file doesn't exist for some reason, the
#' function will download the file from
#' <https://github.com/nflverse/nflverse-players/raw/refs/heads/master/inst/players_manual_overwrite.json>
#'
#' @export
players_manual_ids_fetch <- function(){
  local_file <- system.file("players_manual_overwrite.json", package = "nflverse.players")
  if (file.exists(local_file)) {
    return(.players_read_json(local_file))
  }
  cli::cli_alert_warning("Can't find {.path {local_file}}. Going to fetch \\
                         from GitHub.")
  temp_file <- tempfile("players_json", fileext = "json")
  on.exit(unlink(temp_file))
  curl::curl_fetch_disk(
    url = "https://github.com/nflverse/nflverse-players/raw/refs/heads/master/inst/players_manual_overwrite.json",
    path = temp_file
  )
  .players_read_json(temp_file)
}

#' Clean JSON File of Manual IDs
#'
#' Load manually maintained player IDs from JSON file and compare them with
#' the automatically matched player IDs. If the automated workflow already matched
#' a player ID that is listed in `manual_ids` then that ID will be removed from
#' the manual ID JSON file.
#'
#' @param manual_ids IDs to clean. Defaults to the output of
#' [players_manual_ids_fetch()]
#'
#' @details
#' If the function detects IDs that can be removed, it will ask the user if the
#' JSON file in `inst/players_manual_overwrite.json` should be overwritten.
#' Changes will be detected from git as the file is version controlled.
#'
#' @return Cleaned dataset invisibly
#' @export
players_manual_ids_clean <- function(manual_ids = players_manual_ids_fetch()){

  pfr <- players_download("pfr") |>
    remove_duplicated("pfr_id")

  espn <- players_download("espn") |>
    remove_duplicated("espn_id")

  otc <- players_download("otc") |>
    dplyr::filter(!is.na(gsis_id)) |>
    # otc has some duplicates IDs. We have to remove them here
    remove_duplicated("gsis_id") |>
    remove_duplicated("pff_id")

  cleaned <- manual_ids |>
    dplyr::left_join(
      pfr,
      by = "gsis_id",
      suffix = c("", "_auto")
    ) |>
    dplyr::left_join(
      espn,
      by = "gsis_id",
      suffix = c("", "_auto")
    ) |>
    dplyr::left_join(
      otc |> dplyr::select(gsis_id, pff_id, otc_id),
      by = "gsis_id",
      suffix = c("", "_auto")
    ) |>
    dplyr::select(
      gsis_id,
      tidyselect::starts_with("pfr_id"),
      tidyselect::starts_with("pff_id"),
      tidyselect::starts_with("otc_id"),
      tidyselect::starts_with("espn_id")
    ) |>
    dplyr::mutate(
      # If the ID in the manual ID json file is the same as the ID created in
      # automated processes (suffix "_auto") then we can drop that ID from the
      # manual ID json file by setting it to NA
      pfr_id =  dplyr::na_if(pfr_id, pfr_id_auto),
      pff_id =  dplyr::na_if(pff_id, pff_id_auto),
      otc_id =  dplyr::na_if(otc_id, otc_id_auto),
      espn_id = dplyr::na_if(espn_id, espn_id_auto)
    ) |>
    dplyr::select(
      gsis_id, espn_id, pfr_id, pff_id, otc_id
    ) |>
    dplyr::filter(
      # If all external IDs are NA, there is no point in keeping the gsis ID
      # in the json file
      !dplyr::if_all(c(espn_id, pfr_id, pff_id, otc_id), is.na)
    ) |>
    dplyr::arrange(dplyr::desc(gsis_id))

  if (!identical(manual_ids, cleaned) && interactive()) {
    update <- utils::menu(
      title = "It is possible to remove some IDs from the manual ID json file.\nDo you wish to overwrite the file?",
      choices = c("Yes", "No")
    ) == 1
    if (isTRUE(update)) {
      # NOTE the pretty arg for better readability
      jsonlite::write_json(
        cleaned,
        "inst/players_manual_overwrite.json",
        pretty = TRUE
      )
    }
  } else if (!identical(manual_ids, cleaned)){
    cli::cli_alert_info("Detected entries that should be cleaned. \\
                        Please run {.fun players_manual_ids_clean} interactively.")
  }

  invisible(cleaned)
}

overwrite <- function(original_vec, replacement_vec){
  # IF THE REPLACEMENT VALUE IS
  # "" -> WE WANT TO SET THE REPLACEMENT TO NA, I.E. REMOVE THE ORIGINAL VALUE!
  # NA -> WE WANT TO KEEP THE ORIGINAL VALUE
  # OTEHRWISE WE USE THE REPLACEMENT VALUE
  replacement <- unname(replacement_vec[names(original_vec)])

  data.table::fcase(
    replacement == "", NA_character_,
    is.na(replacement), original_vec,
    default = replacement
  )
}

.players_read_json <- function(file) {
  jsonlite::read_json(file, simplifyVector = TRUE) |>
    .convert_ids()
}

overwrite_ids <- function() c("pff_id", "pfr_id", "otc_id", "espn_id")
