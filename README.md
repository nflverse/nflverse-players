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
data previously provided via `nflreadr::load_players()`. This is a breaking 
change because some variables have been removed or renamed. The table below 
compares all variables from v1 and v2 and shows which have been removed, which 
have been renamed and what they are now called, including a reason.

<div id="rubuwsjram" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>@import url("https://fonts.googleapis.com/css2?family=Prosto+One:ital,wght@0,100;0,200;0,300;0,400;0,500;0,600;0,700;0,800;0,900;1,100;1,200;1,300;1,400;1,500;1,600;1,700;1,800;1,900&display=swap");
@import url("https://fonts.googleapis.com/css2?family=Roboto+Condensed:ital,wght@0,100;0,200;0,300;0,400;0,500;0,600;0,700;0,800;0,900;1,100;1,200;1,300;1,400;1,500;1,600;1,700;1,800;1,900&display=swap");
#rubuwsjram table {
  font-family: 'Roboto Condensed', system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#rubuwsjram thead, #rubuwsjram tbody, #rubuwsjram tfoot, #rubuwsjram tr, #rubuwsjram td, #rubuwsjram th {
  border-style: none;
}
&#10;#rubuwsjram p {
  margin: 0;
  padding: 0;
}
&#10;#rubuwsjram .gt_table {
  display: table;
  border-collapse: collapse;
  line-height: normal;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: none;
  border-top-width: 3px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}
&#10;#rubuwsjram .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#rubuwsjram .gt_title {
  color: #FFFFFF;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}
&#10;#rubuwsjram .gt_subtitle {
  color: #FFFFFF;
  font-size: 85%;
  font-weight: initial;
  padding-top: 3px;
  padding-bottom: 5px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}
&#10;#rubuwsjram .gt_heading {
  background-color: #4D4D4D;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#rubuwsjram .gt_bottom_border {
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#rubuwsjram .gt_col_headings {
  border-top-style: none;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #000000;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#rubuwsjram .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 80%;
  font-weight: normal;
  text-transform: uppercase;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}
&#10;#rubuwsjram .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 80%;
  font-weight: normal;
  text-transform: uppercase;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}
&#10;#rubuwsjram .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#rubuwsjram .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#rubuwsjram .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #000000;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}
&#10;#rubuwsjram .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#rubuwsjram .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 80%;
  font-weight: bolder;
  text-transform: uppercase;
  border-top-style: none;
  border-top-width: 2px;
  border-top-color: #000000;
  border-bottom-style: solid;
  border-bottom-width: 1px;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  text-align: left;
}
&#10;#rubuwsjram .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 80%;
  font-weight: bolder;
  border-top-style: none;
  border-top-width: 2px;
  border-top-color: #000000;
  border-bottom-style: solid;
  border-bottom-width: 1px;
  border-bottom-color: #FFFFFF;
  vertical-align: middle;
}
&#10;#rubuwsjram .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#rubuwsjram .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#rubuwsjram .gt_row {
  padding-top: 3px;
  padding-bottom: 3px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}
&#10;#rubuwsjram .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 80%;
  font-weight: bolder;
  text-transform: uppercase;
  border-right-style: solid;
  border-right-width: 0px;
  border-right-color: #FFFFFF;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#rubuwsjram .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}
&#10;#rubuwsjram .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#rubuwsjram .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#rubuwsjram .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#rubuwsjram .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#rubuwsjram .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#rubuwsjram .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#rubuwsjram .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#rubuwsjram .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#rubuwsjram .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#rubuwsjram .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#rubuwsjram .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#rubuwsjram .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#rubuwsjram .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#rubuwsjram .gt_sourcenotes {
  color: #FFFFFF;
  background-color: #4D4D4D;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#rubuwsjram .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#rubuwsjram .gt_left {
  text-align: left;
}
&#10;#rubuwsjram .gt_center {
  text-align: center;
}
&#10;#rubuwsjram .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#rubuwsjram .gt_font_normal {
  font-weight: normal;
}
&#10;#rubuwsjram .gt_font_bold {
  font-weight: bold;
}
&#10;#rubuwsjram .gt_font_italic {
  font-style: italic;
}
&#10;#rubuwsjram .gt_super {
  font-size: 65%;
}
&#10;#rubuwsjram .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#rubuwsjram .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#rubuwsjram .gt_indent_1 {
  text-indent: 5px;
}
&#10;#rubuwsjram .gt_indent_2 {
  text-indent: 10px;
}
&#10;#rubuwsjram .gt_indent_3 {
  text-indent: 15px;
}
&#10;#rubuwsjram .gt_indent_4 {
  text-indent: 20px;
}
&#10;#rubuwsjram .gt_indent_5 {
  text-indent: 25px;
}
&#10;#rubuwsjram .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#rubuwsjram div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    <tr class="gt_heading">
      <td colspan="3" class="gt_heading gt_title gt_font_normal" style="font-family: 'Prosto One', system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji'; font-weight: bold;">Comparing Players Data V1 and V2</td>
    </tr>
    <tr class="gt_heading">
      <td colspan="3" class="gt_heading gt_subtitle gt_font_normal gt_bottom_border" style>RED = Variable removed<br>ORANGE = Variable renamed<br>BLUE = New variable</td>
    </tr>
    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" style="border-top-width: 0px; border-top-style: solid; border-top-color: black;" scope="col" id="old_var">old_var</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" style="border-top-width: 0px; border-top-style: solid; border-top-color: black;" scope="col" id="new_var">new_var</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" style="border-top-width: 0px; border-top-style: solid; border-top-color: black;" scope="col" id="details">details</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td headers="old_var" class="gt_row gt_left">status</td>
