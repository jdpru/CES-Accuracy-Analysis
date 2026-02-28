# Code directory

R code for the CES Accuracy Analysis: loading data, recoding CES and CPS, computing weights, and comparing survey aggregates to election returns.

## Main script

| File | Role |
|------|------|
| **analysisHQ.Rmd** | Single entry point. Run from top to bottom to reproduce the full analysis. Sources all utilities, reads data from `../data/`, and writes summary tables to `../tables_and_figures/input_tables/`. |

**Run order:** Open the project via the root **CES Accuracy Analysis.Rproj**, then knit or run **analysisHQ.Rmd** in order. See the [main README](../README.md#getting-started) for data setup (CES data, IPUMS API key, etc.).

At the top of **analysisHQ.Rmd**, the setup chunk sets the knitr root directory. If you are not running from the opened .Rproj, set `knitr::opts_knit$set(root.dir = '/path/to/your/CES Accuracy Analysis')` to your project root so paths resolve correctly.

---

## Utilities (`utilities/`)

Helper scripts are sourced at the start of **analysisHQ.Rmd**. Paths are relative to the **project root**, not the `code/` folder.

| File | Purpose |
|------|---------|
| **recoding_utilities.R** | Codebook-driven recoding: `read.codebook()`, `apply_codebook_and_recode()`, `recode_the_vals()`, and helpers to align CES and CPS variables using **CODEBOOK.xlsm**. |
| **data_structures.R** | Year-specific variable names and structures: state/district variables by year, CES House/Senate/Governor candidate name variables, and other lookup lists used across recoding and accuracy steps. |
| **election_return_utilities.R** | Election-return processing: state-level party proportions, candidate-level proportions, and functions that shape and merge benchmark returns (President, Governor, Senate, House, state offices) for comparison with CES. |
| **accuracy_utilities.R** | Accuracy pipeline: `create_accuracy_config()`, extraction of comparison variables, skip logic, and RMSE/error calculations comparing CES (unweighted, CES weights, ANESRake full/restricted) to benchmarks. |

---

## Other files in `code/`

| File | Purpose |
|------|---------|
| **CODEBOOK.xlsm** | Excel workbook (with macros) that defines CES and CPS variable recodes by year. Used by **recoding_utilities.R**. Keep it in `code/` next to **analysisHQ.Rmd**; if you change recodes, edit the codebook and re-run the recoding chunks. |

---

## Outputs

**analysisHQ.Rmd** writes these tables to **`../tables_and_figures/input_tables/`**:

- `metrics_base.xlsx`
- `most_specific.xlsx`
- `national_errors.xlsx`
- `vars_used_by_anesrake.xlsx`

Those files are the inputs for **figuresHQ.ipynb** in `../tables_and_figures/`, which produces figures and tables in `../tables_and_figures/output/`.
