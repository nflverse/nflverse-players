#' Release Players Draft File
#'
#' This function downloads yearly draft files from the release tag `draft`
#' in the nflverse-players repo, and summarizes the data (uses the latest season
#' of each player) to the players draft dataset. Yearly draft data is saved locally.
#' Set argument `overwrite` to `TRUE` to always download the latest data.
#' The function finishes by releasing the players draft data to the release tag
#' `players_components` of the nflverse-players repo.
#'
#' @param overwrite If `TRUE` overwrites all existing draft files in the
#' directory `./build/draft`.
#'
#' @return Returns the players draft dataset invisibly
#' @export
players_draft_release <- function(overwrite = !interactive()){
  draft_files <- .draft_download(overwrite = overwrite)
  draft <- purrr::map(draft_files, readRDS) |>
    purrr::list_rbind()

  nflversedata::nflverse_save(
    draft,
    file_name = "players_draft",
    nflverse_type = "Draft Data",
    release_tag = "players_components",
    file_types = "rds",
    repo = "nflverse/nflverse-players"
  )

  invisible(draft)
}

#' Release Single Season Draft Data
#'
#' This function scrapes the PFR draft websites to obtain relevant draft data
#' by year of the draft. Currently it looks for the following information:
#' \itemize{
#'  \item{pfr_id (used to join the data to the players dataset)}
#'  \item{draft_year}
#'  \item{draft_round}
#'  \item{draft_pick}
#'  \item{draft_team}
#' }
#'
#' The function finishes by releasing a table with the above listed data to the
#' release tag `draft` of the nflverse-players repo.
#'
#' @param years One or more draft years to scrape data for. The function will
#' loop over a vector of years.
#'
#' @return `TRUE` invisibly
#' @export
.draft_release_season <- function(years){
  draft_dir <- file.path(getwd(), "build", "draft")
  if (!dir.exists(draft_dir)) dir.create(draft_dir)

  file_paths <- purrr::map_chr(years, function(s, draft_dir){
    save_to <- file.path(draft_dir, paste0("draft_", s, ".rds"))
    d <- .draft_scrape(s)
    saveRDS(d, save_to)
    save_to
  }, draft_dir = draft_dir, .progress = FALSE)

  nflversedata::nflverse_upload(
    file_paths,
    tag = "draft",
    repo = "nflverse/nflverse-players"
  )

  invisible(TRUE)
}

.draft_scrape <- function(year) {
  scrape_from <- file.path(
    "https://www.pro-football-reference.com/years",
    year,
    "draft.htm",
    fsep = "/"
  )
  cli::cli_progress_step(
    "Scraping {.url {scrape_from}}"
  )
  # Make sure PFR doesn't get mad at us
  Sys.sleep(3)

  raw_html <- httr2::request("https://www.pro-football-reference.com/years") |>
    httr2::req_url_path_append(year, "draft.htm") |>
    httr2::req_perform() |>
    httr2::resp_body_html() |>
    xml2::xml_find_all("//table/tbody/tr[not(@class='thead')]")

  draft_round <- raw_html |>
    xml2::xml_find_all("./*[contains(concat(' ',normalize-space(@data-stat),' '),'draft_round')]") |>
    xml2::xml_text() |>
    as.integer()

  draft_pick <- raw_html |>
    xml2::xml_find_all("./*[contains(concat(' ',normalize-space(@data-stat),' '),'draft_pick')]") |>
    xml2::xml_text() |>
    as.integer()

  draft_team <- raw_html |>
    xml2::xml_find_all("./td[contains(concat(' ',normalize-space(@data-stat),' '),' team ')]") |>
    xml2::xml_text()

  pfr_id <- raw_html |>
    xml2::xml_find_all("./*[contains(concat(' ',normalize-space(@data-stat),' '),'player')]") |>
    xml2::xml_attr("data-append-csv")

  tbl <- tibble::tibble(
    pfr_id = pfr_id,
    draft_year = as.integer(year),
    draft_round = draft_round,
    draft_pick = draft_pick,
    draft_team = draft_team
  )

  cli::cli_progress_done()

  tbl
}

.draft_download <- function(overwrite = !interactive()) {
  to_load <- file.path(
    "https://github.com/nflverse/nflverse-players/releases/download/draft",
    paste0(
      "draft_",
      seq(1974, nflreadr::most_recent_season(roster = TRUE)),
      ".rds"
    ),
    fsep = "/"
  )

  save_dir <- file.path(getwd(), "build", "draft")
  if (!dir.exists(save_dir)) dir.create(save_dir)
  save_to <- file.path(save_dir, basename(to_load))

  succeeded <- character()
  exists_locally <- character()

  if (isFALSE(overwrite)){
    exists <- file.exists(save_to)
    initial_to_load <- to_load
    initial_save_to <- save_to
    to_load <- to_load[!exists]
    save_to <- save_to[!exists]
    cli::cli_alert_info("Going to skip {.url {basename(initial_to_load[exists])}} because the \\
                        files exist locally and {.arg overwrite} is set to {.val FALSE}")
    exists_locally <- initial_save_to[exists]
  }

  if (length(to_load)){
    status <- curl::multi_download(to_load, save_to)

    failed <- status[status$status_code != 200,]

    if (nrow(failed > 0)){
      cli::cli_alert_warning("Failed to download the following {cli::qty(nrow(failed))}file{?s}: {.url {failed$url}}")
    }

    succeeded <- status$destfile[status$status_code == 200]

  }
  raw_files <- c(exists_locally, succeeded)

  if (length(raw_files) == 0){
    cli::cli_abort("No successful downloads and no local copies available. \\
                   It doesn't make sense to continue at this point.")
  }

  raw_files
}
