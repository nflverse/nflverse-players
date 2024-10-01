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

basis <- players_download("basis")

# PFR ---------------------------------------------------------------------

pfr_ids <- players_download("pfr")

join_pfr <- json |>
  dplyr::select(gsis_id, pfr_id) |>
  dplyr::filter(!is.na(pfr_id), !is.na(gsis_id)) |>
  dplyr::left_join(pfr_ids, by = "gsis_id") |>
  dplyr::filter(is.na(pfr_id.y)) |>
  dplyr::select(gsis_id, pfr_id = pfr_id.x)

problematic <- join_pfr |>
  dplyr::filter(is.na(pfr_id.y))

p <- basis |>
  dplyr::filter(gsis_id %in% problematic$gsis_id)

# 37420 - this repo was correct
# 35848 - DeMichael Harris is a special case. In the 2020/21 seasons, he is HarrDe09. In 2022 he is HarrDe11. I messaged PFR about that and stick with HarrDe09
# 29435 - this repo was correct

saveRDS(join_pfr, "data-raw/manual_pfr.rds")


# OTC ---------------------------------------------------------------------

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

join_pff <- json |>
  dplyr::select(gsis_id, pff_id) |>
  dplyr::filter(!is.na(pff_id), !is.na(gsis_id)) |>
  dplyr::left_join(pff_ids, by = "gsis_id") |>
  dplyr::filter(is.na(pff_id.y) | (pff_id.x != pff_id.y)) |>
  dplyr::select(gsis_id, tidyselect::starts_with("pff_id")) |>
  dplyr::select(gsis_id, pff_id = pff_id.x) |>
  dplyr::mutate(
    pff_id = ifelse(gsis_id == "00-0029435", 7530L, pff_id)
  )

# 29435 - this repo was correct
# 35857 - use dynastyprocess one

saveRDS(join_pff, "data-raw/manual_pff.rds")


# SUMMARY -----------------------------------------------------------------

manual_overwrite <- readRDS("data-raw/manual_pff.rds") |>
  dplyr::full_join(readRDS("data-raw/manual_pfr.rds")) |>
  dplyr::full_join(readRDS("data-raw/manual_otc.rds")) |>
  dplyr::arrange(dplyr::desc(gsis_id))

# NOTE the pretty arg for better readability
jsonlite::write_json(manual_overwrite, "players_manual_overwrite.json", pretty = TRUE)
