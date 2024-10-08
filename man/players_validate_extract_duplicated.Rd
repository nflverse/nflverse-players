% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/players_validate.R
\name{players_validate_extract_duplicated}
\alias{players_validate_extract_duplicated}
\title{Extract Table of duplicated Data}
\usage{
players_validate_extract_duplicated(data, id = relevant_ids())
}
\arguments{
\item{data}{A data frame that was checked with \link{players_validate}}

\item{id}{ID to extract a table of duplicates. Must be one of
gsis_id, pfr_id, pff_id, otc_id, and espn_id}
}
\value{
A table of duplicated IDs, sorted by value of \code{id}
}
\description{
Extract Table of duplicated Data
}
