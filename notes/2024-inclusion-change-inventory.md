# Adding 2024: change inventory (2026-11-15)

A read-only survey of analysisHQ.Rmd and its utilities, CODEBOOK.xlsm, data/misc., the benchmark files, figuresHQ.ipynb, droppedFiguresHQ.ipynb, sensitivity_analyses/, manuscript.tex, supplementary_material.tex and the READMEs. Six parallel passes were made, and the main claims were spot-checked against the files. Nothing was modified. Line numbers are as of commit 9190910.

## Bottom line

- **Benchmarks:**
  - Turnout is already done. `VEP_including_ineligible_felons.xlsx` has 2024 (UF v0.4, felons added back), national and statewide, and `select(1:11)` already reads it.
  - State population is not needed. The file has 2024, but the State of Residence branch never runs because `create_targets` excludes `POST_STATE` (AHQ:1380). No State of Residence rows exist in any output.
- **Nothing else adapts to a new year by itself.** Years are wired in by hand in about 30 places in analysisHQ, plus about 15 in figuresHQ.
- **Downstream errors and tables pick up 2024 on their own** once `list_all_years` has a 2024 entry: party, candidate and demovote errors, national errors, metrics_base and most_specific.
- **Most failures are silent, not errors.** figuresHQ hard-codes 2008–2022 in Tables 8, 9 and S.3 and Figure 2, so 2024 would be dropped without warning. Figure 3 would include it, so the paper would be inconsistent.
- **Two places hard-fail:**
  - Table 4 has a fixed 11-column LaTeX spec.
  - Table S.2 raises a KeyError until the BLS rates are re-pulled.
- **The paper has about 45 hand-typed year and count references.** About 20 result-dependent claims also have to be re-checked after the rerun.
- **Five bugs already exist in the current data, unrelated to 2024.** Fix them first, because they change the 2006–2022 numbers (§2).

## 1. Decisions for JD (before coding)

1. **Restricted ANESRake variable set.**
   - Today it is the top 4 by mean rank across all years (AHQ:1677–1680): age, education, employment, income.
   - Adding 2024 changes the mean ranks. If the top 4 shift, the restricted weights and results change for every year.
   - Options: freeze the four as a constant, or recompute and report it.
2. **President 2024 classification.**
   - Secondary sources (Chooi 2026, the CES blog) say the 2024 post-stratification includes 2024 presidential vote. If so, President-2024 is Primary, as in 2020, and drops out of the secondary analyses.
   - This must be confirmed from the 2024 guide, which is on Dataverse only and was not reachable here.
   - The same guide reading fills the 19 rows for 2024 in `ces_weighting_stage_variables.csv`. It also settles whether Senate and governor stay in the state-level adjustment, and whether 2020 turnout is in the frame weights.
3. **Ranked-choice convention.**
   - The existing files use first-round counts (AK 2022, ME-2 2018).
   - 2024 has AK at-large, ME-2 and AK statewide races. Keep first round and say so in the text; the text says nothing about RCV now.
4. **Nebraska 2024 Senate.**
   - The current rule drops the concurrent special and keeps the regular race: Fischer (R) vs. Osborn (I), with no Democrat.
   - Check that the CES `CC24_411` is the regular race and `CC24_411b` the special. If `CC24_411` is the special, Fischer silently fuzzy-matches to Ricketts.
   - Decide how a race with no Democrat is described at party level.
5. **Maine and Vermont 2024 Senate (King, Sanders).**
   - Follow the 2012/2018 practice: benchmark against the Republican.
   - Add rows to both `candidate_benchmark_overrides` (AU:1444–1472) and `modal_exceptions` (AU:1073–1085).
   - The paper's "eight" major-party-nominee contests become ten (App A l.837, Supp 357/754/769).
6. **UF v0.4 rounded numerators.**
   - Seven states (AL, MS, MO, OK, PA, TN, TX) have rounded estimates of total ballots.
   - The 2006–2022 rule is "highest-office votes where total ballots not available." Replace them with 2024 presidential votes from your returns, or footnote them. UF has no v1.0 yet.
