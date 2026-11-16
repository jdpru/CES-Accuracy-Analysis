# 2024 election returns: sources and feasibility check (2026-11-15)

## What exists
| Office | Best source | Notes |
|---|---|---|
| President | FEC "2024 Official Presidential General Election Results" (`fec.gov/documents/5645/2024presgeresults.xlsx`); MEDSL U.S. President 1976–2024 (Dataverse doi:10.7910/DVN/42MVDX, V10.1, file id 13887042) | Existing `President_Returns_2008_2020.xlsx` uses the MEDSL schema |
| U.S. Senate | MEDSL "U.S. Senate statewide 1976–2024", Dataverse doi:10.7910/DVN/PEJ5QU, V8 (released 2026-05-11, file id 13887039) | Existing Senate file uses the MEDSL schema. FEC *Federal Elections* compilation stops at 2022 (no 2024 Senate/House yet) |
| U.S. House | MEDSL "U.S. House 1976–2024", Dataverse doi:10.7910/DVN/IG0UN2, V15 (file id 13592823) | Download requires a guestbook response (guestbookID 458: name/email). Existing House file uses the MEDSL schema (+ cand_num, notes, concurrent_special) |
| Governor | Built from official sources 2026-10-30 (see governor-2024-returns.md) | |
| AG (10 states: IN MO MT NC OR PA UT VT WA WV), SoS (7: MO MT NC OR VT WA WV) | Official SoS canvasses, same method as governor | MEDSL precinct files have all 17 races, usable as cross-check |
| State legislature | Ballotpedia (source of the 2006–2023 file) or MEDSL 2024 precinct files | Ballotpedia: 5,807 seats in 85 chambers, 44 states |

GitHub `MEDSL/2024-elections-official` `2024-president-state.csv` / `2024-senate-state.csv` are not final: 41 president and 6 Senate rows flagged `unofficial`, and the Senate file has 33 states with no specials. Use the Dataverse versions.

## Dataverse files checked (2026-11-15, via Composio sandbox)
- Senate V8, 2024: 148 rows, 33 states + CA and NE specials. 10 rows still flagged `unofficial` (AZ 3, CA 2, NE 2, WA 3); CA and NE rows carry the older version stamp 20241212.
- President V10.1, 2024: 535 rows, 51 states, version 2025-11-20. Candidate-vote sums vs FEC TOTAL VOTES: 36 of 51 exact. MEDSL higher by 0.6–1.4% in DC, HI, ID, MA, ME, NH, NY, VT, WY (likely blank/void rows kept as candidates — check against the president-denominator rule); PA −0.35%; AZ, MT, RI, DE, WV within 0.06%.

## Access from this setup
- Device shell (JD's Mac) and the cloud workspace go through egress allowlists: GitHub and package registries reachable; Dataverse, fec.gov, state SoS sites, and backend.composio.dev refused. WebFetch is refused by Dataverse's robots.txt.
- Composio's remote sandbox has open egress: Dataverse API, FEC, CO/NM/WA SoS sites all reachable (Ballotpedia returns 202 bot check to curl). Some Composio command payloads are rejected with a 403 by a firewall in between; short single-purpose commands go through.
- Exa (via Composio, `EXA_GET_CONTENTS_ACTION`) reads Ballotpedia pages ($0.001/page).
- Moving files from the Composio sandbox to the Mac fails: its download links are on backend.composio.dev, which neither shell can reach. Fix: allow that host (and dataverse.harvard.edu, fec.gov) in claude.ai Settings > Capabilities, or open the link in a browser.
- (Note added for Claude Code: these limits applied to the claude.ai sandbox. Claude Code running on JD's Mac has the Mac's normal network access.)

## MEDSL 2024 precinct files: test aggregation
Aggregated all 51 state files to candidate × district for the 8 offices (keep TOTAL mode where a precinct-contest has it, else sum modes; meta rows such as UNDERVOTES excluded). Scripts and output were in the device-VM scratch dir `~/medsl24/` (not in the repo, not on the Mac).

Governor totals vs the official totals in governor-2024-returns.md:
- Exact: DE, MO, NH, VT. Within 0.04%: MT, NC, UT, WV. WA −0.17%.
- IN +4.0%: duplicated precincts (e.g. Hendricks "1229-Washington 29" appears twice with different counts).
- ND −14.5%: Burleigh and Divide counties have no governor rows (office labeled "GOVERNOR AND LIEUTENANT GOVERNOR").

President precinct sums vs MEDSL state totals: ~30 states exact; ~15 within 0.1–2.1% (typically votes not allocated to precincts: ME, NJ, NM, ID, MA, HI, VT, NY, DC...); LA −48%, IN +5.2%, IL +1.0%.

State-legislative coverage problems:
- WA: offices not standardized ("LEGISLATIVE DISTRICT 7 - STATE REPRESENTATIVE POS. 2"); parseable.
- NY: ~9,100 state-leg rows with blank district (141/150 Assembly, 60/63 Senate districts identifiable).
- AZ: Pima County State House rows have no district (documented by MEDSL).
- NM: 25 of 70 House districts, State House rows in 7 of 33 counties. Ballotpedia's 2024 NM House page shows many single-candidate districts, so part of the gap may be unopposed races the files omit; not yet verified.
- Unopposed candidates not printed on the ballot (e.g. FL) are absent; the Ballotpedia file keeps them with votes = NA.

## Conclusion
MEDSL precinct data is not benchmark-grade as is for 2024. Federal offices: use MEDSL constituency files from Dataverse (+ FEC for president). AG/SoS: official canvasses. State legislature: Ballotpedia for consistency with 2006–2022; otherwise MEDSL with state-by-state repair and validation.
