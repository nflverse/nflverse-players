#' Download Players Components
#'
#' Downloads players component files from the release tag `players_components`
#' of the nflverse-players repo
#'
#' @param type One of `"full"`, `"basis"`, `"pfr"`, `"pff"`, `"otc"`, `"espn"`, `"draft"`, `"ngs"`
#'
#' @return A dataframe with players data
#' @export
players_download <- function(type = c("full", "basis", "pfr", "otc", "pff", "espn", "draft", "ngs")){
  type <- rlang::arg_match(type)
  available_files <- c(
    "basis" = "players_basis.rds",
    "pfr" = "players_pfr.rds",
    "otc" = "players_otc.rds",
    "pff" = "players_pff.rds",
    "espn" = "players_espn.rds",
    "draft" = "players_draft.rds",
    "ngs" = "players_ngs.rds",
    "full" = "players_full.rds"
  )
  load_file <- available_files[type]
  load_from <- file.path(
    "https://github.com/nflverse/nflverse-players/releases/download/players_components",
    load_file,
    fsep = "/"
  )

  out <- nflreadr::rds_from_url(load_from) |>
    .convert_ids()
  strip_nflverse_attributes(out)
}
