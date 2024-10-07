# Contributing to nflverse.players

This outlines how to propose a change to **player IDs** maintained by 
nflverse.players.

## Preface

The players dataset maintained by this package aims to be the single source of 
truth when it come to NFL player IDs across various sources (relevant to the 
nflverse). The package maintains

- basic player information along with NFL gsis_ids,
- player IDs from Pro Football Reference (pfr_ids),
- player IDs from Overthecap (otc_ids),
- player IDs from PFF (pff_ids), and
- player draft information from PFR.

Data acquisition is fully automated via Github actions. Since the workflows 
can't be perfect, there will always be mismatches or missing IDs. And this is
where we are looking for contributions!


## Contribute Player ID Corrections or Additions

As described above, IDs may be incorrect or missing altogether. nflverse.players
provides a mechanism to overwrite each ID with a manual correction without having
to change or add code.

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

Our code will go through all gsis_ids (that's our main key) and overwrite the 
associated other IDs - in this case pfr_ids. The code won't care if the current 
ID is missing or wrong. It will overwrite regardless!

Just in case you wonder about the format. There is a good reason why we save the 
file in this json format. It's great for easily tracking changes on Github and 
it nicely groups together related IDs.

### Pull request (PR) process

*NOTE: The follwing bullets describe the workflow in R, but you can also do all
of this directly from the browser on the GitHub website*

- Fork the package and clone onto your computer. If you haven't done this before, 
we recommend using `usethis::create_from_github("nflverse/nflverse.players", fork = TRUE)`.

- Create a Git branch for your pull request (PR). 
We recommend using `usethis::pr_init("brief-description-of-change")`.

- Make your changes, commit to git, and then create a PR by running 
`usethis::pr_push()`, and following the prompts in your browser. The title of 
your PR should briefly describe the change.

Possible changes to this file could be either a new 3rd party ID to an already 
existing gsis_id, i.e. an addition of a line to an existing group. Or a new entry 
for a previously unlisted gsis_id. **The file is sorted in descending order by 
gsis_id, so newer IDs are at the top!**

### Data sanity

The quality of the data has top priority. That's why we use package tests to look 
for problems that may have been caused by your changes. Replicated IDs are the 
biggest problem. There are two ways how your PR could introduce replicated 
IDs:

1.) The IDs you have added are already in the manual overwrite json file. 
The file itself then contains replicates.

2.) The IDs you have added create replicates in the full players dataset after
applying the manual overwrite. This means that you have added an ID that is 
already listed with another player.

Your pull request will trigger the tests. If they fail, we will help you resolve
the issues.

### Review process

There is no way to automatically verify the IDs you have changed or added. 
So we need your help! Please help us verify the new ID as best you can by

- giving us a brief explanation of which player you are referring to,
- providing links to the related pfr, pff, or otc player websites.

## Code of Conduct

Please note that the nflverse.players project is released with a
[Contributor Code of Conduct](CODE_OF_CONDUCT.md). By contributing to this
project you agree to abide by its terms.
