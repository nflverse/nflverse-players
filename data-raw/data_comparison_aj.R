# aj <- readRDS("~/Documents/Analytics/Dropbox/misc-mrcaseb/data/master_player_mapping.rds")

players <- nflverse.players::players_download()

## PFR

aj_pfr <- aj |>
  dplyr::filter(!pfr_id %in% players$pfr_id, !is.na(pfr_id), !is.na(gsis_id))

join_pfr <- players |>
  dplyr::left_join(
    aj_pfr |> dplyr::select(gsis_id, pfr_id_aj = pfr_id), by = "gsis_id"
  ) |>
  dplyr::filter(
    pfr_id != pfr_id_aj | (is.na(pfr_id) & !is.na(pfr_id_aj))
  ) |>
  dplyr::select(
    gsis_id:football_name, pfr_id, pfr_id_aj, birth_date, position, height, weight
  )

# 00-0037760 = GuntJe01 -> AJ
# 00-0034887 = JohnAl01 -> SEB
# 00-0037587 = LandNa01 -> SEB
# 00-0028141 = WillZa01 -> SEB
# 00-0036535 = SherWi01 -> AJ
# 00-0029829 = SwanDa01 -> AJ
# 00-0028650 = LefeJo00 -> AJ


## PFF

aj_pff <- aj |>
  dplyr::mutate(pff_id = as.character(pff_id)) |>
  dplyr::filter(!pff_id %in% players$pff_id, !is.na(pff_id), !is.na(gsis_id))

join_pff <- players |>
  dplyr::left_join(
    aj_pff |> dplyr::select(gsis_id, pff_id_aj = pff_id), by = "gsis_id"
  ) |>
  dplyr::filter(
    pff_id != pff_id_aj | (is.na(pff_id) & !is.na(pff_id_aj))
  ) |>
  dplyr::select(
    gsis_id:football_name, pff_id, pff_id_aj, birth_date, position, height, weight
  )

# 00-0023053 = 2517 -> AJ
# 00-0037052 = 56037 -> AJ
# 00-0025560 = 3789 -> AJ
# 00-0023498 = 2280 -> AJ
# 00-0027895 = 5618 -> AJ

## NFL ID

aj_nfl <- aj |>
  dplyr::mutate(nfl_id = as.character(nfl_id)) |>
  dplyr::filter(!nfl_id %in% players$nfl_id, !is.na(nfl_id), !is.na(gsis_id))

join_nfl <- players |>
  dplyr::left_join(
    aj_nfl |> dplyr::select(gsis_id, nfl_id_aj = nfl_id), by = "gsis_id"
  ) |>
  dplyr::filter(
    nfl_id != nfl_id_aj | (is.na(nfl_id) & !is.na(nfl_id_aj))
  ) |>
  dplyr::select(
    gsis_id:football_name, nfl_id, nfl_id_aj, birth_date, position, height, weight
  )

## OTC ID

aj_otc <- aj |>
  dplyr::mutate(otc_id = as.character(otc_id)) |>
  dplyr::filter(!otc_id %in% players$otc_id, !is.na(otc_id), !is.na(gsis_id))

join_otc <- players |>
  dplyr::left_join(
    aj_otc |> dplyr::select(gsis_id, otc_id_aj = otc_id), by = "gsis_id"
  ) |>
  dplyr::filter(
    otc_id != otc_id_aj | (is.na(otc_id) & !is.na(otc_id_aj))
  ) |>
  dplyr::select(
    gsis_id:football_name, otc_id, otc_id_aj, birth_date, position, height, weight
  )

## Add to manual overwrite

manual <- players_manual_ids_fetch()

new <- manual |>
  dplyr::rows_upsert(
    join_nfl |> dplyr::select(gsis_id, nfl_id = nfl_id_aj),
    by = "gsis_id"
  ) |>
  dplyr::rows_upsert(
    join_pff |> dplyr::select(gsis_id, pff_id = pff_id_aj),
    by = "gsis_id"
  ) |>
  dplyr::rows_upsert(
    join_pfr |> dplyr::select(gsis_id, pfr_id = pfr_id_aj),
    by = "gsis_id"
  ) |>
  dplyr::arrange(dplyr::desc(gsis_id))

jsonlite::write_json(
  new,
  "inst/players_manual_overwrite.json",
  pretty = TRUE
)

