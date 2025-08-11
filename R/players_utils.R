# strip nflverse attributes for tests because timestamp and version cause failures
# .internal.selfref is a data.table attribute that is not necessary in this case
strip_nflverse_attributes <- function(df){
  input_attrs <- names(attributes(df))
  input_remove <- input_attrs[grepl("nflverse|.internal.selfref", input_attrs)]
  attributes(df)[input_remove] <- NULL
  df
}

remove_duplicated <- function(df,
                              id = relevant_ids(),
                              verbose = FALSE){
  id <- rlang::arg_match(id)
  mults <- identify_duplicated(df = df, id = id, verbose = verbose)
  df |>
    dplyr::filter(!is.na(.data[[id]])) |>
    dplyr::filter(dplyr::n() == 1, .by = {{ id }})
}

identify_duplicated <- function(df,
                                id = relevant_ids(),
                                verbose = TRUE){
  id <- rlang::arg_match(id)
  mults <- df |>
    dplyr::filter(!is.na(.data[[id]]), .data[[id]] != "") |>
    dplyr::filter(dplyr::n() > 1, .by = {{ id }}) |>
    dplyr::arrange(.data[[id]])
  if (nrow(mults) > 0 && isTRUE(verbose)){
    cli::cli_alert_warning("Found duplicated {.val {id}s}")
    print(mults)
  }
  invisible(mults)
}

relevant_ids <- function() c("gsis_id", "pfr_id", "pff_id", "otc_id", "espn_id")

.convert_ids <- function(df){
  df |>
    dplyr::mutate(
      dplyr::across(
        tidyselect::any_of(c("pff_id", "espn_id", "otc_id")),
        as.character
      )
    )
}

fix_headshot_url <- function(data) {
  if ("headshot" %in% names(data)) {
    data <- data |>
      dplyr::mutate(
        headshot = gsub(
          "\\{formatInstructions\\}",
          "f_auto,q_auto",
          headshot
        )
      )
  }
  data
}

upload_no_overwrites <- function(data) {
  if (!is.null(attr(data, "manual_overwrite"))) {
    cli::cli_abort("Won't upload files with applied overwrites!")
  }
  nflversedata::nflverse_save(
    data,
    file_name = "players_full_no_overwrites",
    nflverse_type = "nflverse Players Data",
    release_tag = "players_components",
    file_types = "rds",
    repo = "nflverse/nflverse-players"
  )

  data
}
