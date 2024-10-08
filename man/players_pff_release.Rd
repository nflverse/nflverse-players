% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/players_pff.R
\name{players_pff_release}
\alias{players_pff_release}
\title{Release Players PFF File}
\usage{
players_pff_release(overwrite = !interactive())
}
\arguments{
\item{overwrite}{If \code{TRUE} overwrites all existing raw pff files in the
directory \code{./build/raw_pff}.}
}
\value{
Returns the players pff dataset invisibly
}
\description{
This function downloads raw pff player files from the release tag \code{raw_pff}
in the nflverse-players repo, and summarizes the data (uses the latest season
of each player) to the players pff dataset. Raw players data are saved locally.
Set argument \code{overwrite} to \code{TRUE} to always download the latest data.
The function finishes by releasing the players pff data to the release tag
\code{players_components} of the nflverse-players repo.
}
