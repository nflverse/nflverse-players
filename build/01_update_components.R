type <- Sys.getenv("NFLVERSE_UPDATE_TYPE", unset = NA_character_)
type <- rlang::arg_match0(type, c("basis", "pfr", "otc", "draft", "pff", "espn", "ngs"))

if (type == "basis"){
  out <- nflverse.players::players_basis_release()
} else if (type == "pfr"){
  # Uses env vars PLAYERS_PFR_REBUILD & PLAYERS_PFR_BASE
  out <- nflverse.players::players_pfr_release()
} else if (type == "otc"){
  # Uses env vars PLAYERS_OTC_PLAYERID_ENDPOINT & PLAYERS_OTC_API_KEY
  out <- nflverse.players::players_otc_release()
} else if (type == "draft"){
  out <- nflverse.players::players_draft_release()
} else if (type == "pff"){
  out <- nflverse.players::players_pff_release()
} else if (type == "espn"){
  out <- nflverse.players::players_espn_release()
} else if (type == "ngs"){
  out <- nflverse.players::players_ngs_release()
}
