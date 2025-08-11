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

  # LOAD ESPN ID SOURCE. WE CLEAN IDS AS THE ID SYSTEM AT ESPN CHANGED AROUND 2007
  espn_basis <- .espn_basis_load() |>
    .espn_clean_basis() |>
    dplyr::mutate(espn_id = as.character(espn_id))

  # LOAD PLAYERS BASIS WHERE WE WANT TO JOIN ESPN IDs TO.
  if (isTRUE(espn_full_rebuild)){
    # THE PLAYERS BASIS HAS NO ESPN ID VARIABLE. WE DEFINE IT AND THEN TRY MUTIPLE
    # JOINS TO FILL AS MANY IDs AS POSSIBLE
    players_basis <- players_download("basis") |>
      dplyr::mutate(espn_id = NA_character_)
  } else if (isFALSE(espn_full_rebuild)){
    # IF WE DON'T DO A FULL ESPN REBUILD, WE LOAD THE FULL PLAYERS DATASET
    # AND TRY TO FILL NA ESPN IDs ONLY
    # WE HAVE TO USE THE FULL DATASET WHERE NO OVERWITRES HAVE BEEN PERFORMED
    # OTHERWISE `players_manual_ids_clean()` WILL MARK OVERWRITES AS OBSOLETE!
    players_basis <- players_download("no_overwrites")
  }

  # IF BASIS DATA CONTAINS MANUAL OVERWITRES, players_manual_ids_clean()`
  # WILL MARK OVERWRITES AS OBSOLETE. THIS CAN'T HAPPEN AS WE WOULD LOSE USEFUL
  # MANUAL OVERWRITE DATA. THE ABOVE BLOCK SHOULD CATCH THIS BUT WE DOULBE CHECK
  # HERE TO AVOID THIS PROBLEM THROUGH POTENTIAL FUTURE CODE CHANGES.
  if (!is.null(attr(players_basis, "manual_overwrite"))) {
    cli::cli_abort("Your basis data contains manual overwrites. \\
                   This messes up the complete logic. Please fix.")
  }

  # NOW FILL IDs WITH MULTIPLE JOINS
  players_espn <- players_basis |>
    .espn_join(espn_basis, by = "full_name_dob") |>
    .espn_join(espn_basis, by = "last_name_dob") |>
    .espn_join(espn_basis, by = "full_name_jersey") |>
    .espn_join(espn_basis, by = "full_name_weight") |>
    .espn_join(espn_basis, by = "first_name_dob") |>
    .espn_join(espn_basis, by = "full_name") |>
    remove_duplicated("espn_id") |>
    strip_nflverse_attributes() |>
    tibble::as_tibble()

  # ONLY FOR DEV WORK
  # THESE ARE THE ROWS IN espn_basis WHERE NO MATCH WITH players_basis WAS POSSIBLE
  # AT THE TIME OF DEVELOPMENT 3085 espn_ids WERE UNRESOLVED, 26 OF THEM LISTED
  # AS "ACTIVE", ROUGHLY 0.8%
  unresolved <- espn_basis |> dplyr::filter(!espn_id %in% players_espn$espn_id)

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

#' Release ESPN Players File
#'
#' This function releases raw ESPN players data to a release in the nflverse-players
#' repo. It fetches one table with all available athletes from the ESPN API,
#' compares the returned data with the currently saved data, updates exosting
#' rows and inserts new rows as needed.
#'
#' @export
.espn_release_raw_players <- function(){
  cli::cli_progress_step("Query ESPN players data")
  resp <- tryCatch(
    nflverse.espn::espn_athletes(),
    httr2_http_404 = function(cnd) data.frame()
  )

  # API RETURNS EMPTY DATA INSTEAD OF A FAILURE. SO WE HAVE TO QUIT HERE IF THE
  # DATAFRAME IS EMPTY
  if (nrow(resp) == 0) {
    cli::cli_alert_warning("Couldn't find espn players data. Exiting.")
    return(invisible(FALSE))
  }

  # THIS IS ONE BIG TABLE LISTING ABOUT 20K PLAYERS AT THE TIME OF WRITING THE
  # CODE (AUGUST 2025).
  new_players_espn <- resp |>
    # WE REALLY DON'T NEED THOSE IDS
    dplyr::mutate(uid = NULL, guid = NULL) |>
    # THE RESPONSE INCLUDES SOME NON PLAYER ROWS WE DON'T NEED
    dplyr::filter(!grepl("\\[|\\]|Team", display_name, perl = TRUE)) |>
    # WE WANT TO JOIN BY DATE OF BIRTH AND MAKE SURE WE HAVE IT AS A DATE OBJECT
    dplyr::mutate(
      dob = as.Date(date_of_birth)
    ) |>
    as.data.frame()

  cli::cli_progress_step("Download latest data and compare with new data")

  # WE DO NOT WANT TO LOSE OLDER DATA IF ESPN AT SOME POINT DECIDES TO
  # RETURN LESS DATA OR MESS WITH US. THAT'S WHY WE DOWNLOAD THE CURRENT RELEASE
  # AND UPDATE EXISTING ROWS, OR INSERT NEW ROWS. THIS MAKES SURE WE DON'T LOSE
  # OLDER DATA THAT IS NOT RETURNED BY THE API ANYMORE
  current_players_espn <- .espn_basis_load() |>
    strip_nflverse_attributes() |>
    data.table::setDF()

  if (nrow(current_players_espn) == 0) {
    cli::cli_progress_done()
    cli::cli_alert_warning("Couldn't download current espn players data. Exiting.")
    return(invisible(FALSE))
  }

  if (identical(current_players_espn, new_players_espn)){
    cli::cli_progress_done()
    cli::cli_alert_info("No new data. Exit without upload.")
    return(invisible(FALSE))
  }

  # UPSERT
  # UPDATES EXISTING ROWS IN `current_players_espn` AND
  # INSERTS NEW ROWS IN `new_players_espn` THAT DON'T EXIST IN `current_players_espn`
  to_release <- dplyr::rows_upsert(
    current_players_espn, new_players_espn, by = "espn_id"
  )

  # NOTE:
  # THIS IS RAW DATA. ESPN CHANGED THEIR ID SYSTEM AROUND 2007 WHICH MEANS THERE
  # ARE PLAYERS LISTED WITH TWO DIFFERENT IDS. WE TAKE CARE ABOUT THESE CASES IN
  # `.espn_clean_basis` TO BE ABLE TO LEAVE RAW DATA AS IS.
  nflversedata::nflverse_save(
    to_release,
    file_name = "espn_players_basis",
    nflverse_type = "Raw Players ESPN Data",
    release_tag = "raw_espn",
    file_types = "rds",
    repo = "nflverse/nflverse-players"
  )

  invisible(TRUE)
}


# Join ESPN Players Data --------------------------------------------------

.espn_basis_load <- function(){
  nflreadr::rds_from_url(
    "https://github.com/nflverse/nflverse-players/releases/download/raw_espn/espn_players_basis.rds"
  )
}

.espn_join <- function(players_basis,
                       espn_basis,
                       by = c("full_name_dob", "last_name_dob", "full_name_jersey","first_name_dob", "full_name_weight", "full_name"),
                       verbose = getOption("players_espn_join.verbose", TRUE)){

  by <- rlang::arg_match(by)

  players_basis$join_name <- nflreadr::clean_player_names(
    if (by %in% c("last_name_dob")) {
      players_basis$last_name
    } else if (by %in% c("first_name_dob")) {
      players_basis$first_name
    } else {
      players_basis$display_name
    },
    lowercase = TRUE
  )
  espn_basis$join_name <- nflreadr::clean_player_names(
    if (by %in% c("last_name_dob")) {
      espn_basis$last_name
    } else if (by %in% c("first_name_dob")) {
      espn_basis$first_name
    } else {
      espn_basis$full_name
    },
    lowercase = TRUE
  )

  # WE HAVE TO AVOID MATCHING IDs THAT HAVE BEEN MATCHED IN PREVIOUS JOINS
  # THAT'S WHY WE UPDATE ESPN_BASIS HERE TO LIST ONLY UNMATCHED ESPN_IDs
  # OTHERWISE WE COULD UNINTENTIONALLY CREATE DUPLICATES THAT WILL BE REMOVED
  # LATER ON
  espn_basis <- espn_basis |>
    dplyr::filter(!espn_id %in% players_basis$espn_id)

  if (by %in% c("full_name_dob", "last_name_dob", "first_name_dob")){
    joined <- players_basis |>
      dplyr::filter(!is.na(birth_date), !is.na(gsis_id), is.na(espn_id)) |>
      dplyr::select(join_name, birth_date, gsis_id) |>
      dplyr::mutate(birth_date = as.Date(birth_date)) |>
      dplyr::left_join(
        espn_basis |> dplyr::select(espn_id, join_name, birth_date = dob),
        by = c("join_name", "birth_date"),
      ) |>
      remove_duplicated("gsis_id") |>
      dplyr::filter(!is.na(espn_id))

    if (isTRUE(verbose)){
      by_name <- if (by %in% c("last_name_dob", "last_name_jersey")) {
        "last name"
      } else if (by == "first_name_dob") {
        "first name"
      } else {
        "full name"
      }
      cli::cli_alert_info(
        "The join by {by_name} and date of birth resolved \\
        {cli::no(nrow(joined))}/{cli::no(nrow(espn_basis))} \\
        ESPN player ID{?s}."
      )
    }
  } else if (by %in% c("full_name_weight")){
    joined <- players_basis |>
      dplyr::filter(!is.na(weight), !is.na(gsis_id), is.na(espn_id)) |>
      dplyr::select(join_name, weight, gsis_id) |>
      # dplyr::mutate(weight = as.character(weight)) |>
      dplyr::left_join(
        espn_basis |> dplyr::select(espn_id, join_name, weight),
        by = c("join_name", "weight"),
      ) |>
      remove_duplicated("gsis_id") |>
      dplyr::filter(!is.na(espn_id))

    if (isTRUE(verbose)){
      cli::cli_alert_info(
        "The join by full name and weight resolved \\
        {cli::no(nrow(joined))}/{cli::no(nrow(espn_basis))} \\
        ESPN player ID{?s}."
      )
    }
  } else if (by %in% c("full_name_jersey")){
    joined <- players_basis |>
      dplyr::filter(!is.na(jersey_number), !is.na(gsis_id), is.na(espn_id)) |>
      dplyr::select(join_name, jersey_number, gsis_id) |>
      # dplyr::mutate(weight = as.character(weight)) |>
      dplyr::left_join(
        espn_basis |> dplyr::select(espn_id, join_name, jersey_number = jersey),
        by = c("join_name", "jersey_number"),
      ) |>
      remove_duplicated("gsis_id") |>
      dplyr::filter(!is.na(espn_id))

    if (isTRUE(verbose)){
      cli::cli_alert_info(
        "The join by full name and jersey number resolved \\
        {cli::no(nrow(joined))}/{cli::no(nrow(espn_basis))} \\
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
        "The join by full name resolved \\
        {cli::no(nrow(joined))}/{cli::no(nrow(espn_basis))} \\
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

# ESPN CHANGED THEIR ID SYSTEM AROUND 2007 WHICH MEANS THERE
# ARE PLAYERS LISTED WITH TWO DIFFERENT IDS.
# WE ASSUME THAT THE HIGHER ID IS THE CORRECT ID AS IT SEEMS LIKE
# THEY SWITCHED FROM AROUND 4 DIGITS TO 7
# THE ONLY WAY TO FIND THE DUPLICATED PLAYERS IS GROUPING BY FULL NAME AND
# DATE OF BIRTH
.espn_clean_basis <- function(espn_basis){
  espn_basis |>
    dplyr::mutate(
      clean_name = tolower(full_name)
    ) |>
    dplyr::slice_max(
      order_by = as.integer(espn_id),
      by = c("clean_name", "dob")
    ) |>
    dplyr::mutate(clean_name = NULL)
}