<td headers="new_var" class="gt_row gt_left">status</td>
<td headers="details" class="gt_row gt_left">—</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left">display_name</td>
<td headers="new_var" class="gt_row gt_left">display_name</td>
<td headers="details" class="gt_row gt_left">—</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left">first_name</td>
<td headers="new_var" class="gt_row gt_left">first_name</td>
<td headers="details" class="gt_row gt_left">—</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left">last_name</td>
<td headers="new_var" class="gt_row gt_left">last_name</td>
<td headers="details" class="gt_row gt_left">—</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left">esb_id</td>
<td headers="new_var" class="gt_row gt_left">esb_id</td>
<td headers="details" class="gt_row gt_left">—</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left">gsis_id</td>
<td headers="new_var" class="gt_row gt_left">gsis_id</td>
<td headers="details" class="gt_row gt_left">—</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left">birth_date</td>
<td headers="new_var" class="gt_row gt_left">birth_date</td>
<td headers="details" class="gt_row gt_left">—</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left">college_name</td>
<td headers="new_var" class="gt_row gt_left">college_name</td>
<td headers="details" class="gt_row gt_left">—</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left">position_group</td>
<td headers="new_var" class="gt_row gt_left">position_group</td>
<td headers="details" class="gt_row gt_left">—</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left">position</td>
<td headers="new_var" class="gt_row gt_left">position</td>
<td headers="details" class="gt_row gt_left">—</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left">jersey_number</td>
<td headers="new_var" class="gt_row gt_left">jersey_number</td>
<td headers="details" class="gt_row gt_left">—</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left">height</td>
<td headers="new_var" class="gt_row gt_left">height</td>
<td headers="details" class="gt_row gt_left">—</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left">weight</td>
<td headers="new_var" class="gt_row gt_left">weight</td>
<td headers="details" class="gt_row gt_left">—</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left">years_of_experience</td>
<td headers="new_var" class="gt_row gt_left">years_of_experience</td>
<td headers="details" class="gt_row gt_left">—</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left" style="background-color: #FFA500; color: #000000;">team_abbr</td>
<td headers="new_var" class="gt_row gt_left" style="background-color: #FFA500; color: #000000;">latest_team</td>
<td headers="details" class="gt_row gt_left" style="background-color: #FFA500; color: #000000;">renamed as team_abbr doesn't make sense for retired players</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left" style="background-color: #FF0000; color: #FFFFFF;">team_seq</td>
<td headers="new_var" class="gt_row gt_left" style="background-color: #FF0000; color: #FFFFFF;">—</td>
<td headers="details" class="gt_row gt_left" style="background-color: #FF0000; color: #FFFFFF;">needless variable</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left" style="background-color: #FF0000; color: #FFFFFF;">current_team_id</td>
<td headers="new_var" class="gt_row gt_left" style="background-color: #FF0000; color: #FFFFFF;">—</td>
<td headers="details" class="gt_row gt_left" style="background-color: #FF0000; color: #FFFFFF;">needless; only used in ngs and nfl apis</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left">football_name</td>
<td headers="new_var" class="gt_row gt_left">football_name</td>
<td headers="details" class="gt_row gt_left">—</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left" style="background-color: #FF0000; color: #FFFFFF;">entry_year</td>
<td headers="new_var" class="gt_row gt_left" style="background-color: #FF0000; color: #FFFFFF;">—</td>
<td headers="details" class="gt_row gt_left" style="background-color: #FF0000; color: #FFFFFF;">no source and mostly same as rookie_year</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left" style="background-color: #FFA500; color: #000000;">rookie_year</td>
<td headers="new_var" class="gt_row gt_left" style="background-color: #FFA500; color: #000000;">rookie_season</td>
<td headers="details" class="gt_row gt_left" style="background-color: #FFA500; color: #000000;">renamed for consistency</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left" style="background-color: #FFA500; color: #000000;">draft_club</td>
<td headers="new_var" class="gt_row gt_left" style="background-color: #FFA500; color: #000000;">draft_team</td>
<td headers="details" class="gt_row gt_left" style="background-color: #FFA500; color: #000000;">renamed for consistency</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left" style="background-color: #FFA500; color: #000000;">draft_number</td>
<td headers="new_var" class="gt_row gt_left" style="background-color: #FFA500; color: #000000;">draft_pick</td>
<td headers="details" class="gt_row gt_left" style="background-color: #FFA500; color: #000000;">idk why this was called number</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left">college_conference</td>
<td headers="new_var" class="gt_row gt_left">college_conference</td>
<td headers="details" class="gt_row gt_left">—</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left" style="background-color: #FF0000; color: #FFFFFF;">status_description_abbr</td>
<td headers="new_var" class="gt_row gt_left" style="background-color: #FF0000; color: #FFFFFF;">—</td>
<td headers="details" class="gt_row gt_left" style="background-color: #FF0000; color: #FFFFFF;">needless; we have ngs_status and ngs_status_short_description</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left" style="background-color: #FFA500; color: #000000;">status_short_description</td>
<td headers="new_var" class="gt_row gt_left" style="background-color: #FFA500; color: #000000;">ngs_status_short_description</td>
<td headers="details" class="gt_row gt_left" style="background-color: #808080; color: #FFFFFF;">—</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left" style="background-color: #FFA500; color: #000000;">gsis_it_id</td>
<td headers="new_var" class="gt_row gt_left" style="background-color: #FFA500; color: #000000;">nfl_id</td>
<td headers="details" class="gt_row gt_left" style="background-color: #FFA500; color: #000000;">renamed as it is named nfl_id in Big Data Bowl</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left">short_name</td>
<td headers="new_var" class="gt_row gt_left">short_name</td>
<td headers="details" class="gt_row gt_left">—</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left">smart_id</td>
<td headers="new_var" class="gt_row gt_left">smart_id</td>
<td headers="details" class="gt_row gt_left">—</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left">headshot</td>
<td headers="new_var" class="gt_row gt_left">headshot</td>
<td headers="details" class="gt_row gt_left">—</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left">suffix</td>
<td headers="new_var" class="gt_row gt_left">suffix</td>
<td headers="details" class="gt_row gt_left">—</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left" style="background-color: #FF0000; color: #FFFFFF;">uniform_number</td>
<td headers="new_var" class="gt_row gt_left" style="background-color: #FF0000; color: #FFFFFF;">—</td>
<td headers="details" class="gt_row gt_left" style="background-color: #FF0000; color: #FFFFFF;">duplicate of jersey number from different source</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left">draft_round</td>
<td headers="new_var" class="gt_row gt_left">draft_round</td>
<td headers="details" class="gt_row gt_left">—</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">—</td>
<td headers="new_var" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">common_first_name</td>
<td headers="details" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">new variable</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">—</td>
<td headers="new_var" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">pfr_id</td>
<td headers="details" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">new variable</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">—</td>
<td headers="new_var" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">pff_id</td>
<td headers="details" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">new variable</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">—</td>
<td headers="new_var" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">otc_id</td>
<td headers="details" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">new variable</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">—</td>
<td headers="new_var" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">espn_id</td>
<td headers="details" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">new variable</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">—</td>
<td headers="new_var" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">last_season</td>
<td headers="details" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">new variable</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">—</td>
<td headers="new_var" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">pff_position</td>
<td headers="details" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">new variable</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">—</td>
<td headers="new_var" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">pff_status</td>
<td headers="details" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">new variable</td></tr>
    <tr><td headers="old_var" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">—</td>
<td headers="new_var" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">draft_year</td>
<td headers="details" class="gt_row gt_left" style="background-color: #0000FF; color: #FFFFFF;">new variable</td></tr>
  </tbody>
  &#10;  
</table>
</div>