7. **Residence Duration in 2024.**
   - The 2024 file appears to have no `CC24_361`, only `CC24_361b`, which is coded differently. Confirm in the questionnaire.
   - If it's gone, 2024 has no Residence Duration. That is harmless for the always-present sets (the variable is already missing in 2006 and 2018), but note it.
8. **Layout for 10-year tables.**
   - Tables 8, 9 and 12 go to 13 columns and probably overflow at 12pt.
   - Table 4 is already at `\scriptsize` with squeezed spacing.
   - Options: smaller type, sidewaystable, two year panels, or moving Pooled/Δ to the notes.
9. **Refactor first?** Replacing the per-year blocks with one `YEARS <- seq(2006, 2024, 2)` would turn about 30 edits into one. The same applies to a single `YEARS` and derived "paired years" in figuresHQ. Recommended.
10. **Year macros.** Add generated `\NumYears`, `\FirstYear`, `\LastYear` and `\YearSpan` to prose_numbers.tex, so "nine years", "17-year period" and "2006 to 2022" stop being hand-typed.
11. **Fuller 2024 guide review.** Either do a full review for supplement section F (new items, evidence13+), or only check whether the existing items recur.

## 2. Bugs already in the data (independent of 2024)

**Status update (2026-11-15, late):** commits `de78291`, `e2a29ae` and `6b95e8d` fixed ME-2 2022, the `ST_HOUSE_*` skip keys and Senate fusion, plus President fusion and OH-11 2018 (see `pre-2024-data-bug-fixes.md`). `CES_Reported_Errors.xlsx` was being edited at the time. The defect catalog §5 lists the other pre-2024 defects still open.

| Bug | Where | Effect |
|---|---|---|
| ME-2 2022 House rows are corrupted. Golden's 1,165,136 looks like his final-round 165,136 with a stray leading digit, and Poliquin's 1,146,142 looks the same. Bond's 21,655 is her first-round count. A "BALLOT, EXHAUSTED" row of 322,778 is counted in the total. Re-pull the first round from the Maine SoS. | US_House_Returns_2006_2022.xlsx | Golden shows at 43.9%; his first-round share was about 48%. |
| 12 skip rows use `ST_HOUSE_PARTY_rc` / `ST_HOUSE_CANDIDATE_rc`. That variable doesn't exist; the code uses `ST_REP_*`. | skip_conditions_final.xlsx (NY 2006/08/12/14/16, CT 2008) | Intended fusion exclusions never apply. Those state-years are in most_specific now (verified). |
| Senate party table puts fusion lines (WF, C, IDP) in OTHER. House, Governor, President and state legislature fold them into the candidate's party. | AHQ:1011–1025 | Inconsistent party shares (the A1_fusion variant already probes this). |
| `CES_Reported_Errors.xlsx` race labels have trailing spaces ("U.S. Senate ", "Governor "). | Table 12 merge | Some guide RMSEs may not merge. |
| Supplement placeholder "(2016 guide, [p.~?])" at l.666. "Sections A–G" at manuscript l.851 (section H exists). Duplicated CPS fragment at Supp l.749. | tex | Fix before submission. |

## 3. Inputs to obtain

| Input | Status / what is needed |
|---|---|
| CES 2024 Common Content | DOI 10.7910/DVN/X11EP6. The validated release came out around Aug 2025. File `CCES24_Common_OUTPUT_vv_topost_final` (CSV confirmed; check for a .dta). N ≈ 60,000. If CSV only, replace `read_dta` and recode the CSV missing codes (`-1`, `""`, `__NA__`) to NA. Record the Dataverse version and download date. |
| CES 2024 Guide + questionnaire | Needed for: the stage CSV rows, Tables 2, 4, 5, S.5, S.6, S.9, section F, value labels, completion rate, field dates, matching pool, max weight, any guide-reported RMSEs (Table 12). |
| CPS 2024 | New IPUMS extract with the same 30 variables and all 12 months: `cps2024_01s, 02b, 03b, 04b, 05b, 06s, 07s, 08s, 09s, 10s, 11s, 12s`. Pull after IPUMS's 2026-07-13 HRHHID2 revision, which changed the Jan 2024–Jul 2025 files. Check the IPUMS version cited (bib v13.0; README says 12.0). |
| BLS CPS response rates | Re-download series LNU09300000 through 2024 (feeds Table S.2 and `\CpsRate*`). |
| Election returns (in progress) | Formats in §4. |

