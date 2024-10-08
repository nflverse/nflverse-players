# Contributing to nflverse.players

This outlines how to propose a change to **player IDs** maintained by 
nflverse.players.

## Scope

The players dataset maintained by this package aims to be the single source of 
truth when it comes to NFL player IDs across various sources (relevant to the 
nflverse). The following source IDs and information are considered in-scope for 
nflverse.players:

- Basic player information eg name, height, weight, age, date of birth, years experience, status, headshot image (mostly from GSIS)
- Draft information: draft year, draft round, draft pick, draft overall, draft team, college (mostly from PFR)
- Position information (mostly from PFF)
- Primary source IDs from:
  - NFL (gsis_id, gsis_it_id, smart_id) - gsis_id is the primary key
  - Pro Football Reference (pfr_id)
  - ProFootballFocus (pff_id)
  - OverTheCap (otc_id)
  - Elias Sports Bureau (esb_id)
  <!-- potential sources?
  - ESPN (espn_id)
  - SportRadar (sportradar_id)
  -->

Of note, the following sources are considered _not_ in the nflverse.players scope:
  - FantasyData
  - DraftKings
  - FanDuel
  - Sleeper
  - Fleaflicker
  - CBS
  - Yahoo
  - MyFantasyLeague

Many of these can be found in the [ffverse player universe](https://github.com/dynastyprocess/data). 

## Contribute Player ID Corrections or Additions


This data pipeline is fully automated via GitHub Actions. Since the workflows 
can't be perfect, there will always be mismatches or missing IDs - **this is
where we are looking for contributions**!

nflverse.players provides a mechanism to overwrite each ID with a manual correction 
without having to change or add code.

Manual corrections are located in the file `inst/players_manual_overwrite.json`.
**If you would like to contribute player ID corrections or additions, that file 
is what you have to edit!**

As of Monday, October 7th, 2024, the first 3 entries of that file look like this
```json
[
  {
    "gsis_id": "00-0039908",
    "pfr_id": "JenkKr01"
  },
  {
    "gsis_id": "00-0039856",
    "pfr_id": "JackKh00"
  },
  {
    "gsis_id": "00-0039437",
    "pfr_id": "JohnCo02"
  },
```

Our code will go through all gsis_ids (that's our primary key) and overwrite the 
associated other IDs - in this example the pfr_ids. The code won't care if the current 
ID is missing or wrong. It will overwrite regardless!

We store this file as JSON because it makes it easy to identify and review changes, and 
it nicely groups together related IDs for a specific player.

### Pull request (PR) process

*NOTE: The following bullets describe the workflow in R, but you can also do all
of this directly from the browser on the GitHub website*

- Fork the package and clone onto your computer. If you haven't done this before, 
we recommend using `usethis::create_from_github("nflverse/nflverse.players", fork = TRUE)`.

- Create a Git branch for your pull request (PR). 
We recommend using `usethis::pr_init("brief-description-of-change")`.

- Make your changes, commit to git, and then create a PR by running 
`usethis::pr_push()`, and following the prompts in your browser. The title of 
your PR should briefly describe the change.

Possible changes to this file could be either a new 3rd party ID to an already 
existing gsis_id, i.e. an addition of a line to an existing group, or a new entry 
for a previously unlisted gsis_id. **The file is sorted in descending order by 
gsis_id, so newer IDs are at the top!**

### Data Quality Checks

The quality of the data has top priority, which is why we use package tests to look 
for problems that may have been caused by your changes. Duplicated IDs are the 
biggest problem. There are two ways how your PR could introduce duplicated 
IDs:

1. The IDs you have added are already in the manual overwrite json file, so
the file itself contains duplicates.

2. The IDs you have added create duplicates in the full players dataset after
applying the manual overwrite - this means that you have added an ID that is 
already connected to another player.

Your pull request will trigger the tests - if they fail, we will help you resolve
the issues!

### Review Process

There is no way to automatically verify the IDs you have changed or added. 
So we need your help! Please help us verify the new ID as best you can by

- giving us a brief explanation of which player you are referring to,
- providing links to the related pfr, pff, or otc player websites.

## Code of Conduct

Please note that the nflverse.players project is released with a
[Contributor Code of Conduct](CODE_OF_CONDUCT.md). By contributing to this
project you agree to abide by its terms.
