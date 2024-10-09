# This file loads the json file with manual ids from dynastyprocess, compares the
# ids to the ones we have in this repo (and releases), and saves the observations
# that really need a correction.

# Initially loaded from
# "https://github.com/dynastyprocess/data/raw/refs/heads/master/files/missing_ids.json"
json <- players_fetch_manual_ids() |>
  dplyr::arrange(dplyr::desc(gsis_id)) |>
  dplyr::select(
    gsis_id, pff_id, pfr_id, otc_id
  ) |>
  dplyr::filter(dplyr::if_any(c(pff_id, pfr_id, otc_id), ~ !is.na(.x)))

ff <- nflreadr::load_ff_playerids() |>
  dplyr::select(gsis_id, pff_id, pfr_id, espn_id) |>
  dplyr::filter(dplyr::if_any(c(pff_id, pfr_id, espn_id), ~ !is.na(.x)))

basis <- players_download("basis")

# PFR ---------------------------------------------------------------------

pfr_ids <- players_download("pfr")

join_pfr <- ff |>
  dplyr::select(gsis_id, pfr_id) |>
  dplyr::filter(!is.na(pfr_id), !is.na(gsis_id)) |>
  dplyr::left_join(pfr_ids, by = "gsis_id") |>
  dplyr::filter(is.na(pfr_id.y) | (pfr_id.x != pfr_id.y)) |>
  dplyr::mutate(
    pfr_id = dplyr::case_when(
      # see list below. I checked all of these mismatches manually
      gsis_id == "00-0037420" ~ "LassKw00",
      gsis_id == "00-0036400" ~ "BrowCa01",
      gsis_id == "00-0035848" ~ "HarrDe09",
      gsis_id == "00-0034685" ~ "CampCh01",
      gsis_id == "00-0032050" ~ "MoorCo00",
      gsis_id == "00-0030500" ~ "WillNi01",
      gsis_id == "00-0030126" ~ "JohnTJ00",
      gsis_id == "00-0029435" ~ "JohnDa04",
      gsis_id == "00-0027959" ~ "TaylPh00",
      gsis_id == "00-0026364" ~ "JohnSt00",
      TRUE ~ pfr_id.x
    )
  ) |>
  dplyr::select(gsis_id, pfr_id)

# For these players, the data in this repo's release and the data in
# load_ff_playerids do not agree
duplicated <- join_pfr |>
  dplyr::filter(pfr_id.x != pfr_id.y)

p <- basis |>
  dplyr::filter(gsis_id %in% duplicated$gsis_id)

# Only solution is manual inspection and documentation
# 37420 - LassKw00 -> ff is wrong
# 36400 - BrowCa01 -> ff is right
# 35848 - DeMichael Harris is a special case. PFR assigned two IDs HarrDe09, and
#         HarrDe11. I messaged PFR about that and stick with HarrDe09 -> ff is wrong
# 34685 - CampCh01 -> ff is right
# 32050 - MoorCo00 -> ff is wrong
# 30500 - WillNi01 -> ff is right
# 30126 - JohnTJ00 -> ff is wrong
# 29435 - JohnDa04 -> ff is wrong
# 27959 - TaylPh00 -> ff is right -> TaylPh01 seems to be a duplicate smh
# 26364 - JohnSt00 -> ff is right

saveRDS(join_pfr, "data-raw/manual_pfr.rds")


# ESPN --------------------------------------------------------------------

espn_ids <- players_download("espn")

join_espn <- ff |>
  dplyr::mutate(espn_id = as.integer(espn_id)) |>
  dplyr::select(gsis_id, espn_id) |>
  dplyr::filter(!is.na(espn_id), !is.na(gsis_id)) |>
  dplyr::left_join(espn_ids, by = "gsis_id") |>
  dplyr::filter(is.na(espn_id.y) | (espn_id.x != espn_id.y)) |>
  dplyr::mutate(
    espn_id = dplyr::case_when(
      # see list below. I checked all of these mismatches manually
      gsis_id == "00-0036897" ~ 4568981L,
      gsis_id == "00-0035923" ~ 4046605L,
      gsis_id == "00-0032430" ~ 2580052L,
      gsis_id == "00-0031612" ~ 2577467L,
      gsis_id == "00-0031087" ~ 17467L,
      gsis_id == "00-0031059" ~ 16904L,
      gsis_id == "00-0029112" ~ 15356L,
      TRUE ~ as.integer(espn_id.x)
    )
  ) |>
  dplyr::select(gsis_id, espn_id)

