test_that("basis data is not duplicated", {
  data <- players_download("basis")
  check <- players_validate(data)
  expect_false(is_duplicated(check))
})

test_that("pfr data is not duplicated", {
  data <- players_download("pfr")
  check <- players_validate(data)
  expect_false(is_duplicated(check))
})

test_that("pff data is not duplicated", {
  data <- players_download("pff")
  check <- players_validate(data)
  expect_false(is_duplicated(check))
})

test_that("espn data is not duplicated", {
  data <- players_download("espn")
  check <- players_validate(data)
  expect_false(is_duplicated(check))
})

test_that("ngs data is not duplicated", {
  data <- players_download("ngs")
  check <- players_validate(data)
  expect_false(is_duplicated(check))
})

test_that("manual overwrite is not duplicated", {
  data <- players_manual_ids_fetch()
  check <- players_validate(data)
  expect_false(is_duplicated(check))
})

test_that("manual overwrite does not create duplicates", {
  data <- players_download("no_overwrites") |>
    players_manual_overwrite()
  check <- players_validate(data)
  expect_false(is_duplicated(check))
})

test_that("manual overwrite is clean", {
  manual_ids <- players_manual_ids_fetch()
  cleaned <- players_manual_ids_clean(manual_ids)
  expect_identical(cleaned, manual_ids)
})

test_that("complete dataset is not duplicated", {
  data <- players_build_dataset(release = FALSE)
  check <- players_validate(data)
  expect_false(is_duplicated(check))
})
