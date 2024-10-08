season <- Sys.getenv("NFLVERSE_UPDATE_SEASON", unset = NA_character_) |> as.integer()

type <- Sys.getenv("NFLVERSE_UPDATE_TYPE", unset = NA_character_)
type <- rlang::arg_match0(type, c("roster", "raw_draft", "raw_pff"))

if (type == "roster"){
  out <- nflverse.players::.basis_release_raw_roster(seasons = season)
} else if (type == "raw_draft"){
  # We ask for Draft in every Workflow run but we actually try to scrape
  # only if the system date is inside an arbitrarily chosen range around the
  # possible draft date at the end of April
  if (Sys.Date() %in% nflverse.players:::.draft_date_range()){
    out <- nflverse.players::.draft_release_season(years = season)
  }
} else if (type == "raw_pff" && .pff_is_valid_season(season)){
  out <- nflverse.players::.pff_release_raw_players(seasons = season)
}
