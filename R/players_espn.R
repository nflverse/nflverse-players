#' Release Players ESPN ID Mapping
#'
#' This function loads ESPN player IDs and the players basis dataset
#' (see [players_basis_release]) and tries to join as many ESPN IDs as possible.
#' Currently the function tries to join by
#' \itemize{
#'  \item{Full name and position}
#'  \item{Full name}
#' }
#' Joining is done in the order given and the function cleans the names prior
#' to joins with [nflreadr::clean_player_names()].
#' The function finishes by releasing a ESPN ID to GSIS ID mapping to the release
#' tag `players_components` of the nflverse-players repo.
#'
#' @details
#' The underlying join function prints messages of join status. You can suppress
#' the messages by setting `options(players_espn_join.verbose = FALSE)`.
#'
#' @param players_espn_full_rebuild If `FALSE` (the default), the function will
#' load the players dataset using `players_download("full")` and fill only missing
#' ESPN IDs. Otherwise, it will fill ESPN IDs of all players. Set the environment
#' variable `"PLAYERS_ESPN_REBUILD"` to control the behavior.
#'
#' @return Returns the players ESPN dataset invisibly
#' @export
players_espn_release <- function(players_espn_full_rebuild = Sys.getenv("PLAYERS_ESPN_REBUILD", "false")){
  # IN CASE OF A FULL REBUILD, WE TRY TO JOIN IDs TO ALL PLAYERS, ALSO THE ONES
  # WHERE WE ALREADY HAVE ESPN IDs FROM A FORMER JOIN
  espn_full_rebuild <- as.logical(players_espn_full_rebuild)

  # LOAD ESPN ID SOURCE. THE DATASOURCE LIVES IN
  # THE ENVIRONMENT VARIABLE "ESPN_PLAYERS_BASE"
  espn_basis <- .espn_basis_load() |>
    dplyr::mutate(espn_id = as.character(espn_id))

  # LOAD PLAYERS BASIS WHERE WE WANT TO JOIN ESPN IDs TO.
  if (isTRUE(espn_full_rebuild)){
    # THE PLAYERS BASIS HAS NO ESPN ID VARIABLE. WE DEFINE IT AND THEN TRY MUTIPLE
    # JOINS TO FILL AS MANY IDs AS POSSIBLE
    players_basis <- players_download("basis") |>
      dplyr::mutate(espn_id = NA_integer_)
  } else if (isFALSE(espn_full_rebuild)){
    # IF WE DON'T DO A FULL ESPN REBUILD, WE LOAD THE FULL PLAYERS DATASET
    # AND TRY TO FILL NA ESPN IDs ONLY
    players_basis <- players_download("full")
  }

  # NOW FILL IDs WITH MULTIPLE JOINS
  players_espn <- players_basis |>
    .espn_join(espn_basis, by = "full_name_position") |>
    .espn_join(espn_basis, by = "full_name") |>
    remove_duplicated("espn_id") |>
    strip_nflverse_attributes() |>
    tibble::as_tibble()

  # ONLY FOR DEV WORK
  missing <- players_basis |> dplyr::filter(!gsis_id %in% players_espn$gsis_id)

  # THE MAPPING REALLY ONLY LISTS GSIS ID AND ESPN ID
  espn_mapping <- players_espn |>
    dplyr::filter(!is.na(espn_id)) |>
    dplyr::select(gsis_id, espn_id)

  nflversedata::nflverse_save(
    espn_mapping,
    file_name = "players_espn",
    nflverse_type = "Players ESPN Mapping",
    release_tag = "players_components",
    file_types = "rds",
    repo = "nflverse/nflverse-players"
  )

  invisible(players_espn)
}

# Raw ESPN Players Data (no joins) ----------------------------------------

