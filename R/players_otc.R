#' Release Players Overthecap IDs
#'
#' Thanks to overthecap who kindly grant us access to their player data! This
#' function queries player IDs from the OTC api and releases them to the release
#' tag `players_components` of the nflverse-players repo.
#'
#' @param players_otc_endpoint endpoint (defaults to environment variable PLAYERS_OTC_PLAYERID_ENDPOINT)
#' @param players_otc_api_key api key (defaults to environment variable PLAYERS_OTC_API_KEY)
#'
#' @details
#' Please note that the otc players data contain more than only an otc id to gsis
#' mapping. The data contains the following variables (example values from Eli Manning):
#' \itemize{
#'  \item{otc_id (865)}
#'  \item{nfl_player_id (2505996)}
#'  \item{ebdid (MAN473170)}
#'  \item{gsis_id (00-0022803)}
#'  \item{gsis_it_id (28953)}
#'  \item{pff_id (1722)}
#' }
#'
#' @return Returns the players OTC dataset invisibly
#' @export
players_otc_release <- function(players_otc_endpoint = Sys.getenv("PLAYERS_OTC_PLAYERID_ENDPOINT"),
                                players_otc_api_key = Sys.getenv("PLAYERS_OTC_API_KEY")){
  stopifnot(
    length(players_otc_endpoint) == 1 && nchar(players_otc_endpoint) > 0,
    length(players_otc_api_key) == 1 && nchar(players_otc_api_key) > 0
  )

  resp <- httr2::request(players_otc_endpoint) |>
    httr2::req_auth_bearer_token(players_otc_api_key) |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_perform()

  players_otc <- resp |>
    httr2::resp_body_string() |>
    jsonlite::fromJSON() |>
    dplyr::mutate_all(~replace(.x, .x %in% c("", 0), NA_character_)) |>
    dplyr::rename(
      gsis_it_id = gsis_id,
      gsis_id = gsis_player_id
    )

  nflversedata::nflverse_save(
    players_otc,
    file_name = "players_otc",
    nflverse_type = "Players Overthecap Data",
    release_tag = "players_components",
    file_types = "rds",
    repo = "nflverse/nflverse-players"
  )

  invisible(players_otc)
}
