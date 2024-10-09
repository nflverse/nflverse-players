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

test_that("manual overwrite is not duplicated", {
  data <- players_fetch_manual_ids()
  check <- players_validate(data)
  expect_false(is_duplicated(check))
})

test_that("manual overwrite does not create duplicates", {
  data <- players_download("full") |>
    players_manual_overwrite()
  check <- players_validate(data)
  expect_false(is_duplicated(check))
})

test_that("complete dataset is not duplicated", {
  data <- players_build_dataset(release = FALSE)
  check <- players_validate(data)
  expect_false(is_duplicated(check))
})