#' Combine Raw ESPN Player Files
#'
#' This function downloads raw ESPN player files from the release tag `raw_espn`
#' in the nflverse-players repo, and summarizes the data (uses the latest season
#' of each player) to the raw players ESPN dataset. Raw players data are saved
#' locally. Set argument `overwrite` to `TRUE` to always download the latest data.
#' The function finishes by releasing the raw players ESPN data to the release tag
#' `raw_espn` of the nflverse-players repo.
#'
#' @param overwrite If `TRUE` overwrites all existing raw ESPN files in the
#' directory `./build/raw_espn`.
#'
#' @return Returns the combined raw players ESPN dataset invisibly
#'
#' @export
.espn_combine_raw_players <- function(overwrite = !interactive()){
  raw_players_files <- .espn_download_raw_players(overwrite = overwrite)
  raw_players <- purrr::map(raw_players_files, readRDS) |>
    purrr::list_rbind()

  espn_players <- raw_players |>
    dplyr::filter(espn_id >= 0) |>
    dplyr::filter(!is.na(espn_id)) |>
    dplyr::slice_max(season, n = 1, by = espn_id) |>
    dplyr::rename(last_season = season) |>
    dplyr::arrange(dplyr::desc(last_season), espn_id)

  nflversedata::nflverse_save(
    espn_players,
    file_name = "espn_players_combined",
    nflverse_type = "Raw Players ESPN Data",
    release_tag = "raw_espn",
    file_types = "rds",
    repo = "nflverse/nflverse-players"
  )

  invisible(espn_players)
}

#' Release ESPN Players Files
#'
#' This function releases raw ESPN players files to a release in the nflverse-players
#' repo. This function is intended to update the most recent season in order
#' to get up to date ESPN player information.
#'
#' @param seasons The seasons for which to release ESPN players files
#'
#' @export
.espn_release_raw_players <- function(seasons){
  # CREATE TEMPORARY DIRECTORY FOR ESPN ROSTER
  file_dir <- file.path("build", "raw_espn")
  if (!dir.exists(file_dir)) dir.create(file_dir)

  file_paths <- purrr::map_chr(
    seasons,
    .espn_save_raw_players,
    file_dir = file_dir,
    .progress = TRUE
  )

  file_paths <- stats::na.omit(file_paths)

  nflversedata::nflverse_upload(
    file_paths,
    tag = "raw_espn",
    repo = "nflverse/nflverse-players"
  )

  invisible(TRUE)
}

