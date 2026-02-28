# Data directory

This folder holds all inputs for the CES Accuracy Analysis. Most large or external datasets are not in the repo; see below for where to get them and how they are used.

## Directory layout

| Directory | Purpose |
|-----------|---------|
| **CES Data/** | CES common-content microdata (Stata `.dta`) by year. **Not in repo**—must be downloaded. |
| **Benchmarks/** | Election returns and demographic/turnout benchmarks used to evaluate CES accuracy. |
| **misc./** | Auxiliary files: recoding helpers, exclusion lists, and one-off CES files. |
| **IPUMS CPS Artifacts/** | CPS extract metadata and downloads from the IPUMS API. **Not in repo**—created when you run the IPUMS chunk in `analysisHQ.Rmd`. |

---

## CES Data/

Cooperative Election Study common-content files, one per year. Required for the main analysis.

**You must download these yourself.** See the [main README](../README.md#download-ces-data) for links (CES Dataverse and Tufts). Place each file in `data/CES Data/`. Filenames must match what is loaded in the **CES Datasets** chunk of `code/analysisHQ.Rmd`:

| Year | Expected filename |
|------|--------------------|
| 2006 | `cces_2006_common.dta` |
| 2008 | `cces_2008_common.dta` |
| 2010 | `cces_2010_common_validated.dta` |
| 2012 | `commoncontent2012.dta` |
| 2014 | `CCES14_Common_Content_Validated.dta` |
| 2016 | `CCES16_Common_OUTPUT_Feb2018_VV.dta` |
| 2018 | `cces18_common_vv.dta` |
| 2020 | `CES20_Common_OUTPUT_vv.dta` |
| 2022 | `CES_2022_Common_Output.dta` |

CES sometimes releases updated versions; if filenames change, update the paths in `analysisHQ.Rmd` to match.

---

## Benchmarks/

Reference data used to compute election accuracy (e.g., vote shares, turnout).

### Benchmarks/Election Returns/

| File | Description |
|------|-------------|
| `President_Returns_2008_2020.xlsx` | Presidential election returns by state |
| `Governor_Returns_2006_2022.xlsx` | Gubernatorial returns |
| `US_Senate_Returns_2006_2022.xlsx` | U.S. Senate returns |
| `US_House_Returns_2006_2022.xlsx` | U.S. House returns |
| `State_Legislative_and_Constitutional_Offices_2006_2023.xlsx` | State legislative and constitutional office returns |

Loaded in `analysisHQ.Rmd` from `data/Benchmarks/Election Returns/` (and `data/benchmarks/Election Returns/` for the state legislative file—path case may vary).

### Other files in Benchmarks/

| File | Description |
|------|-------------|
| `VAP_Turnout_Rates.xlsx` | VAP turnout rates (national and statewide). Sheets: `"National"` and state-level. |
| `Historical_State_Population_by_Year.xlsx` | State population by year for benchmarking. |

Sources: Ballotpedia and other providers (see [Acknowledgments](../README.md#acknowledgments) in the main README).

---

## misc./

Auxiliary inputs used for recoding, filtering, or special cases.

| File | Used for |
|------|----------|
| `skip_conditions_final.xlsx` | Skip-logic / recoding rules (read in `analysisHQ.Rmd`) |
| `mixed_in_special_election_candidates.xlsx` | Candidates to drop from benchmarks when they appear in regular-election context |
| `NC_responents_incorrect_CD.csv` | North Carolina respondents with incorrect CD (exclusion/flagging) |
| `2008 CCES Election File (House and Senate).csv` | 2008 CES election file used in the pipeline |

Other files in `misc./` (e.g. `CES_Reported_Errors.xlsx`) may be for reference or side analyses and are not necessarily read by `analysisHQ.Rmd`.

---

## IPUMS CPS Artifacts/

Used by the **ipumsr** R package when pulling Current Population Survey data via the IPUMS API. The **CPS Data** chunk in `analysisHQ.Rmd` defines extracts, submits them, and downloads results into `data/IPUMS CPS Artifacts/`. You need a free [IPUMS API key](https://developer.ipums.org/docs/v2/get-started/) stored as `USER_IPUMS_API_KEY` in the Rmd. Alternatively, you can download CPS data manually from [IPUMS CPS](https://cps.ipums.org/cps-action/variables/group) and place or point the code to the right location.

Contents of this folder (e.g. `.xml`, `.dat.gz`) are gitignored; only the directory structure is kept in the repo.