## 4. Election-return rows: format rules the 2024 rows must follow

- **All files:**
  - Real TRUE/FALSE in `special`, `concurrent_special` and `writein`. An NA in `concurrent_special` silently drops rows through the Senate filter.
  - `party_simplified` must be exactly `DEM`, `REP` or `OTHER`. `collapse_proportion_table` silently loses any other value; add a check.
- **President:**
  - District must be the literal `nationwide`.
  - Exactly one DEM and one REP row per state, with fusion lines pre-collapsed (NY).
  - Any new non-vote string (BLANK, VOID, SCATTERING…) must be added to `president_nonvote_rows`, or the check stops.
  - Watch for MA/NY "BLANK/SCATTERING" combined rows, like the 2008/2012 fix.
  - The MEDSL 2024 file has 9 states 0.6–1.4% above FEC, probably because of blank rows (see 2024-election-returns-sources.md).
- **Governor:**
  - `cand_num` is required for both major candidates (1 = DEM, 2 = REP; 3/4 for third parties the CES listed).
  - A major candidate with NA `cand_num` silently becomes OTHER.
  - Fusion is pre-collapsed.
  - 2024 states: DE, IN, MO, MT, NH, NC, ND, UT, VT, WA, WV.
- **Senate:**
  - FEC-style separate fusion lines are OK.
  - CA: both the regular and the special get `concurrent_special = TRUE`, and the special also gets `special = TRUE`.
  - NE: same rule for the Fischer–Osborn regular race and the Ricketts–Love special.
- **House:**
  - District is an integer, with 0 or 1 for at-large (never "AL").
  - Include the DC delegate row, or the party path stops.
  - Do not add the concurrent unexpired-term specials (TX-18, WI-8). They would merge into the district totals.
  - Same-party top-two races (CA, WA) are OK.
  - LA's November open primary interacts with the "leading candidate not offered" rule.
- **State legislature / AG / SoS (Ballotpedia file):**
  - Party must be exactly `Democrat` or `Republican`; anything else becomes Other.
  - The year is taken from `election_date` (2024-11-05).
  - The file is read with `guess_max = 20000`: a sparse column that first gets values in rows added at the end may be read as the wrong type.
  - AG: IN MO MT NC OR PA UT VT WA WV. SoS: MO MT NC OR VT WA WV.
- **File names encode year ranges.** They are referenced at AHQ:124–137, in object names used through AHQ:987–1306, in `build_flags.py` l.99–105 and 145–148, in `state_leg_uncontested/run.py`:27, and in data/README.md:46–50. Rename everywhere, or append 2024 under the old names.

## 5. analysisHQ.Rmd and utilities: edits

**Year vectors and per-year lines (manual unless refactored):**
- L49–60: add `CES_24_raw`.
- L255 and L352: CPS `target_years` / extract loop.
- L344: `cps_sample_2024`.
- L383–423: `CES_24_subset_vars` and `CES_24_raw_subset`.
- L469–502: citizenship map `"24" = "immstat"`.
- L509: CPS subset years.
- L544–557: `update_list_all_years()`.
- L577–583: `update_ces_rc_datasets()`.
- L592–600: `apply_codebook_and_recode(24)`.
- L625–644: age groups (CES `2024 - birthyr`, CPS).
- L656: CPS POST_STATE loop.
- L669–677: REGION.
- L680–688: `normalize_cd(CES_24_rc$cdid119_post)`.
- L696–748: factor, `cps_rc_datasets`, `clean_NAs` and `as.data.frame` lines.
- L1521, L1653, L1692: `run_weighting` / discrepancy year vectors.
- L1563–1571 and L1694–1702: `add_weights_to_df` lines.
- L1714–1723: `yearly_ces_wt_vars` `"2024" = commonpostweight`. Only element [1] is used.
- data_structures.R L1–39: `pre_post_location_vars` `"2024"` (required; otherwise `add_location_vars` errors).

