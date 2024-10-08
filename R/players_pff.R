#' Release Players PFF File
#'
#' This function downloads raw pff player files from the release tag `raw_pff`
#' in the nflverse-players repo, and summarizes the data (uses the latest season
#' of each player) to the players pff dataset. Raw players data are saved locally.
#' Set argument `overwrite` to `TRUE` to always download the latest data.
#' The function finishes by releasing the players pff data to the release tag
#' `players_components` of the nflverse-players repo.
#'
#' @param overwrite If `TRUE` overwrites all existing raw pff files in the
#' directory `./build/raw_pff`.
#'
#' @return Returns the players pff dataset invisibly
#'
#' @export
players_pff_release <- function(overwrite = !interactive()){
  raw_players_files <- .pff_download_raw_players(overwrite = overwrite)
  raw_players <- purrr::map(raw_players_files, readRDS) |>
    purrr::list_rbind()

  pff_players <- raw_players |>
    dplyr::rename(pff_id = id) |>
    dplyr::filter(!is.na(pff_id)) |>
    dplyr::slice_max(season, n = 1, by = pff_id) |>
    dplyr::select(
      pff_id,
      pff_name = name,
      pff_position = position,
      pff_status = status,
      pff_weight = weight,
      pff_height = height,
      pff_slug = slug,
      pff_speed = speed,
      last_season = season
    ) |>
    dplyr::arrange(dplyr::desc(last_season), pff_id)

  nflversedata::nflverse_save(
    pff_players,
    file_name = "players_pff",
    nflverse_type = "Players PFF Data",
    release_tag = "players_components",
    file_types = "rds",
    repo = "nflverse/nflverse-players"
  )

  invisible(pff_players)
}

#' Release PFF Players Files
#'
#' This function releases raw pff players files to a release in the nflverse-players
#' repo. This function is intended to update the most recent season in order
#' to get up to date pff player information.
#'
#' @param seasons The seasons for which to release pff players files
#'
#' @export
.pff_release_raw_players <- function(seasons){
  # CREATE TEMPORARY DIRECTORY FOR PFF ROSTER
  file_dir <- file.path("build", "raw_pff")
  if (!dir.exists(file_dir)) dir.create(file_dir)

  file_paths <- purrr::map_chr(
    seasons,
    .pff_save_raw_players,
    file_dir = file_dir,
    .progress = TRUE
  )

  file_paths <- stats::na.omit(file_paths)

  nflversedata::nflverse_upload(
    file_paths,
    tag = "raw_pff",
    repo = "nflverse/nflverse-players"
  )

  invisible(TRUE)
}

.pff_download_raw_players <- function(overwrite = !interactive()) {
  to_load <- file.path(
    "https://github.com/nflverse/nflverse-players/releases/download/raw_pff",
    paste0(
      "pff_players_",
      seq(2001, nflreadr::most_recent_season(roster = TRUE)),
      ".rds"
    ),
    fsep = "/"
  )

  save_dir <- file.path(getwd(), "build", "raw_pff")
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

    if (nrow(failed > 0)){
      cli::cli_alert_warning("Failed to download the following {cli::qty(nrow(failed))}file{?s}: {.url {failed$url}}")
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

.pff_save_raw_players <- function(season, file_dir){
  # CREATE LIST OF REQUESTS FOR PARALLEL EXECUTION
  reqs <- lapply(
    c("QB", "WR", "HB", "FB", "TE", "C", "G", "T", "CB", "S", "LB", "DI", "ED", "K", "P", "LS"),
    function(position, season){
      httr2::request("https://www.pff.com/api/") |>
        httr2::req_url_path_append("nfl", "grades") |>
        httr2::req_url_query(
          season = season,
          position = position
        ) |>
        httr2::req_retry()
    }, season = season)

  # EXECUTE REQUESTS
  resps <- httr2::req_perform_parallel(reqs, on_error = "continue")

  players_pff <- httr2::resps_successes(resps) |>
    lapply(function(x){
      httr2::resp_body_json(x, simplifyVector = TRUE) |>
      getElement("players") |>
      tibble::as_tibble()
    }) |>
    purrr::list_rbind()

  # API RETURNS EMPTY DATA INSTEAD OF A FAILURE. SO WE HAVE TO QUIT HERE IF THE
  # DATAFRAME IS EMPTY
  if (nrow(players_pff) == 0) {
    cli::cli_alert_warning(
      "Couldn't find {.val {season}} PFF players data. Exiting."
    )
    return(invisible(NA_character_))
  }

  players_pff <- players_pff |>
    dplyr::mutate(
      season = .env$season,
      team_name = nflreadr::clean_team_abbrs(team_name)
    ) |>
    tidyr::unpack(tidyselect::where(is.data.frame), names_sep = "_") |>
    janitor::remove_empty("cols") |>
    dplyr::mutate(dplyr::across(tidyselect::where(is.character), ~ dplyr::na_if(.x, ""))) |>
    dplyr::select(
      season, team_name, name, dplyr::everything()
    )

  # THE FILENAME SHOULD INCLUDE THE SEASON
  # WHEN SEASON == NULL, THE API WILL RETURN CURRENT SEASON
  # SO WE HAVE TO REPLACE NULL VALUES WITH THE CURRENT SEASON FOR THE FILENAME
  file_name <- paste0("pff_players_", season, ".rds")
  file_path <- file.path(file_dir, file_name)
  saveRDS(players_pff, file_path)

  # WE RETURN FILEPATH HERE BECAUSE THERE WILL BE A LOOP OVER SEASONS
  return(file_path)
}

.pff_is_valid_season <- function(season){
  season %in% seq(2001, nflreadr::most_recent_season(roster = TRUE))
}
