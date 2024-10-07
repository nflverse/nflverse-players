test_that("basis data is not replicated", {
  data <- players_download("basis")
  check <- players_validate(data)
  expect_false(is_replicated(check))
})

test_that("pfr data is not replicated", {
  data <- players_download("pfr")
  check <- players_validate(data)
  expect_false(is_replicated(check))
})

test_that("manual overwrite is not replicated", {
  data <- players_fetch_manual_ids()
  check <- players_validate(data)
  expect_false(is_replicated(check))
})

test_that("manual overwrite does not create replicates", {
  data <- players_download("full") |>
    players_manual_overwrite()
  check <- players_validate(data)
  expect_false(is_replicated(check))
})

test_that("complete dataset is not replicated", {
  data <- players_build_dataset(release = FALSE)
  check <- players_validate(data)
  expect_false(is_replicated(check))
})
