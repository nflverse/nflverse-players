#' Release Players NGS File
#'
#' This function downloads raw ngs player files from the release tag `raw_ngs`
#' in the nflverse-players repo, and summarizes the data (uses the latest season
#' of each player) to the players ngs dataset. Raw players data are saved locally.
#' Set argument `overwrite` to `TRUE` to always download the latest data.
#' The function finishes by releasing the players ngs data to the release tag
#' `players_components` of the nflverse-players repo.
#'
#' @param overwrite If `TRUE` overwrites all existing raw ngs files in the
#' directory `./build/raw_ngs`.
#'
#' @return Returns the players ngs dataset invisibly
#'
#' @export
players_ngs_release <- function(overwrite = !interactive()){
  raw_players_files <- .ngs_download_raw_players(overwrite = overwrite)
  raw_players <- purrr::map(raw_players_files, readRDS) |>
    data.table::rbindlist(fill = TRUE) |>
    janitor::clean_names()

  ngs_players <- raw_players |>
    dplyr::filter(!is.na(gsis_id)) |>
    dplyr::slice_max(season, n = 1, by = gsis_id, with_ties = FALSE) |>
    dplyr::select(
      gsis_id,
      nfl_id = gsis_it_id,
      short_name,
      football_name,
      suffix,
      ngs_position,
      ngs_position_group,
      ngs_status = status,
      ngs_status_short_description = status_short_description,
      college_conference
    ) |>
    dplyr::arrange(gsis_id)

  data.table::setDF(ngs_players)

  nflversedata::nflverse_save(
    ngs_players,
    file_name = "players_ngs",
    nflverse_type = "Players NGS Data",
    release_tag = "players_components",
    file_types = "rds",
    repo = "nflverse/nflverse-players"
  )

  invisible(ngs_players)
}

#' Release NGS Players Files
#'
#' This function releases raw ngs players files to a release in the nflverse-players
#' repo. This function is intended to update the most recent season in order
#' to get up to date ngs player information.
#'
#' @param seasons The seasons for which to release ngs players files
#'
#' @export
.ngs_release_raw_players <- function(seasons){
  # CREATE TEMPORARY DIRECTORY FOR NGS PLAYERS
  file_dir <- file.path("build", "raw_ngs")
  if (!dir.exists(file_dir)) dir.create(file_dir)

  file_paths <- purrr::map_chr(
    seasons,
    .ngs_save_raw_players,
    file_dir = file_dir,
    .progress = TRUE
  )

  file_paths <- stats::na.omit(file_paths)

  nflversedata::nflverse_upload(
    file_paths,
    tag = "raw_ngs",
    repo = "nflverse/nflverse-players"
  )

  invisible(TRUE)
}

.ngs_download_raw_players <- function(overwrite = !interactive()) {
  to_load <- file.path(
    "https://github.com/nflverse/nflverse-players/releases/download/raw_ngs",
    paste0(
      "ngs_players_",
      seq(2016, nflreadr::most_recent_season(roster = TRUE)),
      ".rds"
    ),
    fsep = "/"
  )

  save_dir <- file.path(getwd(), "build", "raw_ngs")
  if (!dir.exists(save_dir)) dir.create(save_dir)
  save_to <- file.path(save_dir, basename(to_load))

  succeeded <- character()
  exists_locally <- character()

  if (isFALSE(overwrite)){
    exists <- file.exists(save_to)
    initial_to_load <- to_load
    initial_save_to <- save_to
    to_load <- to_load[!exists]
    save_to <- save_to[!exists]
    cli::cli_alert_info("Going to skip {.url {basename(initial_to_load[exists])}} because the \\
                        files exist locally and {.arg overwrite} is set to {.val FALSE}")
    exists_locally <- initial_save_to[exists]
  }

  if (length(to_load)){
    status <- curl::multi_download(to_load, save_to)

    failed <- status[status$status_code != 200,]

    if (nrow(failed) > 0){
      cli::cli_alert_warning("Failed to download the following {cli::qty(nrow(failed))}file{?s}: {.url {failed$url}}")
      deleted_failed <- file.remove(failed$destfile)
    }

    succeeded <- status$destfile[status$status_code == 200]

  }
  raw_files <- c(exists_locally, succeeded)

  if (length(raw_files) == 0){
    cli::cli_abort("No successful downloads and no local copies available. \\
                   It doesn't make sense to continue at this point.")
  }

  raw_files
}

.ngs_save_raw_players <- function(season, file_dir){
  players_ngs <- nflapi::init_ngs_request() |>
    httr2::req_url_path_append("roster", "current") |>
    httr2::req_url_query(
      teamId = "ALL",
      season = season,
      status = "ALL"
    ) |>
    httr2::req_retry() |>
    httr2::req_perform() |>
    httr2::resp_body_json(simplifyVector = TRUE) |>
    getElement("teamPlayers")

  # API RETURNS EMPTY DATA INSTEAD OF A FAILURE. SO WE HAVE TO QUIT HERE IF THE
  # DATAFRAME IS EMPTY
  if (nrow(players_ngs) == 0) {
    cli::cli_alert_warning(
      "Couldn't find {.val {season}} NGS roster data. Exiting."
    )
    return(invisible(NA_character_))
  }

  # THE FILENAME SHOULD INCLUDE THE SEASON
  # WHEN SEASON == NULL, THE API WILL RETURN CURRENT SEASON
  # SO WE HAVE TO REPLACE NULL VALUES WITH THE CURRENT SEASON FOR THE FILENAME
  file_name <- paste0("ngs_players_", season, ".rds")
  file_path <- file.path(file_dir, file_name)
  saveRDS(players_ngs, file_path)

  # WE RETURN FILEPATH HERE BECAUSE THERE WILL BE A LOOP OVER SEASONS
  return(file_path)
}

.ngs_is_valid_season <- function(season){
  season %in% seq(2016, nflreadr::most_recent_season(roster = TRUE))
}
