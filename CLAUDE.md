# CES Accuracy Analysis: notes for Claude

JD Pruett's paper on the accuracy of the Cooperative Election Study (CES), measured against election returns, CPS demographics, VEP turnout and state populations. It covers 2006–2022, unweighted, with the CES weights, and with custom ANESRake weights. Co-authors: Gabriel Li and Jon Krosnick. Target journal: POQ. **Current effort: adding 2024.**

## Pipeline

1. `code/analysisHQ.Rmd` (R, renv) does the recoding and error computation. It uses `code/utilities/*.R` and `code/CODEBOOK.xlsm`, and writes `tables_and_figures/input_tables/*.xlsx`.
2. `tables_and_figures/figuresHQ.ipynb` builds every exhibit and `output/prose_numbers.tex` (the in-text numbers, as macros). `output/` is gitignored and gets uploaded to Overleaf.
3. `sensitivity_analyses/` runs in this order: `build_flags.py`, then delete the `~/ces_sens_scratch/_cache` pickles, then `run_variants.py`, `compare.py`, `make_paper_outputs.py`. It writes `output/sensitivity_numbers.tex` (Supplement section H).
4. `manuscript.tex` and `supplementary_material.tex` are the paper.

## Notes: read the relevant one before starting a task

- `notes/2024-inclusion-change-inventory.md`: everything that must change in the code, notebooks and paper to add 2024, plus the open decisions.
- `notes/2024-defect-catalog.md`: every type of data defect seen in 2006–2022, with a mechanical check for each, JD's decision rules, the 2024 cases to expect, and the plan for the check agents. **Check agents must read this file.**
- `notes/2024-election-returns-sources.md`: where the 2024 returns come from, and known problems in each source.
- `notes/governor-2024-returns.md`: the 2024 governor file. It lives at `~/Downloads/Governor_Returns_2024.xlsx`, outside the repo.
- `notes/pre-2024-data-bug-fixes.md`: 2006–2022 fixes from Nov 15, 2026. The commits are on local main, and analysisHQ and figuresHQ need re-running.

These notes are copies of docs in JD's claude.ai Project "CES Accuracy Analysis". If you change one, tell JD, so the Project copy can be updated too.

## How JD wants work done

- **Paper prose:** delegate the drafting to a Sonnet subagent. JD finds Opus's writing weak.
- **No unsupported claims:** no qualitative or comparative claims in the paper ("larger", "a shift") without an analysis or test behind them. Report the numbers instead.
- **Headers:** never use a bolded first sentence as a header. Use a real header and a topic sentence.
- **Wording edits:** when applying JD's wording to the .tex files, push back on anything you disagree with, flag typos and grammar mistakes, and say when it's unclear which text an edit refers to.
- **Git:**
  - Commit only when asked.
  - Work on main and merge directly. No PRs.
  - No Claude or Claude Code attribution lines in commit messages.
  - Stage with `git add -A`.
  - zsh mangles heredoc commit messages, so pass the message with several `-m` flags.
- **Before editing a data file:** as earlier sessions have done, make a backup in `_backup_<date>/` next to it and report the cell-level diff.
- **Editing .xlsx files:**
  - `CODEBOOK.xlsm` uses TEXTJOIN formulas whose cached values readxl reads. Edit it in Excel, or use openpyxl with `keep_vba=True` and then recalculate.
  - For small label fixes in benchmark .xlsx files, editing the sharedStrings XML inside the zip preserves formulas and formatting.
  - New rows in `skip_conditions_final.xlsx` need both CANDIDATE and PARTY rows, the standard reason wording, and the sheet's highlighting.

## Adding 2024: where things stand (Nov 15, 2026)

- **Done:** 2024 turnout (UF v0.4, with felons added back) is in `data/Benchmarks/VEP_including_ineligible_felons.xlsx`. 2024 state population is in its file but is not used anywhere. The 2024 governor returns are built.
- **Still needed:**
  - the 2024 CES file, guide and questionnaire (Dataverse doi:10.7910/DVN/X11EP6);
  - the remaining 2024 returns, in the formats described in inventory §4;
  - a 2024 CPS IPUMS extract.
- **Next step:** when JD supplies the raw 2024 data, run the check plan in `notes/2024-defect-catalog.md` §4. Phase 0 checks the lookup keys; phase 1 runs about 8 parallel agents; phase 2 has independent agents verify the hits; phase 3 produces a single decisions list for JD.
  - Agents are read-only on the repo and write their results to a scratch folder.
  - Every hit uses the catalog's row format.
- **Before the code edits:** consider refactoring the per-year blocks in analysisHQ and figuresHQ into one years vector (inventory decision 9).
