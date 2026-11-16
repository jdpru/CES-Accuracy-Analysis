# Pre-2024 data bug fixes (Nov 15, 2026)

Bugs that change the 2006–2022 numbers. All are committed locally on main:
- de78291: fixes 1–3. Fix 2's skip file was first touched in fc514cf.
- e2a29ae: fix 4 and the skip-file dedup.
- 6b95e8d: fix 5.

These commits are NOT pushed: GitHub push is blocked from the Cowork sandbox, so JD needs to run `git push` from his own terminal. analysisHQ.Rmd and figuresHQ.ipynb need re-running.

**Rule for all offices:** a candidate's minor-party (fusion) lines count toward that candidate and their major party. Where each office applies it:
- House and Senate party tables: `calculate_state_level_party_proportions()`.
- State offices: `make_bp_prop_table()` (PrimaryParty).
- Governor: the returns file already combines lines.
- Candidate-level House, Senate, Governor and state offices: votes summed per candidate.
- President: `collapse_fusion_lines()` (fix 4).

## 1. Maine CD-2 2022 House rows (US_House_Returns_2006_2022.xlsx)
- Before: Poliquin 1,146,142, Golden 1,165,136, Bond 21,655, "BALLOT, EXHAUSTED" 322,778, write-in 393, total 2,656,104. Golden = 43.9%.
  - The Golden and Poliquin numbers were their round-2 counts (165,136; 146,142) with a stray leading "1". Bond and write-in were round-1 counts.
  - 322,778 is the report's TOTAL ballots line: 316,382 continuing + 1,020 overvotes + 5,376 undervotes. It is not an exhausted count.
- After: round-1 counts, matching how 2018 CD-2 is coded. Golden 153,074, Poliquin 141,260, Bond 21,655, write-in 393, total 316,382 (continuing ballots). Golden = 48.4%. Exhausted row deleted.
- Verified against the official tabulation (Maine Legislature LLDC, elec_20221108v.pdf).

### Independent verification of all Maine RCV-era races (Nov 15, verifier agent with maine.gov access)
- Checked: House 2018/2020/2022 both districts, Senate 2018/2020, President 2020.
  - Every candidate count matches the official SOS files.
  - No other race mixes round-1 and round-2 counts.
  - 2022 CD-2 confirmed against the SOS RCV report, including 322,778 = total ballots.
- Two stored totals include blank ballots: 2022 CD-1 (358,138 vs 349,176 in candidate votes; the difference is 8,962 blanks) and 2020 President (828,305, which includes 8,844 blanks).
  - No effect on results. Every House path recomputes totals from candidate votes (`recalculate_total_votes` statewide or district; the 2006 district path computes its own). `drop_president_nonvotes()` drops the BLANK VOTES row and recomputes the President total.
- 2018 Senate: the 64-vote row we label "RILEY, JAMES N., JR." is labeled "Others" in the SOS file. It is OTHER either way, so it has no effect.
- 2018 CD-1 and CD-2 have no write-in rows. Official files show no separate write-in count, and in CD-2 the four candidates sum exactly to continuing ballots.

### Why some House stored totals exceed candidate votes
After fix 5, 48 of 3,932 House races have a stored total above the sum of candidate votes.
- 44 are 2022.
  - The 2022 rows were hand-collected from state election sites: 99.6% of 2022 rows have a `source` URL, and no 2006–2020 row has one.
  - In states that report blanks, undervotes or spoiled ballots (NY, MA, HI, IA, ME, VT, WY), the collected "total" is total ballots cast rather than votes for candidates.
  - The gaps are 1–5% typically, and largest in lopsided or uncontested races: MA-4 28.6%, NY-13 17.5%, NY-9 14.1%.
- 4 are pre-2022 and tiny (≤0.6%), probably small write-in or scattering lines missing from the source (not verified): OH-11 2008 (185), RI-1 2008 (20), RI-2 2008 (31), NY-5 2018 (971; Meeks unopposed).
- No effect on results, because stored totals are never used (see above).
- No House rows are blank, over or under-vote rows posing as candidates. The only odd label is RI 2016 "None of the Above" (5 votes per district), a write-in name counted as OTHER.

