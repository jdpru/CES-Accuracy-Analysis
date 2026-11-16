# 2024 governor returns (built 2026-10-30)

File: `~/Downloads/Governor_Returns_2024.xlsx`. It is kept locally and is not in the repo: a copy added to `data/Benchmarks/Election Returns/` was removed at JD's request. Same 17 columns as `Governor_Returns_2006_2022.xlsx`. 11 races, 49 rows. Build script logic: candidate votes from official sources; `totalvotes` = sum of candidate + write-in votes (blanks, over/undervotes excluded, same as 2020 rows); `cand_num` 1 = DEM, 2 = REP, NaN otherwise.

| State | Source (official) | Total | Notes |
|---|---|---|---|
| DE | Dept. of Elections GE2024 report | 498,635 | No governor write-ins reported |
| IN | **Secondary** (Ballotpedia / Green Papers / Wikipedia citing IN ENR final) | 2,879,655 | IN ENR archive is JS-only, so the number couldn't be read off the official site. The Jan 9, 2025 legislative canvass, as reported in the press, has Braun 1,566,080 (−1) and Stried 59 (vs 52) |
| MO | SoS official returns (Board of State Canvassers, Dec 5, 2024) | 2,960,266 | Write-ins = Brown, 24 |
| MT | SoS state canvass | 602,404 | No governor write-ins reported |
| NH | SoS figures via NHPR ElectionStats (SoS page links to an Excel file I couldn't open) | 813,497 | Matches Wikipedia, which cites the SoS |
| NC | NCSBE ENR data feed (`er.ncsbe.gov/enr/20241105/data/results_0.txt`) | 5,591,547 | No write-ins |
| ND | SoS official results | 361,951 | Piepkorn's ballot label is Democratic-NPL; coded DEMOCRAT, as in 2020 |
| UT | Lt. Gov. statewide canvass | 1,477,457 | Lyman write-in 200,551 is a separate row (INDEPENDENT, writein = TRUE, OTHER). Tautuaa's 525 goes in Write-Ins. Invalid write-ins (4,464) excluded. IAP coded INDEPENDENT AMERICAN, UNA coded INDEPENDENT |
| VT | SoS canvassing committee report | 362,841 | Charlestin was DEM/PROG fusion; coded DEMOCRAT (same as Zuckerman 2020). Blanks 9,877 and overvotes 167 excluded |
| WA | SoS results (final Nov 26, 2024) | 3,861,388 | Coded by party preference |
| WV | SoS Clarity final + write-in PDF | 740,938 | 10 write-ins; their assignment to governor relies on Green Papers |

Open items:
- `cand_num` for third candidates: the 2006–2022 file sets 3/4 only when the CES listed that candidate. Not set for 2024 because CES 2024 isn't in the repo. Check whether CES 2024 listed Lyman (UT) or any third candidate.
- UT Lyman party coding: as a write-in he had no ballot label. Apply the "CES label" rule once the CES 2024 file is in hand.