**2024 subset list.** Don't copy 2022's list.
- Use `HouseCand1–5`, `SenCand1–3` plus `SenCand1/2Name2`/`Party2`, `GovCand1–3`, `AttCand1–3`, `SecCand1–3`.
- Use `cdid119` / `cdid119_post`.
- Include the vote items `CC24_401`, `403`, `410`, `411`, `411b`, `412`, `413`, `414a/b`, `415c/d` and the early-vote items `CC24_365_voted`, `365b_voted` (check against 2022 usage).
- Exclude the `_nv` items.
- `caseid` must be column 1 (AHQ:1470 and 1544 use it by position).

**Not needed for 2024:**
- 2018 straight-ticket fill: the 2024 file has no straight-ticket item.
- 2008 candidate file.

**CODEBOOK.xlsm sheet "24":**
- Duplicate sheet "22" in Excel and edit it there.
- The `Codes` and `New.labels` header cells are TEXTJOIN formulas, and readxl reads the cached values. A sheet written with openpyxl or pandas has no cached values, so the recode silently fails. If you do script it, use `keep_vba=True`.
- Keep the fixed column layout: CPS in A–F, CES in G–L.
- Add `PRES_CANDIDATE_rc` / `PRES_PARTY_rc` from `CC24_410`, using the 2020 rows 157–170 as the template. The labels are static strings and must exactly match the normalized returns names (e.g. "Kamala D. Harris"). Labels can't contain commas.
- Unlisted codes pass through as raw levels without error. Tabulate every 2024 mother variable against its code list.
- The set of `_rc` names defined on both the CPS and CES sides decides which variables 2024 is benchmarked and raked on.

**CES-side manual fixes.** After `clean_NAs`, look for 2024 slots with a candidate name but a blank party. Precedents are the 2022 Begich, 2020 Petsonk and 2014 OK fixes at AHQ:762–793.

**`clean_party_names` (AHQ:942–965).** Only an exact "Republican" counts as Republican. Tabulate the distinct 2024 party strings first.

**Redistricting (AL, GA, LA, NC, NY).**
- The 2024 file's `cdid118_post` and `cdid119_post` differ only in these five states. Use cdid119.
- Add a consistency check: the CES House candidate names should appear among the returns candidates for each (state, district).
- `filter_nc_if_needed` (AU:1320–1337) is hard-coded to 2020. Generalize it only if 2024 turns up a similar flag file.

## 6. Year-keyed tables to extend

| Table | 2024 content |
|---|---|
| `ces_weighting_stage_variables.csv` | 19 rows (from the guide). The pipeline errors if they are missing. |
| `skip_conditions_final.xlsx` | DC Senate. Legislatures with no 2024 general (verify: AL, LA, MD, MS, NJ, VA; MI and MN senates). NE unicameral. NY state senate fusion. AG/SoS not up or appointed, if the CES asked. Any CES questionnaire errors. Use `ST_REP_*`. |
| `mixed_in_special_election_candidates.xlsx` | Audit the 2024 Ballotpedia pull for mislabeled specials. The key has no state column, so watch for cross-state collisions. |
| `candidate_benchmark_overrides`, `modal_exceptions` | ME and VT Senate. Any other statewide race where Other is the top vote-getter. |
| `candidate_name_crosswalk` (AHQ:1140–1184) | Repeat the within-contest duplicate-name audit. |
| `CES_Reported_Errors.xlsx` | Any RMSEs the 2024 guide reports. |
| `sensitivity_analyses/build_flags.py` hand lists | Review list mismatch, nominee benchmark and CES manual fixes for 2024. |

