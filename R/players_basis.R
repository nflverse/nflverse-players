#' Release Players Basis File
#'
#' This function downloads raw roster files from the release tag `raw_roster`
#' in the nflverse-players repo, and summarizes the data (uses the latest season
#' of each player) to the players basis dataset. Raw rosters are saved locally.
#' Set argument `overwrite` to `TRUE` to always download the latest data.
#' The function finishes by releasing the players basis data to the release tag
#' `players_components` of the nflverse-players repo.
#'
#' @param overwrite If `TRUE` overwrites all existing raw roster files in the
#' directory `./build/raw_roster`.
#'
#' @return Returns the players basis dataset invisibly
#'
#' @export
players_basis_release <- function(overwrite = !interactive()){
  raw_roster_files <- .basis_download_raw_roster(overwrite = overwrite)
  roster <- purrr::map(raw_roster_files, readRDS) |>
    purrr::list_rbind()

  basis <- roster |>
    dplyr::mutate(
      # many rookies are missing gsis_ids during the offseason but most of them
      # already got assigned esb_ids. We overwrite missing gsis_ids here to avoid
      # dropping rookies. As soon as they are assigned gsis_ids they will be used.
      # This isn't a perfect solution but the complete process is built on top of
      # gsis IDs, so it's the easiest way to handle missing gsis_ids esp. during offseason
      player_gsis_id = dplyr::if_else(is.na(player_gsis_id), player_esb_id, player_gsis_id)
    ) |>
    dplyr::filter(!is.na(player_gsis_id)) |>
    dplyr::mutate(rookie_season = dplyr::first(season), .by = player_gsis_id) |>
    dplyr::slice_max(tibble::tibble(season, dplyr::desc(player_status)), n = 1, by = player_gsis_id) |>
    dplyr::mutate_if(is.list, ~ purrr::map_chr(.x, ~ unlist(.x) |> paste(collapse = "; "))) |>
    dplyr::rename_with(~ gsub("player_", "", .x)) |>
    dplyr::select(
      gsis_id,
      display_name,
      common_first_name,
      first_name,
      last_name,
      esb_id,
      smart_id = id,
      birth_date,
      position_group,
      position,
      height,
      weight,
      headshot,
      college_name = college_names,
      jersey_number,
      rookie_season,
      last_season = season,
      latest_team = team_abbreviation,
      status,
      years_of_experience = nfl_experience
    ) |>
    dplyr::mutate(
      latest_team = nflreadr::clean_team_abbrs(latest_team)
    ) |>
    dplyr::arrange(dplyr::desc(last_season), gsis_id)

  nflversedata::nflverse_save(
    basis,
    file_name = "players_basis",
    nflverse_type = "Players Basis",
    release_tag = "players_components",
    file_types = "rds",
    repo = "nflverse/nflverse-players"
  )

  invisible(basis)
}


#' Release Roster Files
#'
#' This function releases raw roster files to a release in the nflverse-players
#' repo. These files serve as base for players data. This function is intended to
#' update the most recent season in order to get up to date teams and status data.
#'
#' @param seasons The seasons for which to release roster files
#'
#' @export
.basis_release_raw_roster <- function(seasons){
  roster_dir <- file.path(getwd(), "build", "raw_roster")
  if (!dir.exists(roster_dir)) dir.create(roster_dir)

  file_paths <- purrr::map_chr(seasons, function(s, roster_dir){
    save_to <- file.path(roster_dir, paste0("raw_roster_", s, ".rds"))
    r <- nflapi::nflapi_roster(s) |> nflapi::nflapi_roster_parse()
    saveRDS(r, save_to)
    save_to
  }, roster_dir = roster_dir, .progress = TRUE)

  nflversedata::nflverse_upload(
    file_paths,
    tag = "raw_roster",
    repo = "nflverse/nflverse-players"
  )

  invisible(TRUE)
}

.basis_download_raw_roster <- function(overwrite = !interactive()) {
  to_load <- file.path(
    "https://github.com/nflverse/nflverse-players/releases/download/raw_roster",
    paste0(
      "raw_roster_",
      seq(1974, nflreadr::most_recent_season(roster = TRUE)),
      ".rds"
    ),
    fsep = "/"
  )

  save_dir <- file.path(getwd(), "build", "raw_roster")
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
