old_p <- nflreadr::load_players() |>
  dplyr::filter(position == "QB") |>
  dplyr::slice_sample(n = 2)

new_p <- nflverse.players::players_download("full") |>
  dplyr::filter(position == "QB") |>
  dplyr::slice_sample(n = 2)

pillar::glimpse(old_p)
pillar::glimpse(new_p)

paste0('"', names(old_p), '",') |>
  cli::cli_code()

tbl <- tibble::tribble(
  ~old_var, ~new_var, ~details,
  "status", "status", NA_character_,
  "display_name", "display_name", NA_character_,
  "first_name", "first_name", NA_character_,
  "last_name", "last_name", NA_character_,
  "esb_id", "esb_id", NA_character_,
  "gsis_id", "gsis_id", NA_character_,
  "birth_date", "birth_date", NA_character_,
  "college_name", "college_name", NA_character_,
  "position_group", "position_group", NA_character_,
  "position", "position", NA_character_,
  "jersey_number", "jersey_number", NA_character_,
  "height", "height", NA_character_,
  "weight", "weight", NA_character_,
  "years_of_experience", "years_of_experience", NA_character_,
  "team_abbr", "latest_team", "renamed as team_abbr doesn't make sense for retired players",
  "team_seq", NA_character_, "needless variable",
  "current_team_id", NA_character_, "needless; only used in ngs and nfl apis",
  "football_name", "football_name", NA_character_,
  "entry_year", NA_character_, "no source and mostly same as rookie_year",
  "rookie_year", "rookie_season", "renamed for consistency",
  "draft_club", "draft_team", "renamed for consistency",
  "draft_number", "draft_pick", "idk why this was called number",
  "college_conference", "college_conference", NA_character_,
  "status_description_abbr", NA_character_, "needless; we have ngs_status and ngs_status_short_description",
  "status_short_description", "ngs_status_short_description", "renamed for consistency",
  "gsis_it_id", "nfl_id", "renamed as it is named nfl_id in Big Data Bowl",
  "short_name", "short_name", NA_character_,
  "smart_id", "smart_id", NA_character_,
  "headshot", "headshot", NA_character_,
  "suffix", "suffix", NA_character_,
  "uniform_number", NA_character_, "duplicate of jersey number from different source",
  "draft_round", "draft_round", NA_character_,
  NA_character_, "common_first_name", "new variable",
  NA_character_, "pfr_id", "new variable",
  NA_character_, "pff_id", "new variable",
  NA_character_, "otc_id", "new variable",
  NA_character_, "espn_id", "new variable",
  NA_character_, "last_season", "new variable",
  NA_character_, "pff_position", "new variable",
  NA_character_, "pff_status", "new variable",
  NA_character_, "draft_year", "new variable"
) |>
  gt::gt() |>
  gt::sub_missing() |>
  mrcaseb::gt_table_theme() |>
  gt::data_color(
    rows = old_var != new_var,
    palette = "orange"
  ) |>
  gt::data_color(
    rows = is.na(new_var),
    palette = "red",
    na_color = "red"
  ) |>
  gt::data_color(
    rows = is.na(old_var),
    palette = "blue",
    na_color = "blue"
  ) |>
  gt::tab_header(
    "Comparing Players Data V1 and V2",
    gt::html("RED = Variable removed<br>ORANGE = Variable renamed<br>BLUE = New variable")
  )

gt::gtsave(tbl, "man/figures/data_comparison.png", zoom = 3)

new_names <- names(new_p)
old_names <- names(old_p)

new_names[!new_names %in% old_names]

paste0('"', new_names[!new_names %in% old_names], '",') |>
  cli::cli_code()
