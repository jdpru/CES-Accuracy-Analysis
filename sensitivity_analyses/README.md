# Sensitivity analyses (exploratory, not in the paper)

Response to the coauthor's comment on the limitations paragraph (manuscript p. 36): do the Supplement C complications and the question format drive the results?
Nothing here changes `manuscript.tex`, `supplementary_material.tex`, `code/`, or `tables_and_figures/`. This folder is untracked.

## Files
| File | What it is |
|---|---|
| `build_flags.py` → `flagged_races.csv` | One row per race × flag, with the race's benchmark and CES-weighted error |
| `run_variants.py` | Reruns `figuresHQ.ipynb` unchanged (read-only, in a scratch dir) with the flagged races dropped from `most_specific` and `metrics_base` immediately after loading |
| `compare.py` → `results/*.csv`, `results/tables_text/` | Prose macros and changed exhibits, by variant |
| `results/<variant>/` | That variant's `prose_numbers.tex` and every LaTeX table the notebook writes |
| `explore_sensitivity.ipynb` | Browse results; quick RMSE explorer for any exclusion; fragility check |

Regenerate everything from this folder: `python3 build_flags.py && JOBS=2 python3 run_variants.py && python3 compare.py && python3 make_paper_outputs.py`. The last step writes Table S.H1 and `output/sensitivity_numbers.tex` for the paper.

`state_leg_uncontested/` holds the C3 check (exploratory; delete the folder to remove it).
The `base` variant reproduces the committed `prose_numbers.tex` exactly.

## Flags
Analysis 1 covers the Supplement C cases that are still in the analysis:
- **list_mismatch (4).** KS and IA Senate 2014, CT SoS 2022, HI-2 House 2006.
- **nominee_bench (8).** Contests benchmarked against the major-party nominee.
- **fusion (336).** A candidate's votes were summed over two or more ballot lines. Most are NY House, then CT and SC. The median race has 8 points of its vote on secondary lines.
- **special (10).** The only election for the office that year was a special. This covers SC 2014 state senate (a single-district special scored against statewide respondents, error −61) and the five 2006 Texas House districts redrawn after LULAC v. Perry.
- **hand_fixes (12).** The CES file or the returns were corrected by hand: 3 CES-side fixes and 9 notes in the returns.

Supplement C's manual party assignments for states that don't report party can't be reconstructed from the returns files, because they aren't marked. Fuzzy name matches were all manually verified, so they are not flagged.

Analysis 2 is question format:
- **named_only.** Drops every party-level estimate. This removes all state legislative items, AG/SoS 2006–16, Governor 2006–08, and House/Senate 2006.
- **named_statewide.** Same, but keeps state legislative, which has no named alternative.
- **generic_AG_SoS.** Drops only the AG/SoS items from 2006–16 whose response options were the generic "Democratic candidate / Republican candidate". I checked these in the .dta value labels. This is where a respondent can pick a candidate who does not exist, as in NC 2012.

## Results

| | base | A1 all (367) | A1 + >90% | named only | named statewide | generic AG/SoS |
|---|---|---|---|---|---|---|
| Neither, matching / weighted (Table 8) | 9.5 / 8.2 | 9.5 / 8.2 | 9.3 / 8.0 | 9.5 / 8.0 | 9.5 / 7.9 | 9.5 / 7.9 |
| Used, matching / weighted (Table 9) | 10.7 / 8.1 | 10.7 / 8.0 | 10.7 / 8.0 | 10.7 / 8.1 | 10.7 / 8.1 | 10.7 / 8.1 |
| Secondary trend, matching β (p) | .113 (.089) | .111 (.097) | .114 (.094) | −.030 (.699)* | .127 (.099) | .113 (.089) |
| Secondary trend, weighted β (p) | −.016 (.701) | −.017 (.677) | −.014 (.739) | .023 (.572)* | −.003 (.947) | −.016 (.701) |
| CES weights / anesrake, 4 unweighted vars (Table 13) | −1.1 / +0.3 | −1.2 / +0.3 | −1.2 / +0.3 | −0.4 / 0.0* | −1.5 / +0.1* | −1.1 / +0.3 |
| Gap from CES guides (Table 12) | 1.2 | 1.1 | 0.2 | 0.5 | 0.5 | 0.7 |
| AG / SoS RMSE, all races (Table 11) | 9.5 / 7.8 | 9.7 / 7.5 | 6.1 / 6.6 | — | — | 5.8 / 5.2 |

\* These variants change *which variables* enter the analysis, not just which races. The trend test and Table 13 use variables observed in every year:
- In named_only, 2006 has no candidate-choice estimates at all. State legislative and House drop out, so Table 13 is left with voting method alone.
- In named_statewide, House drops out of Table 13 because 2006 House is party-level. The state legislative rows are identical to base.

The rows of those two exhibits that remain are unchanged. Both variants also hit an assertion in cell 56, the supplementary Governor/Senate weighting table, because Governor 2008 is gone. Every other output was produced.

### Reading
1. **Supplement C cases don't drive the conclusions.** Dropping all 367 flagged races changes no headline number by more than 0.1. Fusion is the largest category, and dropping it changes almost nothing.
2. **Question format matters a great deal for AG and SoS, and not for the conclusions.** Removing the generic-label AG/SoS years cuts AG RMSE from 9.5 to 5.8 and SoS from 7.8 to 5.2. The headline means, trend tests, and Table 13 do not change. This is confounded with year: the named items are 2018–22 only.
3. **Two claims are sensitive and should be worded accordingly:**
   - Office-level AG/SoS (and state senate) RMSE.
   - The comparison with the CES guides (Table 12). The gap goes from 1.2 to 0.2–0.7.
4. **The upward matching-only trend for secondary variables (p = .089) depends on including party-level items.** With named items only, the slope is −0.03 (p = .70), but the variable set is different, so this is not a like-for-like test. The paper already calls this trend marginal. The weighted "no improvement" conclusion holds in every variant.
5. **Fragility (notebook §4b).** Dropping the 400 worst races cuts House RMSE from 9.4 to 7.2. AG falls from 9.5 to 6.2 after dropping just 100 races; those 100 are spread across all offices, so this does not mean 100 AG races. President, Senate, and Governor barely move. At office level, a small number of races accounts for much of the AG/SoS/state senate error.
