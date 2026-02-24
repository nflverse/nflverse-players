#' Release Full Players Dataset
#'
#' Download all components of the players dataset and combine them to the full
#' dataset. The function calls [players_validate()] internally to make sure, clean
#' data will be released.
#' Currently, the following components will be joined:
#' \itemize{
#'  \item{Basis data, containing basic player info and `gsis_id`}
#'  \item{PFR data, adding `pfr_id`}
#'  \item{OTC data, adding overthecap player IDs (`otc_id`) and `pff_id`}
#'  \item{Draft data, scraped from PFR and joined by `pfr_id`}
#' }
#'
#' @param release If `TRUE`, the function will upload the full dataset to the
#' release tag `players_components` of the nflverse-players and nflverse-data
#' repos.
#'
#' @return The full players dataset invisibly
#' @export
players_build_dataset <- function(release = FALSE){
  basis <- players_download("basis")

  pfr <- players_download("pfr") |>
    remove_duplicated("pfr_id")

  pff <- players_download("pff") |>
    remove_duplicated("pff_id")

  espn <- players_download("espn") |>
    remove_duplicated("espn_id")

  otc <- players_download("otc") |>
    dplyr::filter(!is.na(gsis_id)) |>
    # otc has some duplicates IDs. We have to remove them here
    remove_duplicated("gsis_id") |>
    remove_duplicated("pff_id")

  draft <- players_download("draft") |>
    dplyr::filter(!is.na(pfr_id)) |>
    # Bo Jackson and Craig Erickson got drafted twice and we need to avoid
    # duplicates. So we consider the later draft as actual draft
    dplyr::slice_max(draft_year, by = pfr_id) |>
    dplyr::mutate(
      draft_team = nflreadr::clean_team_abbrs(draft_team)
    )

  ngs <- players_download("ngs")

  players_full <- basis |>
    dplyr::left_join(
      pfr,
      by = "gsis_id"
    ) |>
    dplyr::left_join(
      espn,
      by = "gsis_id"
    ) |>
    dplyr::left_join(
      otc |> dplyr::select(gsis_id, pff_id, otc_id),
      by = "gsis_id"
    ) |>
    dplyr::left_join(
      pff |> dplyr::select(pff_id, pff_position, pff_status),
      by = "pff_id"
    ) |>
    dplyr::left_join(
      draft, by = "pfr_id"
    ) |>
    dplyr::left_join(
      ngs, by = "gsis_id"
    ) |>
    dplyr::relocate(nfl_id, pfr_id, pff_id, otc_id, espn_id, .after = esb_id) |>
    dplyr::relocate(short_name, football_name, suffix, .after = last_name) |>
    dplyr::relocate(college_conference, .after = college_name) |>
    dplyr::relocate(ngs_status, ngs_status_short_description, .after = status) |>
    dplyr::relocate(ngs_position_group, ngs_position, .after = position) |>
    upload_no_overwrites(release = release) |>
    players_manual_overwrite() |>
    fix_headshot_url() |>
    # need to update draft data for players where pfr IDs are fixed
    # through players_manual_overwrite
    dplyr::rows_update(draft, by = "pfr_id", unmatched = "ignore") |>
    dplyr::arrange(last_name, first_name, gsis_id) |>
    .convert_ids()

  check <- players_validate(players_full)

  if (isTRUE(release) && !is_duplicated(check)){
    cli::cli_alert_info(
      "Release full dataset to the {.pkg players_components} \\
      tag in the {.pkg nflverse/nflverse-players} repo"
    )
    # Release to nflverse-players repo
    nflversedata::nflverse_save(
      players_full,
      file_name = "players_full",
      nflverse_type = "nflverse Players Data",
      release_tag = "players_components",
      file_types = "rds",
      repo = "nflverse/nflverse-players"
    )
    # Release to nflverse-data repo
    nflversedata::nflverse_save(
      players_full,
      file_name = "players",
      nflverse_type = "nflverse Players Data",
      release_tag = "players",
      file_types = c("rds", "csv", "parquet", "qs", "csv.gz"),
      repo = "nflverse/nflverse-data"
    )
  } else if (isTRUE(release) && is_duplicated(check)) {
    cli::cli_alert_warning(
      "Cannot release dataset because it contains duplicated rows. \\
      Try {.fun players_validate} to identify the duplicated rows and \\
      variables."
    )
  } else if (is_duplicated(check)) {
    cli::cli_alert_warning(
      "Dataset contains duplicated rows. Try {.fun players_validate} \\
      to identify the duplicated rows and variables."
    )
  }

  invisible(players_full)
}