## 2. Skip rows with a nonexistent variable (skip_conditions_final.xlsx)
- 12 rows used `ST_HOUSE_CANDIDATE_rc` / `ST_HOUSE_PARTY_rc`. The pipeline's variable is `ST_REP_*`, so they never matched. Rows: NY 2006, 2008, 2012, 2014, 2016; CT 2008. Renamed to `ST_REP_*`.
- Dedup: 5 State/Year/Race keys appeared twice with different Reason text, and both copies said Skip = TRUE. One row was deleted per key, keeping the reasons:
  - KS 2018 ST_SENATOR_PARTY: replaced "Special election" with the more informative "Election removed because all candidates for this race were mixed-in special election candidates".
  - MS 2018 ST_REP_PARTY; MS 2020 ST_REP_PARTY and ST_SENATOR_PARTY; MS 2022 ST_REP_PARTY: kept the original reason and appended "Also: all candidates for this race were mixed-in special election candidates." Each reason said something the other did not.
  - The file now has 872 rows and no duplicate keys.

## 3. Senate fusion lines counted as Other (analysisHQ.Rmd)
- Senate now uses `calculate_state_level_party_proportions()`, like the House. The Senate candidate-level table already summed lines per candidate.
- Benchmark Other share, old → new:
  - NY: 2006 12.9→2.0, 2010 14.6→1.5, 2016 12.0→2.2, 2018 9.5→0.1, 2022 10.7→0.5.
  - CT: 2010 4.3→1.6, 2012 7.6→2.1, 2016 7.7→2.2, 2018 3.9→1.1, 2022 1.8→0.0.
  - SC: 2014 8.9→7.0, 2016 5.1→2.5.
- Verified in R by running the Rmd's own Senate code on the real returns file:
  - All 304 state-years match an independent calculation (each candidate's votes summed across all their lines, assigned to DEM/REP if any line is DEM/REP).
  - Shares sum to 1.
  - The `calculate_party_errors()` lookup (Office == "US Senate", is.na(District)) finds exactly one row per state-year. The District column comes from house_prop_table's 2006 district rows.

## 4. President fusion lines (election_return_utilities.R)
- `assign_president_candidate_numbers()` only numbered DEM/REP lines, so NY's WF, Conservative and Independence lines fell into "Other Candidates" in both the party and candidate tables.
- New `collapse_fusion_lines()`, called at the top of `assign_president_candidate_numbers()`, merges each major-party candidate's lines into one row with summed votes. It stops if a candidate is on both DEM and REP lines. Both callers in analysisHQ.Rmd (party and candidate tables) pick it up.
- Tested in R: votes conserved, same row count, no duplicate cand_num, shares sum to 1. Only NY changes:
  - 2008: D 60.80→62.88, R 31.65→36.03, Other 7.56→1.09.
  - 2012: D 61.23→63.32, R 31.48→35.19, Other 7.28→1.48.

## 5. OH-11 2018 House rows copied from 2008 (US_House_Returns_2006_2022.xlsx)
- 2018 Fudge 212,485 and Goldstein 36,705 were the 2008 counts (Fudge vs. Pekarek). The stored total of 250,660 was already the 2018 figure.
- Corrected to Fudge 206,138 and Goldstein 44,486. With Bell's 36 write-ins, the rows sum to 250,660 (Ballotpedia; Ohio SOS totals). Fudge's share goes from 84.8% to 82.2%.
- Scanned all four federal returns files for vote counts repeated across years in the same state/district (≥1,000 votes). Only two other matches turned up:
  - TX-35, 5,236 in 2018 and 2020: a verified coincidence (Patterson 2018; Mata Sr. 2020).
  - NJ Senate, 3,544 in 2012 and 2014: minor candidates, not checked; OTHER either way.