## 7. Checks to add (because failures are silent)

- **Candidate path:** missing returns make the contest drop with no message (AU:529). Count 2024 contests by office and compare with the CES races.
- **Fuzzy matching** has no score threshold. Review 2024 `Match_Score > 0` rows (export at AHQ:1771). The paper's "4,185 contests / 2,874 exact / 1,309 by distance" (Supp l.343) changes, and the new distance matches need manual review.
- **`party_simplified` values** ∈ {DEM, REP, OTHER} before collapsing.
- **CES 2024 codes** vs codebook code lists, and party strings vs `clean_party_names`.
- **House district consistency** (§5).

## 8. figuresHQ.ipynb

**Silent exclusions.** Derive these from "all years minus `ASSUMED_SECONDARY_YEARS`":
- cell 31 (Table 8): `range(2008, 2023, 2)`, `between(2008, 2022)`
- cell 33 (Table 9)
- cell 35 (Figure 2)
- cell 56 (Table S.3 / Figure S.1)
- droppedFiguresHQ cells 11, 13, 15, 17, 55, 62, 64

Cells 31 and 35 are coupled: an assert requires their observation counts to match.

**Hard breaks:**
- Cell 19 (Table 4): `*{9}{c}`, `\multicolumn{11}` and `\cmidrule{1-11}`. Derive them from `len(years)`. Also hand-coded: `guide_only_patterns`, the "Presidential vote, current election" year list (2020 only) and `undocumented_stage_years` (add 2024 as appropriate).
- Cell 54 (Table S.2): needs the BLS 2024 rate and a 2024 entry in `cps_sample_sizes`.

**Hand-transcribed data:**
- Cell 21 (Table 5): 2024 N, completion rate (must end in `\%`), field dates, note clause.
- Cell 15 and cell 24: `presidential_years` / `[2008, 2012, 2016, 2020]`. Add 2024. droppedFiguresHQ has the same list at 7.76, 9.79 and 44.16.

**Assertions that may fail with 2024:**
- Cell 56: Governor and Senate must be Primary every year after 2012, age/education/sex Primary, union/veteran Secondary.
- droppedFiguresHQ 62.55–70: exact consistent-variable sets.

**Figure 3 (cell 41):**
- Ticks are `[2006…2022]`.
- `set_xlim(2005, 2026.5)`: slope labels at 2024.6 run into panel B. Widen to about 2029.
- `set_ylim(0, 11)` may clip.

**Figures S.2/S.3:** bin edges top out at 5,000 and an assert fires above that. The 2022 maximum was 4,045, so this is low risk.

**Captions and notes with "2006–2022" / "2008–2022":** cells 21, 31, 33, 45, 49, 54, 56, 62, 64. Cell 64 also needs the UF 2024 turnout URL and source.

**Automatic:** Tables 1, 6, 7, 11, 13, S.1 and Figures 4 and 5 gain the year automatically. Tables 6, 13 and S.1 gain a column (medium layout risk).

**Macros:**
- Almost all 101 macros in prose_numbers.tex and all 20 in sensitivity_numbers.tex will change. None has a year in its name.
- `\ThreeVarYears` becomes "10". `pn_word` writes 10 as a numeral, giving "seven of 10 years"; decide on that style.

## 9. sensitivity_analyses/

- **Rerun order:** analysisHQ → figuresHQ → `build_flags.py` → **delete the pickles in `~/ces_sens_scratch/_cache`** → `run_variants.py` (12 variants) → `compare.py` → `make_paper_outputs.py`. The pickles are reused without warning if they aren't deleted.
- **Assertions:** `make_paper_outputs.py` l.236–240 asserts the trend signs, that the p-values stay non-significant, and the Table 13 directions. These can fail after 2024 is added.
- **README is stale:** it says the folder isn't in the paper, and its regenerate command omits `make_paper_outputs.py`.

