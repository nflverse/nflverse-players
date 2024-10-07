players_pff_save_raw <- function(season = NULL){

  # CREATE LIST OF REQUESTS FOR PARALLEL EXECUTION
  reqs <- lapply(
    # 1:32 are pff team ids. See data-raw/pff_teams.R
    seq(1, 32),
    function(team_id, season){
      httr2::request("https://www.pff.com/api/teams") |>
        httr2::req_url_path_append(team_id, "roster") |>
        httr2::req_url_query(
          season = season
        ) |>
        httr2::req_retry()
    }, season = season)

  # EXECUTE REQUESTS
  resps <- httr2::req_perform_parallel(reqs, on_error = "continue")

  # CAPTURE FAILED REQUESTS. WE COULD MOVE ON AFTER THIS STEP BUT I PREFER
  # AN ERROR TO SIGNAL FAILURE BECAUSE IT IS RUNNING AUTOMATICALLY
  failed <- httr2::resps_failures(resps)
  if (length(failed)){
    cli::cli_abort("Some requests failed so we error here to signal failure. \\
                   Here are the failed requests: {failed}")
  }

  # WITHOUT FAILURES, WE PARSE THE RESPONSES
  roster_pff <- httr2::resps_successes(resps) |>
    lapply(function(x){
      httr2::resp_body_json(x, simplifyVector = TRUE) |>
      getElement("team_players")
    }) |>
    purrr::list_rbind() |>
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

  # CREATE TEMPORARY DIRECTORY FOR PFF ROSTER
  file_dir <- file.path("build", "raw_pff")
  if (!dir.exists(file_dir)) dir.create(file_dir)

  # THE FILENAME SHOULD INCLUDE THE SEASON
  # WHEN SEASON == NULL, THE API WILL RETURN CURRENT SEASON
  # SO WE HAVE TO REPLACE NULL VALUES WITH THE CURRENT SEASON FOR THE FILENAME
  file_name <- paste0(
    "pff_roster_",
    season %||% nflreadr::most_recent_season(roster = TRUE),
    ".rds"
  )
  file_path <- file.path(file_dir, file_name)
  saveRDS(roster_pff, file_path)

  # WE RETURN FILEPATH HERE BECAUSE THERE WILL BE A LOOP OVER SEASONS
  return(file_path)
}
