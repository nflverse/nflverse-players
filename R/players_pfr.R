#' Release Players PFR ID Mapping
#'
#' This function loads PFR player IDs and the players basis dataset
#' (see [players_basis_release]) and tries to join as many PFR IDs as possible.
#' Currently the function tries to join by
#' \itemize{
#'  \item{Name and Rookie Season}
#'  \item{Name}
#'  \item{First, Last}
#' }
#' Joining is done in the order given and the function cleans the names prior
#' to joins with [nflreadr::clean_player_names()].
#' The function finishes by releasing a PFR ID to GSIS ID mapping to the release
#' tag `players_components` of the nflverse-players repo.
#'
#' @details
#' Please note that you have to set the environment variable `"PLAYERS_PFR_BASE"`
#' to the nflverse PFR ID source url. If it is unset, the underlying function
#' will error.
#' The underlying join function prints messages of join status. You can suppress
#' the messages by setting `options(players_pfr_join.verbose = FALSE)`.
#'
#' @param players_pfr_full_rebuild If `FALSE` (the default), the function will
#' load the players dataset using `players_download("full")` and fill only missing
#' PFR IDs. Otherwise, it will fill PFR IDs of all players. Set the environment
#' variable `"PLAYERS_PFR_REBUILD"` to control the behavior.
#'
#' @param players_pfr_source A source URL where we load the PFR players base from.
#' Set the environment variable `"PLAYERS_PFR_BASE"` to control the behavior.
#'
#' @return Returns the players PFR dataset invisibly
#' @export
players_pfr_release <- function(players_pfr_full_rebuild = Sys.getenv("PLAYERS_PFR_REBUILD", "false"),
                                players_pfr_source = Sys.getenv("PLAYERS_PFR_BASE")){
  # IN CASE OF A FULL REBUILD, WE TRY TO JOIN IDs TO ALL PLAYERS, ALSO THE ONES
  # WHERE WE ALREADY HAVE PFR IDs FROM A FORMER JOIN
  pfr_full_rebuild <- as.logical(players_pfr_full_rebuild)

  # LOAD PFR ID SOURCE. THE DATASOURCE LIVES IN
  # THE ENVIRONMENT VARIABLE "PFR_PLAYERS_BASE"
  pfr_basis <- .pfr_basis_load(load_from = players_pfr_source)

  # LOAD PLAYERS BASIS WHERE WE WANT TO JOIN PFR IDs TO.
  if (isTRUE(pfr_full_rebuild)){
    # THE PLAYERS BASIS HAS NO PFR ID VARIABLE. WE DEFINE IT AND THEN TRY MUTIPLE
    # JOINS TO FILL AS MANY IDs AS POSSIBLE
    players_basis <- players_download("basis") |>
      dplyr::mutate(pfr_id = NA_character_)
  } else if (isFALSE(pfr_full_rebuild)){
    # IF WE DON'T DO A FULL PFR REBUILD, WE LOAD THE FULL PLAYERS DATASET
    # AND TRY TO FILL NA PFR IDs ONLY
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
  players_pfr <- players_basis |>
    .pfr_join(pfr_basis, by = "name_rookie_season") |>
    .pfr_join(pfr_basis, by = "name") |>
    .pfr_join(pfr_basis, by = "first_last") |>
    remove_duplicated("pfr_id") |>
    strip_nflverse_attributes() |>
    tibble::as_tibble()

  # ONLY FOR DEV WORK
  missing <- players_basis |> dplyr::filter(!gsis_id %in% players_pfr$gsis_id)

  # THE MAPPING REALLY ONLY LISTS GSIS ID AND PFR ID
  pfr_mapping <- players_pfr |>
    dplyr::filter(!is.na(pfr_id)) |>
    dplyr::select(gsis_id, pfr_id)

  nflversedata::nflverse_save(
    pfr_mapping,
    file_name = "players_pfr",
    nflverse_type = "Players PFR Mapping",
    release_tag = "players_components",
    file_types = "rds",
    repo = "nflverse/nflverse-players"
  )

  invisible(players_pfr)
}

.pfr_basis_load <- function(load_from = Sys.getenv("PLAYERS_PFR_BASE")){
  if (load_from == "") {
    cli::cli_abort("No valid url provided in arg {.arg load_from}. \\
                   Do you need to run {.run Sys.setenv(\"PLAYERS_PFR_BASE\")}?")
  }
  pfr_players <- data.table::fread(load_from, showProgress = FALSE) |>
    dplyr::select(
      pfr_id = V1, full_name = V2, years = V3, is_active = V4
    ) |>
    dplyr::mutate_if(is.character, ~ dplyr::na_if(.x, "")) |>
    tidyr::separate_wider_delim(
      years,
      "-",
      names = c("rookie_season", "latest_season"),
      too_few = "align_start"
    ) |>
    dplyr::mutate(
      full_name = nflreadr::clean_player_names(full_name),
      rookie_season = as.integer(rookie_season)
    )
  pfr_players
}

.pfr_join <- function(players_basis,
                      pfr_basis,
                      by = c("name_rookie_season", "name", "first_last"),
                      verbose = getOption("players_pfr_join.verbose", TRUE)){

  by <- rlang::arg_match(by)

  players_basis$join_name <- nflreadr::clean_player_names(
    players_basis$display_name,
    lowercase = TRUE
  )
  pfr_basis$join_name <- nflreadr::clean_player_names(
    pfr_basis$full_name,
    lowercase = TRUE
  )

  # WE HAVE TO AVOID MATCHING IDs THAT HAVE BEEN MATCHED IN PREVIOUS JOINS
  # THAT'S WHY WE UPDATE PFR_BASIS HERE TO LIST ONLY UNMATCHED PFR_IDs
  # OTHERWISE WE COULD UNINTENTIONALLY CREATE DUPLICATES THAT WILL BE REMOVED
  # LATER ON
  pfr_basis <- pfr_basis |>
    dplyr::filter(!pfr_id %in% players_basis$pfr_id)

  if (by == "name_rookie_season"){
    joined <- players_basis |>
      dplyr::filter(!is.na(rookie_season), !is.na(gsis_id), is.na(pfr_id)) |>
      dplyr::select(join_name, rookie_season, gsis_id) |>
      dplyr::left_join(
        pfr_basis |> dplyr::select(pfr_id, join_name, rookie_season),
        by = c("join_name", "rookie_season"),
      ) |>
      remove_duplicated("gsis_id") |>
      dplyr::filter(!is.na(pfr_id))

    if (isTRUE(verbose)){
      cli::cli_alert_info(
        "The join by name and rookie season resolved \\
        {cli::no(nrow(joined))}/{cli::no(nrow(players_basis))} \\
        PFR player ID{?s}."
      )
    }
  } else if (by == "name"){
    joined <- players_basis |>
      dplyr::filter(!is.na(gsis_id), is.na(pfr_id)) |>
      dplyr::select(join_name, gsis_id) |>
      dplyr::left_join(
        pfr_basis |> dplyr::select(pfr_id, join_name),
        by = c("join_name"),
      ) |>
      remove_duplicated("gsis_id") |>
      dplyr::filter(!is.na(pfr_id))

    if (isTRUE(verbose)){
      cli::cli_alert_info(
        "The join by name resolved \\
        {cli::no(nrow(joined))}/{cli::no(nrow(players_basis[is.na(players_basis$pfr_id),]))} \\
        PFR player ID{?s}."
      )
    }
  } else if (by == "first_last"){
    players_basis$join_name <- nflreadr::clean_player_names(
      paste(players_basis$first_name, players_basis$last_name),
      lowercase = TRUE
    )
    joined <- players_basis |>
      dplyr::filter(!is.na(gsis_id), is.na(pfr_id)) |>
      dplyr::select(join_name, gsis_id) |>
      dplyr::left_join(
        pfr_basis |> dplyr::select(pfr_id, join_name),
        by = c("join_name"),
      ) |>
      remove_duplicated("gsis_id") |>
      dplyr::filter(!is.na(pfr_id))

    if (isTRUE(verbose)){
      cli::cli_alert_info(
        "The join by (first last) resolved \\
        {cli::no(nrow(joined))}/{cli::no(nrow(players_basis[is.na(players_basis$pfr_id),]))} \\
        PFR player ID{?s}."
      )
    }
  }

  id_vec <- joined$pfr_id |> rlang::set_names(joined$gsis_id)

  players_basis$join_name <- NULL
  .pfr_fill_ids(players_basis, id_vec)
}

.pfr_fill_ids <- function(players_basis, id_vec){
  players_basis |>
    dplyr::mutate(
      pfr_id = dplyr::case_when(
        is.na(pfr_id) ~ unname(id_vec[gsis_id]),
        TRUE ~ pfr_id
      )
    )
}
