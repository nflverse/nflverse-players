# THIS IS CODE TO QUERY PFF TEAM IDs BUT AS OF 2024 THOSE ARE REALLY JUST 1:32

library(httr2)
pff_teams <- purrr::map(
  seq(2016, nflreadr::most_recent_season(roster = TRUE)),
  function(s){
    request("https://premium.pff.com/api/v1/teams/overview") |>
      req_url_query(
        league = "nfl",
        season = s
      ) |>
      req_perform() |>
      resp_body_json() |>
      purrr::pluck("team_overview") |>
      data.table::rbindlist(fill = TRUE) |>
      dplyr::mutate(season = s)
  }, .progress = TRUE) |>
  data.table::rbindlist(fill = TRUE) |>
  dplyr::select(
    season,
    team = abbreviation,
    team_id = franchise_id
  ) |>
  dplyr::mutate(
    team = nflreadr::clean_team_abbrs(team)
  )
