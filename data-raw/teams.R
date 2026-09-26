## code to prepare `teams` dataset goes here

teams <- ngsscrapR::scrape_teams(2026) |>
  dplyr::filter_out(abbr %in% c("AFC", "NFC")) |>
  dplyr::mutate(
    abbr = nflreadr::clean_team_abbrs(abbr)
  ) |>
  dplyr::select(team_id, abbr)

usethis::use_data(teams, overwrite = TRUE, internal = TRUE)