## 10. Paper

**Hand edits to year range and counts:**
- Abstract l.263: nine → ten years, 2006 to 2024, 17-year → 19-year.
- l.294, l.325 ("all available… 2006 and 2022" becomes false), l.346, Table 3 l.417, l.459, l.462, l.475, l.495, l.513, l.572, l.578, l.585, l.594, the l.596 alt text, l.707, l.774, l.777, l.781, l.787, l.795, l.807, l.823, l.837.
- Supplement: l.260, 262, 273, 322, 365, 388, 419–434, 483, 738 (2024 noncitizen count), 749, 754 (the list of 28 highest-office state-years and the "eight" count), 769, 773.

**Claims to re-verify against the rerun** (per the no-unsupported-claims rule):
- "accuracy did not improve" (l.263, 707)
- "considerably lower" (l.263)
- the sign of the post-stratification effect (l.263)
- "apparent in each year" (l.515, 521)
- "all but four variables" (l.521)
- "first three years better than later years" and "most in the last two years (2020 and 2022)" (l.517)
- the distribution and tail claims (l.574–580)
- "three primary / six secondary in every year" (l.585)
- every significance word next to trend p-values (l.587–589, 707; "marginally significant" p = .094 and .089 could flip)
- "larger samples, larger errors" (l.645, 715)
- the race-exclusion direction (l.657, 713)
- "RMSEs higher than the guides" (l.679)
- the whole year-by-year ANESRake paragraph and alt text (l.691, 696, 698)
- employment status (l.709)
- "one in 10 off by more than 15 points" (l.713)
- section H "conclusions unchanged" (l.721, Supp 771)
- the pool-size "four years… 18 to 36 percent" (l.723)
- "29 CES variables" (l.502)

**New content from the 2024 guide:**
- Table 2 (2024 external providers)
- Table 4 column
- Table 5 row
- Supp Table S.5 (frame source)
- Table S.6 (dispositions, pool, RR1, weight variable)
- Table S.9 (2024 variable-name column; already `resizebox`'d at 10 columns)
- section E prose for 2024
- section F: extend the item years and page cites, possible new items and screenshots
- section G: 2024 quirks and the RCV sentence
- check whether 2024 was English-only (App A l.789)

**Citations:**
- Add a CES 2024 dataset citation. No CES year is cited as a dataset now; consider adding all years.
- Update the MEDSL President (1976–2024) and the UF 2024 turnout v0.4 entries.
- Check the IPUMS version.
- Consider citing Chooi (2026, arXiv 2606.12889). It is a 2024 CES nonresponse-bias study and bears on the Meng paragraph (l.317) and the prior-evaluations discussion (l.323, 719).
- The AAPOR 2024 task force report is optional.

**Length:** the main text is about 6,450 words (intro to the end of the discussion). The year swaps are word-neutral; put the new 2024 description in the supplement.

**READMEs:**
- README.md l.12, 51, ~67, 168 (IPUMS 12.0 vs 13.0).
- data/README.md: 2024 CES filename row, return file names, the VAP description at l.60–61.

## 11. Suggested order

1. Fix the §2 bugs and rerun 2006–2022, so their effects on the current numbers are separated from 2024's.
2. Refactor the year vectors (decision 9).
3. Get the 2024 CES file and guide. Fill the stage CSV, CODEBOOK "24" and the subset list. Pull CPS 2024.
4. Add the 2024 returns using §4's rules. Extend the §6 tables. Run the §7 checks.
5. Run analysisHQ. Then fix figuresHQ (silent ranges, Table 4, captions, Figure 3 axis) and rerun it, then the sensitivity analyses.
6. Make the paper edits. Do the claim re-verification against the new macros last.

Open web-sourced facts still to confirm from the 2024 guide: the weight names (`commonpostweight` present per sample), President in post-stratification, the residence item, the `CC24_*` value labels, and the `CC24_411` vs `411b` assignment for NE and CA.