# For these players, the data in this repo's release and the data in
# load_ff_playerids do not agree
duplicated <- join_espn |>
  dplyr::filter(espn_id.x != espn_id.y)

p <- basis |>
  dplyr::filter(gsis_id %in% duplicated$gsis_id)

# Only solution is manual inspection and documentation
# 36897 - 4568981 -> ff is wrong
# 35923 - 4046605 -> ff is right
# 32430 - 2580052 -> ff is wrong
# 31612 - 2577467 -> ff is wrong
# 31087 - 17467   -> ff is wrong
# 31059 - 16904   -> ff is wrong
# 29112 - 15356   -> ff is wrong

saveRDS(join_espn, "data-raw/manual_espn.rds")


# OTC ---------------------------------------------------------------------

# No otc in ff_playerids, so we use the json file instead
otc_ids <- players_download("otc")

join_otc <- json |>
  dplyr::select(gsis_id, otc_id) |>
  dplyr::filter(!is.na(otc_id), !is.na(gsis_id)) |>
  dplyr::left_join(otc_ids, by = "gsis_id") |>
  dplyr::filter(is.na(otc_id.y) | (otc_id.x != otc_id.y)) |>
  dplyr::select(gsis_id, otc_id = otc_id.x)

p <- basis |>
  dplyr::filter(gsis_id %in% join_otc$gsis_id)

saveRDS(join_otc, "data-raw/manual_otc.rds")


# PFF ---------------------------------------------------------------------

pff_ids <- players_download("otc")

join_pff <- ff |>
  dplyr::select(gsis_id, pff_id) |>
  dplyr::filter(!is.na(pff_id), !is.na(gsis_id)) |>
  dplyr::left_join(pff_ids, by = "gsis_id") |>
  dplyr::filter(is.na(pff_id.y) | (pff_id.x != pff_id.y)) |>
  dplyr::mutate(
    pff_id = dplyr::case_when(
      # see list below. I checked all of these mismatches manually
      gsis_id == "00-0035857" ~ 87178L,
      gsis_id == "00-0035306" ~ 37479L,
      gsis_id == "00-0034270" ~ 47124L,
      gsis_id == "00-0029435" ~ 7530L,
      gsis_id == "00-0027044" ~ 4993L,
      TRUE ~ as.integer(pff_id.x)
    )
  ) |>
  dplyr::select(gsis_id, pff_id)

# For these players, the data in this repo's release and the data in
# load_ff_playerids do not agree
duplicated <- join_pff |>
  dplyr::filter(pff_id.x != pff_id.y)

p <- basis |>
  dplyr::filter(gsis_id %in% duplicated$gsis_id)

# 35857 - 87178 -> ff is right
# 35306 - 37479 -> ff is right
# 34270 - 47124 -> ff is wrong
# 29435 - 7530 -> ff is wrong
# 27044 - 4993 -> ff is right

saveRDS(join_pff, "data-raw/manual_pff.rds")

# SUMMARY -----------------------------------------------------------------

manual_overwrite <- readRDS("data-raw/manual_pff.rds") |>
  dplyr::full_join(readRDS("data-raw/manual_pfr.rds")) |>
  dplyr::full_join(readRDS("data-raw/manual_otc.rds")) |>
  dplyr::arrange(dplyr::desc(gsis_id))

# NOTE the pretty arg for better readability
jsonlite::write_json(manual_overwrite, "inst/players_manual_overwrite.json", pretty = TRUE)
