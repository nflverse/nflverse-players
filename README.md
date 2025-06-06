<!-- badges: start -->
[![R-CMD-check](https://github.com/nflverse/nflverse.players/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/nflverse/nflverse.players/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

*!! THIS IS AN INTERNAL NFLVERSE PACKAGE. DO NOT TRY TO INSTALL IT OR WORK WITH IT !!*

# nflverse.players

This repo manages code and data to create players data available through

``` r 
nflreadr::load_players()
```

## Scope

We have a clear definition of which sources we include in the scope of 
nflverse.players. 
You can find the definition in our [contribution guide](.github/CONTRIBUTING.md) 

## Overview

The main functions of this package are

- `players_build_dataset()`: create and release the complete dataset
- `players_basis_release()`: create and release basis data (basic player info and gsis_ids)
- `players_draft_release()`: scrape and release draft information (round, pick, team, year)
- `players_otc_release()`  : fetch and release player IDs from overthecap (otc_id and pff_id)
- `players_pff_release()`  : release pff players data (joinable through pff_id)
- `players_pfr_release()`  : create and release pfr player IDs (joinable through gsis_id)
- `players_espn_release()` : create and release espn player IDs (joinable through gsis_id)
- `players_validate()`     : dataset check that searches for duplicated IDs
- `players_download()`     : download components from the `players_components` release tag of this repo

Basis, draft, otc, pfr, and espn data are released to the `players_components` release 
tag of this repo. Data updates automatically over night (draft data only in the 
days around the draft).

Since the workflows can't be perfect, there will always be mismatches or missing 
IDs. The package provides a solution for this problem. The ultimate source of truth 
is saved in `inst/players_manual_overwrite.json`. The package will load this data
inside the function `players_manual_overwrite()` and overwrites all IDs with the
ones in the json file. This allows us to manually modify IDs without having to
change code.

## How to Contribute?

Please see the [contribution guide](.github/CONTRIBUTING.md) 
for further information.

## What's New in Players V2?

Players data from this repo can be considered as version 2. They were officially 
introduced to nflverse in the offseason after the 2024 season and replace the 
data previously provided via `nflreadr::load_players()`. This is a **breaking 
change** because some variables have been removed or renamed. The table below 
compares all variables from v1 and v2 and shows which have been removed, which 
have been renamed and what they are now named, including a reason.

<div align="center">
<img src="man/figures/data_comparison.png" width="800px">
</div>