.espn_download_raw_players <- function(overwrite = !interactive()) {
  # IT SEEMS LIKE ESPN CHANGED PLAYER IDs in 2007
  # THIS CAUSES DUPLICATED PLAYERS BECAUSE THEY HAVE 2 IDs
  # FILTERING TO 2007+ FINDS MORE MATCHES TOTAL
  to_load <- file.path(
    "https://github.com/nflverse/nflverse-players/releases/download/raw_espn",
    paste0(
      "espn_players_",
      seq(2007, nflreadr::most_recent_season(roster = TRUE)),
      ".rds"
    ),
    fsep = "/"
  )

  save_dir <- file.path(getwd(), "build", "raw_espn")
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

.espn_save_raw_players <- function(season, file_dir){
  resp <- tryCatch(
    httr2::request("https://lm-api-reads.fantasy.espn.com") |>
      httr2::req_url_path_append(
        "apis", "v3", "games", "ffl", "seasons", season, "players"
      ) |>
      httr2::req_url_query(view = "players_wl") |>
      httr2::req_headers("x-fantasy-filter" = '{"filterActive":{"value":true}}') |>
      httr2::req_perform() |>
      httr2::resp_body_json(simplifyVector = TRUE) |>
      janitor::clean_names(),
    httr2_http_404 = function(cnd) data.frame()
  )

  # API RETURNS EMPTY DATA INSTEAD OF A FAILURE. SO WE HAVE TO QUIT HERE IF THE
  # DATAFRAME IS EMPTY
  if (nrow(resp) == 0) {
    cli::cli_alert_warning(
      "Couldn't find {.val {season}} espn players data. Exiting."
    )
    return(invisible(NA_character_))
  }

  players_espn <- resp |>
    dplyr::mutate(
      season = .env$season,
    ) |>
    dplyr::select(
      season,
      espn_id = id,
      espn_position = default_position_id,
      first_name,
      last_name,
      full_name,
      team = pro_team_id
    ) |>
    dplyr::mutate(
      team = unname(.espn_team_ids[as.character(team)]),
      espn_position = unname(.espn_position_ids[as.character(espn_position)])
    )

  # THE FILENAME SHOULD INCLUDE THE SEASON
  # WHEN SEASON == NULL, THE API WILL RETURN CURRENT SEASON
  # SO WE HAVE TO REPLACE NULL VALUES WITH THE CURRENT SEASON FOR THE FILENAME
  file_name <- paste0("espn_players_", season, ".rds")
  file_path <- file.path(file_dir, file_name)
  saveRDS(players_espn, file_path)

  # WE RETURN FILEPATH HERE BECAUSE THERE WILL BE A LOOP OVER SEASONS
  return(file_path)
}


# Join ESPN Players Data --------------------------------------------------

.espn_basis_load <- function(){
  nflreadr::rds_from_url(
    "https://github.com/nflverse/nflverse-players/releases/download/raw_espn/espn_players_combined.rds"
  )
}

.espn_join <- function(players_basis,
                       espn_basis,
                       by = c("full_name_position", "full_name"),
                       verbose = getOption("players_espn_join.verbose", TRUE)){

  by <- rlang::arg_match(by)

  players_basis$join_name <- nflreadr::clean_player_names(
    players_basis$display_name,
    lowercase = TRUE
  )
  espn_basis$join_name <- nflreadr::clean_player_names(
    espn_basis$full_name,
    lowercase = TRUE
  )

  # WE HAVE TO AVOID MATCHING IDs THAT HAVE BEEN MATCHED IN PREVIOUS JOINS
  # THAT'S WHY WE UPDATE ESPN_BASIS HERE TO LIST ONLY UNMATCHED ESPN_IDs
  # OTHERWISE WE COULD UNINTENTIONALLY CREATE DUPLICATES THAT WILL BE REMOVED
  # LATER ON
  espn_basis <- espn_basis |>
    dplyr::filter(!espn_id %in% players_basis$espn_id)

  if (by == "full_name_position"){
    joined <- players_basis |>
      dplyr::filter(!is.na(position), !is.na(gsis_id), is.na(espn_id)) |>
      dplyr::select(join_name, position, gsis_id) |>
      dplyr::left_join(
        espn_basis |> dplyr::select(espn_id, join_name, position = espn_position),
        by = c("join_name", "position"),
      ) |>
      remove_duplicated("gsis_id") |>
      dplyr::filter(!is.na(espn_id))

    if (isTRUE(verbose)){
      cli::cli_alert_info(
        "The join by name and position resolved \\
        {cli::no(nrow(joined))}/{cli::no(nrow(players_basis))} \\
        ESPN player ID{?s}."
      )
    }
  } else if (by == "full_name"){
    joined <- players_basis |>
      dplyr::filter(!is.na(gsis_id), is.na(espn_id)) |>
      dplyr::select(join_name, gsis_id) |>
      dplyr::left_join(
        espn_basis |> dplyr::select(espn_id, join_name),
        by = c("join_name"),
      ) |>
      remove_duplicated("gsis_id") |>
      dplyr::filter(!is.na(espn_id))

    if (isTRUE(verbose)){
      cli::cli_alert_info(
        "The join by name resolved \\
        {cli::no(nrow(joined))}/{cli::no(nrow(players_basis[is.na(players_basis$espn_id),]))} \\
        ESPN player ID{?s}."
      )
    }
  }

  id_vec <- joined$espn_id |> rlang::set_names(joined$gsis_id)

  players_basis$join_name <- NULL
  .espn_fill_ids(players_basis, id_vec)
}

.espn_fill_ids <- function(players_basis, id_vec){
  players_basis |>
    dplyr::mutate(
      espn_id = dplyr::case_when(
        is.na(espn_id) ~ unname(id_vec[gsis_id]),
        TRUE ~ espn_id
      )
    )
}

# ESPN Utils --------------------------------------------------------------

.espn_is_valid_season <- function(season){
  season %in% seq(2004, nflreadr::most_recent_season(roster = TRUE))
}

.espn_team_ids <- tibble::tribble(
  ~id, ~name,
  22L, "ARI",
  1L, "ATL",
  33L, "BAL",
  2L, "BUF",
  29L, "CAR",
  3L, "CHI",
  4L, "CIN",
  5L, "CLE",
  6L, "DAL",
  7L, "DEN",
  8L, "DET",
  9L, "GB",
  34L, "HOU",
  11L, "IND",
  30L, "JAX",
  12L, "KC",
  24L, "LAC",
  14L, "LA",
  13L, "LV",
  15L, "MIA",
  16L, "MIN",
  17L, "NE",
  18L, "NO",
  19L, "NYG",
  20L, "NYJ",
  21L, "PHI",
  23L, "PIT",
  26L, "SEA",
  25L, "SF",
  27L, "TB",
  10L, "TEN",
  28L, "WAS"
) |>
  tibble::deframe()

.espn_position_ids <- tibble::tribble(
  ~id, ~name,
  1,  "QB",
  2,  "RB",
  3,  "WR",
  4,  "TE",
  5,  "K",
  7,  "P",
  9,  "DT",
  10,  "DE",
  11,  "LB",
  12,  "CB",
  13,  "S",
  14,  "HC",
  16,  "DST"
) |>
  tibble::deframe()
