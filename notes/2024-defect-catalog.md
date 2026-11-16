# 2024 data-defect catalog and check plan (2026-11-15)

This is the catalog of every type of data defect found in 2006–2022. Each entry has the check the 2024 check-swarm should run, and the rules already set for resolving hits. It was built from:
- the project audit docs (fuzzy-match-audit, party-coding-check, us-house-district-coverage-check, house-district-join-fix-plan, unopposed-statewide-benchmarks-check, straight-ticket-skip-check, mrp-race-exclusion-edge-cases, president-denominator-fix, limitations-sensitivity-uncontested-races, ces-guide-documentation-problems, ces-memo-coverage, governor-2024-returns, 2024-election-returns-sources);
- supplementary_material.tex sections C, E, F, G and H, and manuscript Appendix A;
- the repo's own defect records: skip_conditions_final.xlsx, the special-removal list, build_flags.py, hand fixes in analysisHQ and the utilities, the returns `notes` columns, CODEBOOK notes and git history;
- past project chats.

It is read-only. Spot checks against the files are marked "verified". Repo state: HEAD `de78291`, plus uncommitted edits to `election_return_utilities.R` (`collapse_fusion_lines`) and `skip_conditions_final.xlsx`.

## 0. Constraints the swarm must work within

- **Subagents cannot read Project docs.** No Projects tool is available to them. Paste this catalog, and any other doc they need, into their prompts, or put copies in the repo.
- **The repo is being edited concurrently.** The swarm is read-only and writes only scratch output outside the repo, or to a folder JD names.
- **No R on the device VM or in the cloud container.** Checks are written in Python (pandas, pyreadstat). They reproduce the pipeline's rules rather than running it.
- **Each device_bash call is capped at 180 s.** Write scripts to scratch and run them in steps. Big .dta reads should read only the needed columns (`usecols`).
- **Every hit goes into one schema.** One row per hit: `check_id, year, state, office, district, candidate(s), evidence (values + file:row), severity (blocker / decision / fyi), rule_applied or decision_needed, proposed_action`. One CSV per check, then one merged decisions list.

## 1. Decision rules already set (apply these, do not re-ask)

**Respondent filters**

1. Drop self-reported noncitizens (the immigration item code meaning noncitizen). Keep respondents who skipped the item.
2. "Don't know", "not sure", "did not vote in this race", skipped and not-asked answers are missing, item by item. "Other" stays in the denominator. Vote choice has no turnout filter.
3. **Post-election wave only.** Pre-election early-vote reports (SENATOREARLY and similar) are never used. Concurrent second-race items (SENATOR2) are dropped.
4. Geography is the post-election state and post-election CD. A respondent with no post-election CD is out of House estimates.
5. The weight is the post-election common weight (`commonpostweight` analogue) for every item.

**Benchmark construction**

6. The benchmark is the top vote-getter at the candidate level where the item names candidates. Otherwise it is the party level, using the modal category.
7. Denominators are candidate votes, including write-ins and scattering. They never include blank, under-, over-, void or exhausted votes. Nevada's "None of these candidates" counts as a vote.
8. **Nominee override.** If the winner is an independent or write-in, or the leading candidate was not offered in the CES item, benchmark the second-place major-party nominee. This needs a `candidate_benchmark_overrides` row and a matching `modal_exceptions` row. PI rule: this is acceptable as long as the benchmark candidate is matched to the right CES option.
9. **Fusion.** Sum a candidate's votes across all ballot lines (including lines where the name is formatted differently) into the major-party line.
10. **Ambiguous major-party labels at party level.** Exclude the contest if candidates whose label names a major party without being simply that party ("Independent-GOP", D+R cross-filed) could change the compared party or move its share by ≥1 pt. Labels that name no party (AK "Nonpartisan") count as unaffiliated (Other).
11. Code each benchmark candidate with the party label the CES showed. Confirm it against the official returns. Fix `party_simplified`; leave `party_detailed`.
12. **Specials.**
    - If a special was the only election for a statewide office, use it.
    - If a same-day special and regular race were held for the same office, drop the special.
    - A state legislative chamber with no regular election that year is excluded, even if one or a few districts held specials.
13. **RCV.** Use first-round counts (AK, ME).
14. **Keep flawed but real contests and disclose them.** This covers uncontested races, same-party races, jungle races, and generic party options chosen where the party had no candidate (NC AG 2012). Contests that are artifacts of a CES or returns error go in the skip file. Every skip uses the skip-file format: CANDIDATE and PARTY rows, the standard reason wording, and the sheet's highlighting.
15. **Wrong names in the CES list.**
    - If respondents probably saw wrong names and mostly chose "other", exclude the contest (AK Gov 2014).
    - If the list adds an off-ballot extra candidate, keep those respondents in the denominator like "other" (KS and IA Senate 2014, CT SoS 2022).
    - In party-only items, count a wrong same-party name as that party (HI-2 2006).
16. **Wrong party shown on a CES candidate:** exclude the contest on both sides (FL-23 2014).
17. **CES-flagged wrong CD:** drop the flagged respondents from House only (NC 2020).
18. **Straight-ticket routing:** fill each race with the ticket party's slot. Leave it missing when the party has no candidate or the ticket was "another party". There is no straight-ticket item in 2024 (per the 2024 column list; confirm).
19. **Name matching.** Exact, case-insensitive match first. Otherwise Jaro (stringdist jw, p=0) with no threshold. For D/R benchmarks outside president, match only within the same party. A party-mismatch guard stops the run. Every distance match is reviewed by hand.
20. **Guide ambiguity.**
    - Where a list and its function disagree, take the union.
    - Where two sentences conflict, take the first.
    - Mark an undocumented step as unknown.
    - Report a figure that appears carried forward only for the first year it appears.
    - Describe what the guide prints.
21. DC is included everywhere. Fix label mismatches in JD's own benchmark files at the source.

## 2. Defect catalog

**Guard** says whether the existing pipeline catches the defect. LOUD means it stops. SILENT means it passes through or the row drops without notice. NONE means there is no guard.

### A. CES guide, codebook and questionnaire vs. the data file

**A1. Guide statistics copied from an earlier year.**
- Past: the 2014 V103 codebook entry is the 2012 entry (N 54,535, max 20.00044, though the 2014 N is 56,200 and the cap is 15).
- Check: for every 2024 weight, compute N, mean, SD, min and max from the file. Compare them with the 2024 guide entry, and that entry with the 2022 guide's.
- Hit: the guide equals 2022 to 5 significant figures, the guide differs from the file, the guide's max exceeds the stated cap, or the guide's N is not the stated sample size.
- Guard: NONE.

**A2. Methods text carried forward unrevised.**
- Past: the 2012 section is word for word 2010's (it says trim at 7, but the max is 20). "≈87,389" appears as the pool in 2014, 2016 and 2018. The 2016 second frame repeats the 2014 text, and the 2016 matching list repeats the 2014 list ("Pid5b from July 2012"). The "two frames" sentence appears in 2018 and 2020 with no second frame described. The "over 150,000" pool appears 2006–2016.
- Check: diff the 2024 sampling and weighting section sentence by sentence against the 2022 and 2020 guides. Extract every number and source year (pool, trim cap, ACS/CPS year, dispositions, RR1).
- Hit: an identical sentence containing a year-specific fact, an identical number, a source older than expected that the guide doesn't explain, or a stated cap below the observed max weight.

**A3. Guide lists disagree with each other.**
- Past:
  - 2014 and 2016: the matching list doesn't match the distance function (Newsint vs. registration).
  - 2018–2022: Hispanic origin and turnout are among the frame distributions but not the moment conditions.
  - "Completed" vs. "matched" cases.
- Check: build a variable × stage matrix from the 2024 guide. Stages: target strata, invitation cells, matching list, distance terms, frame-distribution sentence, moment conditions, raking/post-stratification list with a target source, statewide-race offices.
- Hit: a variable in one paired list but not the other.
- Output: draft 2024 rows (19 variables) for `ces_weighting_stage_variables.csv`, with notes.

**A4. Step undocumented.**
- Past: interactions unspecified (2014–22); statewide-race offices unnamed (2014, 2016; Gov+Senate confirmed by email); no source for born-again or presidential targets (2018–22); target strata missing (2018–22); 2022 modeled frame not described; post and validated-voter weight construction not described; quality controls, incentives and field-date precision missing.
- Check: run the checklist against the 2024 guide. Hit: any item missing.

**A5. Implausible procedure or timing.**
- Past: the distance function uses "took both waves" (a post-election variable) for pre-election matching (2014, 2016). Frames cite November CPS data released after the release date (2018, 2020). "Euclidean" is used for an L1 sum.
- Check: compare each cited source's release date with the field and sampling dates. Check that each formula matches its label.

**A6. Sample size or dispositions inconsistent.**
- Past: 2020 and 2022 completes are below the matching pool (YouGov-only base, unstated). The 2008 completes are below the matching pool. The 2012 file has no post-completion flag.
- Check: from the file, N total, N with tookpost, and N non-missing for each weight. Compare with the guide's N, pool, dispositions, RR1 and post completes.
- Hit: any mismatch, or an RR1 that doesn't recompute.

**A7. Variable documented but absent, or present but undocumented.**
- Past:
  - 2006 `ccesmodule` not released.
  - 1,394 respondents in 2006 have no v4004 value (excluded from 2006 turnout).
  - The 2008 candidate names came as a separate file.
  - CT SoS 2022 has no `_post` name set.
- Check: needed-variable list (the 2022 subset at AHQ:413 mapped to CC24_ names, plus weights, citizenship, inputstate(_post), cdid119(_post), every *Cand*Name/Party pre and post) against the guide's variable list and the file's variable list.
- Report needed∖file, guide∖file and file∖guide, plus missing rates among tookpost=1.
- Hit: anything absent, or a missing rate ≥5% beyond the skip logic.
- 2024 note: Residence Duration is probably absent (`CC24_361b` only).

**A8. Variable names change, or the guide names the wrong variable.**
- Past: the item numbers move every year. The 2016 guide gives the wrong Senate variable (CES confirmed CC16_410b). gender → gender4 (2022). faminc → faminc_new. The cdid name varies by year. The 2014 codebook says "November 6" while the .dta labels say November 4.
- Check: find each 2024 variable by matching the 2022 *label text*, not the name. Confirm against the questionnaire item ID and wording, and confirm it's the post-wave version.
- Hit: no match, more than one match, or a guide instruction naming a variable whose label is a different question.

**A9. Value-code drift and label errors.**
- Past:
  - Non-sequential codes that differ by year (CC18_412: 7=Other, 10–12=Cand5–7; CC22_412: 1–8 candidates, 10=Other).
  - The own/rent order flips in 2018.
  - President slot order is REP=1 in 2008 and 2016.
  - 2010 Senate codebook code 3 points to V556_post (a party) instead of V554_post (the name).
  - 2008 President codes 3–6 are permuted relative to the .dta.
  - Codebook notes record assumptions ("all AttCand1 are Dem") without checking them.
  - The recode never checks the file's value labels; unlisted codes pass through as raw levels.
- Check: for every needed variable, dump the .dta labels and the observed frequencies. Compare with the questionnaire options and the draft CODEBOOK "24" sheet. For each state, check that the slot-N name variable is non-empty wherever code N is chosen, and that slot party order matches what the codebook assumes. Verify the presidential slot order from the labels and PresCand party variables.
- Hit: an unlabeled observed code, a moved Other or not-sure code, a label that doesn't match its slot, or a code chosen whose slot is empty.
- Guard: LOUD only if a code maps to a missing column; a mis-mapped slot is SILENT.

**A10. Weight properties vs. documentation.**
- Past: max weights differ from the stated caps (2012: 20 vs. 7). Several weights in a file are undocumented.
- Check: list every weight. Identify the post-election common weight. Check max ≤ cap, mean ≈ 1, and that it is non-missing exactly for tookpost.

### B. CES candidate lists and questionnaire display

**B1. Another state's candidates displayed.**
- Past: ND SoS 2022 shows Ohio's names (skipped, but not described in the paper; verified). KY was shown KS's AG and SoS in 2018, and KS respondents saw nothing.
- Check: match each state-office's CES name set against that state's 2024 returns and against every other state's.
- Hit: a name found only in another state, responses where the office isn't up, or no responses or blank names where it is up.
- Guard: NONE.

**B2. Names in the file are wrong (primary losers or the wrong person).**
- Past: AK Gov 2014 (Mallott and Heikes; excluded); HI-2 2006 Hanabusa; CT SoS 2022 "Harold Harris (R)".
- Check: list CES names with no returns match after normalization (case, suffix, middle initial, quotes, nickname). Compare the pre and post name sets, and the guide or questionnaire list with the file. Compute the weighted "other/third option" share minus the official minor share.
- Hit: an unmatched name, a gap above 5 pts, or "other" as the modal answer.
- Decision: apply rule 15 (AK-type, CT/KS-type or 2006-type). Ask the CES what was displayed.

**B3. Extra candidates not on the ballot.**
- Past: KS 2014 Barnhart (9 respondents) and IA 2014 Williams (8); kept per rule 15. In 2024, candidates who withdrew may still be listed (RFK Jr. in some states' presidential lists).
- Check: CES names minus returns candidates for each contest.
- Hit: any such name. Report how many respondents chose it.

**B4. Leading or second candidate not offered.**
- Past: LA Sen 2016 (Kennedy not offered; overridden to Campbell). 19 House units had no runner-up offered; the PI rule says no change is needed.
- Check: returns candidates with ≥5% minus the CES names.
- Hit: the winner is missing (blocker: needs an override decision), or the runner-up is missing (fyi).

**B5. Name present but party blank, or a slot blank for some respondents.**
- Past: AK-1 2022 Begich; WV AG 2020 Petsonk; OK Gov 2014 (some rows had both names and parties blank). All were hand-filled at AHQ:762–793.
- Check: for each state, office and slot, count rows with the name present and the party blank, and states where some respondents have a slot filled and others blank.
- Guard: SILENT (a blank party becomes Other).

**B6. Wrong party shown on a candidate.**
- Past: FL-23 2014 (Wasserman Schultz shown as R; excluded).
- Check: after matching names, CES party ≠ returns party. Also flag two displayed candidates with the same major party outside top-two states.
- False positives: CA, WA and LA top-two races; D-nominated independents.
- Guard: LOUD only when the mismatched candidate is the benchmark.

**B7. Party strings that `clean_party_names` mis-buckets.**
- Rule: only an exact "Republican" counts as Republican; any string containing "Democratic" counts as Democrat; everything else is Other.
- Check: tabulate every distinct value of every *Party* variable.
- Hit: a variant that names a major party ("Republican Party", "GOP", "Republican " with a trailing space, "Independent-Republican"). DFL and Dem-NPL are fine.
- Guard: SILENT.

**B8. Generic party options where a party had no candidate.**
- Past: NC AG 2012 (485 of 1,071 chose a nonexistent Republican). AG and SoS used generic options 2006–16; state legislature used them in every year. The 11 AG races above 90% supply 63% of AG squared error.
- Check: for each party-level item, list the offered parties against the parties with candidates in the returns. Report the share choosing an absent party.
- Decision: keep and disclose (rule 14). This record feeds the Section H sensitivity analysis.

**B9. Item asked where there is no contest or the office isn't elected.**
- Past: 546 "Election did not occur" and 228 "Not elected position" skip rows. DC Senate is skipped every year. NE is unicameral or nonpartisan. OK AG 2014 (Pruitt unopposed) is excluded, which is inconsistent with keeping NC AG 2012.
- Check: compare the item's non-missing N by state with whether a 2024 general contest exists in the returns and whether the office is elected.
- Hit: responses with no contest (needs a skip row), or a contest with no item.
- Guard: the party path is LOUD ("No election results"), so the pipeline would fail midway; the candidate path is SILENT.

**B10. Routing that hides answers (straight ticket and similar).**
- Past: 2018 CC18_408/409 (4,021 respondents; TX Senate Democratic share 52.3 with the fill vs. 57.6 without). The 2008 House missingness came from whole districts not being asked.
- Check: the NA rate on each vote item among post-wave self-reported voters, by state, against 2022. Search the variable labels for straight/ticket/party-line.
- Hit: a state block more than twice its 2022 rate.

**B11. Second-race items and concurrent specials.**
- Past: the CES asked a separate second-race item in 9 of 11 concurrent-special state-years. JD drops the specials anyway (rule 12). Stray single answers to the second-race item come from non-special states.
- 2024: check that `CC24_411` in NE is the regular race (Fischer vs. Osborn) and `CC24_411b` the special. CA has the same candidates in both races.
- Hit: `CC24_411` names match the special's candidates, or second-race answers come from non-special states.

**B12. Pre- and post-wave reports disagree.**
- Past: 2020 Senate, 68 of 5,726. Rule 3 applies.
- Check: count disagreements (fyi only).

**B13. Too few respondents.**
- Past: DC 2006 House (1 of 18 respondents).
- Check: n per scored unit. Hit: n below a threshold JD sets (suggest 10).

### C. Geography

**C1. CD misassigned.**
- Past: NC 2020, 774 respondents flagged by the CES and dropped from House.
- 2024: AL, GA, LA, NC and NY redrew their maps. `cdid118_post` and `cdid119_post` differ only in those states.
- Check: use `cdid119_post`. Check that each respondent's `HouseCand*Name_post` set equals their district's 2024 returns candidates, and look for any CES change-flag variable.
- Hit: a district whose names don't match, or a respondent whose names belong to a different district.
- Guard: NONE for 2024 (`filter_nc_if_needed` is hard-coded to 2020).

**C2. CD encoding drift.**
- Past: "01" strings vs. numeric districts dropped districts 1–9 in 2008 and 2010. At-large was coded "00", "1" or 0. "-1" appears in 2020. Fixed by `normalize_cd`, which handles both sides: integer, with 0→1.
- Check: distinct raw CD values by state. Hit: a non-integer, a negative, more than 1% NA, a CD greater than the state's seat count, or an at-large code that isn't 0 or 1.
- Guard: SILENT (bad values become NA).

**C3. State label mismatch across tables.**
- Past: DC appeared as "Washington DC" in the turnout files (fixed; now asserted).
- Check: the state (and state × district) key sets must be identical across the CES, returns, turnout and skip tables before any join: 51 units.

### D. CES ↔ returns matching

**D1. Name-format differences and unchecked fuzzy matches.**
- Past: 4,185 contests (2,874 exact, 1,309 Jaro, maximum distance 0.52, all reviewed, 0 wrong). Nicknames such as Jerry / Edmund G. Brown and Chuy / Jesús García. Menendez is hard-coded.
- The 3 wrong matches that surfaced (Boren, Poe, Wilson; quoted nicknames) led to the party-restricted pool.
- Check: export every non-exact match sorted by distance for manual review. Flag any match where the CES name's last-name token isn't in the returns name.
- Guard: no threshold; LOUD party guard.

**D2. Same person under several names within a contest in the returns.**
- Past: 13 crosswalk entries (RI Chafee/Chaffee 2006; AK Murkowski and McAdams 2010; RI Fontes and Costa 2018; RI-1 Kennedy 2006; RI-1 Ugilmette 2018). Two crosswalk entries match nothing today.
- Check: pairwise within each contest. Hit: SequenceMatcher above 0.8, the same last name (more than 3 characters), or one name containing the other.
- False positives: relatives (Ross AR-4 2006; Carter LA-2 2006).
- Also validate that every crosswalk key matches a row.

**D3. Contest with no returns, or returns with no CES contest.**
- Past: FL-25 2020 and other unopposed FL and OK districts aren't reported. LA-2 and LA-4 2008 (December generals) are missing from the 2008 name file.
- Check: the full outer join of CES contests (state × office × district with responses) and returns contests; list both anti-joins.
- Guard: the candidate path is SILENT (the contest is skipped); the party path is LOUD.

**D4. Positional and slot-order assumptions.**
- Past: Governor `cand_num` must equal the CES slot. President REP=1 in 2008 and 2016. 2008 MS and WY keep the first Senate row by row order.
- Check: the returns candidate with `cand_num` N must fuzzy-match the CES `GovCandN`/`PresCand` name for slot N.

### E. Election returns

**E1. Non-vote rows in the denominator.**
- Past: presidential BLANK/UNDER/OVER/VOID rows in 22 state-years; MA and NY 2008/12 merged blank+scattering rows; RI 2008 Senate "BLANK" (67); ME-02 2022 "BALLOT, EXHAUSTED".
- Check: regex `BLANK|OVER ?VOTE|UNDER ?VOTE|VOID|EXHAUST|SPOIL|NONE OF THE ABOVE|TOTAL|SCATTER.*BLANK` on candidate names in every 2024 file. NV's "None of these candidates" is fine.
- 2024: MEDSL President is 0.6–1.4% above FEC in DC, HI, ID, MA, ME, NH, NY, VT and WY.
- Guard: LOUD for President only.

**E2. Fusion lines not collapsed, including through name variants.**
- Past: NY, CT and SC (336 contests). The Senate party table put WF/CRV lines in Other until `de78291`. NY President fusion was fixed by `collapse_fusion_lines` (uncommitted). 12 state-legislative name variants were fixed (Schneiderman, Arconti Jr/Jr., Mack/Mack III, Bronson, and others).
- Check: within each contest, normalize names (case, punctuation, middle initials, suffixes) and flag minor-line rows whose normalized name equals or nearly equals a D or R candidate's while the raw string differs.
- 2024: NY WFP and Conservative lines; CT WFP and Independent; VT DEM/PROG.

**E3. One candidate on both the D and R lines (cross-filing).**
- Past: NY state senate (every year), NY state house 2006–16, CT 2008, SC 2012 (skipped); NH 2006 (36 candidates, 7%; excluded).
- Live: NH 2012 Hillsborough-37 "McGuire" has a D line and an R line, both counted as Democrat (verified).
- Check: group by contest × candidate. Hit: both D and R present. Compute rule 10's 1-pt test.
- Guard: LOUD for federal offices; SILENT for state legislative (Democrat wins).

**E4. Ambiguous major-party labels.**
- Past: WA "Independent-GOP" 2012/16 (excluded); WA "Prefers G.O.P." mis-simplified (fixed); MS nonpartisan specials (excluded).
- Check: regex `GOP|Republican|Democrat|Dem\b|Rep\b|DFL|NPL` on labels that aren't the canonical value. Compute vote shares. Apply rule 10 or 11.
- 2024: WA "Prefers X Party" labels; ND Democratic-NPL (already coded D in the governor file); UT IAP.

**E5. Errors in `party_simplified`.**
- Past: OR Sen 2022 Perkins "R/CON" → OTHER; WA-1 2008 and WA-8 2018 "GOP" → OTHER (fixed). Live: House "IND" (AK 2020 Galvin) and Governor "OtHER" fall outside DEM/REP/OTHER and are dropped by `collapse_proportion_table`.
- Check: values outside {DEM, REP, OTHER}; a `party_detailed` value mapping to more than one simplified value; OTHER rows whose detail contains a D or R token with at least 1% of the vote; write-in rows coded DEM or REP.
- Guard: SILENT.

**E6. A candidate's party coded inconsistently, or a manual party with no provenance.**
- Past: Galvin, AK-AL: DEM in 2018 ("endorsed by democratic party"), IND in 2020 ("technically indep") (verified). Gross AK 2020 "N(D)/D" → OTHER. Supplement C's manual party assignments are unmarked, so they can't be audited.
- Check: for 2024 candidates who also ran in 2018–22, flag a different `party_simplified`. Require a `party_source` column (`returns` or `manual`) on every filled-in party.
- 2024: UT Gov Lyman (a Republican running as a write-in): apply rule 11 once the CES label is known.

**E7. Wrong vote values (typos, swaps, extra digits).**
- Past: SD 2006 SoS 2,171,518 (should be 217,518); NY-17 2006 and NY-21 2008 D/WF votes swapped; OH-11 2018 corrected; UT Gov 2010 total 634,307 vs. 643,307; WI 2008, 2010 and 2012 Assembly entry errors; CT 2014 and 2016 hand edits; AK 2010 HD34 missing; ME-02 2022 (an extra leading digit plus exhausted ballots).
- Check:
  - Per contest: sum of candidate votes ≠ the reported total (report the % difference).
  - More than one distinct total within a contest.
  - A candidate's votes above the total, or more than 2× the office median.
  - A fusion candidate with fewer votes on the major line than on a minor line.
  - A digit-count outlier against the 2022 contest.
  - Against a second source (FEC, SoS, MEDSL), a difference above 0.5%.
- Guard: totals are recomputed from candidate votes, so total typos are neutralized; candidate-vote errors pass SILENTLY.

**E8. Duplicate rows, or merged contests.**
- Past: House contests listed twice (IN-3 2010, NY-29 2010, KY-4 and NJ-10 2012, WA-1 2012, PA-2 2016, NY-25 2018; removed).
- Live: CT 2012 HD2 Dan Carter and CT 2016 HD90 Fishbein have two R rows each with different `total_votes` (verified). These are probably two districts merged under one label.
- 2024: IN governor precincts duplicated in MEDSL (+4%).
- Check: `duplicated(year, state, office, district, candidate, party)`. Report whether the votes are identical or differ.
- Guard: SILENT double-count.

**E9. Garbled names.**
- Past: 35 mojibake names in the 2022 House file (fixed). Still present: Senate footnote markers "ZUPAN, LAWRENCE  #" and others (the VT override depends on the "#"); CO 2020 "JACOB?FAMBRO"; FL Gov 2022 "Gimenez, \tCarmen"; casing problems.
- Check: regex `Ã|â€|Â|\?|\t|#|\*|\s{2,}`, an all-lowercase token, or leading or trailing space. Diacritics and the ʻokina are false positives.

**E10. RCV rounds.**
- Past: ME-02 2022 had totals summed across rounds (fixed in `de78291`). Rule 13 applies.
- Check: for AK and ME contests, look for an "exhausted" row, duplicate candidate rows, or a total more than 1.1× the 2022 total or above state turnout.
- 2024: AK (all offices), ME (all federal offices).

**E11. Specials mislabeled, concurrent, or the only contest.**
- Past: 274 Ballotpedia specials labeled as generals (2018–22), removed by anti-join. 7 removal rows match nothing. 10 even-year rows flagged `special_election == TRUE` are still in the benchmark (MI 2006, GA 2012, OH 2012 ×2, HI/OK/TN 2014, MI/OR 2016; OH 2008 AG is intentional). Concurrent Senate specials are dropped. Specials that were the only statewide contest are kept (DE and WV Senate 2010, HI 2014, OR Gov 2016, TX 2006).
- Check:
  - In state-legislative contests, flag district names containing "Unexpired", "Special" or "(Historical)".
  - Flag staggered-senate districts that also held races in 2022.
  - Flag two contests with the same district on one date, or with a missing `special_election` value.
  - Flag Senate states with more than one 2024 contest.
  - Check that every removal-list row matches exactly one returns row.
- 2024: CA and NE Senate concurrent specials; TX-18 and WI-8 House unexpired-term specials (leave them out of the file).
- Guard: SILENT.

**E12. Chamber not up, so its "statewide" benchmark is a special.**
- Past: SC 2014 SS (error −61), NJ 2020 and 2022 Assembly, KS 2010 SS, MN 2008 SS (skipped in `fc514cf`). The returns didn't mark them as specials.
- Check: per chamber, districts present ÷ the chamber's maximum district count across years. Hit: below 0.4, then check the state calendar. Do not rely on the `special` column.
- 2024: chambers not up are AL, LA, MD, MS, NJ, VA, the MI Senate and the MN Senate (verify).

**E13. Unopposed seats missing, or placeholder votes.**
- Past: unreported FL and OK House districts, every year; FL-5 and LA-4 2022 show 1 vote each. 477 state-legislative contests have all-NA votes (AR, TX, FL, HI, OK). In AR, unopposed candidates are off the ballot. The share of a chamber's vote in uncontested districts biases the party share (−1.7 pt per 10 pts; the C3 analysis).
- Check:
  - Compare House districts against the 2024 apportionment.
  - Flag single-candidate contests with ≤10 votes.
  - Per chamber, report the share of districts with all-NA votes and the share of votes in districts with no D or no R.

**E14. Top-two, jungle and runoff races.**
- Past: LA Sen 2016 (December runoff; the November round is used); LA SoS 2018 (December general; skipped); GA Senate rounds; CA and WA same-party House races.
- Check: contests with more than one D or more than one R, a `stage` other than general, or a date outside November.
- 2024: LA House was a November open primary; CA and WA same-party races (verify).

**E15. Top vote-getter not comparable (independent or write-in winner, or no D or R).**
- Past: the 8 overrides (AK 2010, ME and VT Senate 2012 and 2018, LA Sen 2016, RI Gov 2010, ND SoS 2018), each paired with a modal exception. Nothing checks that the two lists agree.
- Check: contests whose top candidate is OTHER or where DEM or REP is absent. Propose an override row and a modal-exception row, and assert the two lists match.
- 2024: ME (King) and VT (Sanders) Senate; NE Senate regular (Osborn won no seat and there was no D candidate, so the modal benchmark is R; describe the race); UT Gov (Lyman write-in, 13.6%).

**E16. Uncontested statewide races (100%).**
- Past: IA 2006 AG, ID 2010 AG, NC 2012 AG, SD 2010 Sen, NE AG 2006/10/18, and others. All were verified unopposed and kept. NE 2018 AG has a 0-vote Democratic row for a candidate not on the ballot. DC 2022 AG excludes write-ins.
- Check: winner ≥ 99%. Verify it was unopposed, and flag 0-vote rows.

**E17. Benchmark unavailable.**
- Past: AR legislature 2008 and 2010 (paper ballots only; skipped).
- Check: a chamber where fewer than 50% of districts have non-NA votes.

**E18. Source discrepancies, and unofficial or uncertified rows.**
- Past: certified shares differ across sources. MEDSL GitHub 2024 has 41 President and 6 Senate rows marked `unofficial`, and the Dataverse Senate V8 still has 10. IN governor 2024 comes from a secondary source.
- MEDSL precinct files are not benchmark-grade: IN has duplicated precincts; ND is missing counties; LA President is −48%; NY state-legislative district fields are blank.
- Check:
  - Every 2024 row carries a source.
  - No row is flagged unofficial.
  - Per contest, compare against a second source and flag differences above 0.5%.

**E19. Stray rows or a mislabeled office.**
- Past: TN 2008 "Attorney General" is a district attorney general race; "U.S. House" rows sit inside the state-legislative file; all-NA rows; malformed lines in the 2008 CSV (read with `suppressWarnings`).
- Check: NA in any key column, an office outside the expected set, or a statewide office with a district-level office name.

### F. Lookup tables and hard-coded fixes

**F1. Keys that don't match.**
- Past: `ST_HOUSE_*` skip rows matched nothing until `de78291`. Live: 5 duplicate skip rows; 7 dead removal rows; 2 dead crosswalk entries; trailing spaces in `CES_Reported_Errors.xlsx` "Race" (8 values; they show as "--" in Table 12 and distort `\GuideGapOverall`).
- Check: every key in the skip file, removal list, crosswalk, overrides, modal exceptions and reported-errors file must be in `race_maps`, use the 51 uppercase state names, have an integer year, carry no whitespace, match at least one target row, and have no duplicates.
- This is the cheapest check with the highest value. Run it first.

**F2. Year-keyed fixes that won't fire for 2024.**
- The NC wrong-CD filter (2020 only), FL-23 (2014), President slot order (2008/2016), the RI "BLANK" string filter, the MA/NY merged-row fix (`stopifnot(nrow == 4)`), the 2008 name file, and the 2018 straight-ticket fill.
- For each one, the swarm records whether 2024 has an analogue.

### G. Other benchmarks

**G1. Turnout numerator estimated rather than counted.**
- UF v0.4 has rounded total-ballot figures for AL, MS, MO, OK, PA, TN and TX. The 2006–2022 fallback rule was to use highest-office votes.
- Check: list the rounded values. Propose replacing them with 2024 presidential votes from the returns (a decision for JD).

**G2. VEP + felons construction.**
- Check: VEP + ineligible felons should equal VAP × (1 − noncitizen share) within 0.1%. Flag the gaps.

## 3. Expected 2024 cases to seed the swarm (verify each)

**Senate**
- NE: regular race (Fischer R vs. Osborn I; no D) and a special (Ricketts vs. Love). Check what `CC24_411` and `CC24_411b` cover.
- CA: regular and special races with the same candidates (Schiff vs. Garvey).
- ME (King) and VT (Sanders): overrides.
- AK is not up. ME has no Senate RCV issue: King won outright.

**House**
- Redistricted in 2024: AL, GA, LA, NC, NY.
- LA held a November open primary.
- Unexpired-term specials (TX-18, WI-8) stay out of the file.
- FL and OK unopposed districts won't be reported.
- AK-AL and ME-2 went to RCV; use first round.
- DC delegate row.
- Same-party races in CA and WA.

**Governor (11 states)**
- UT: Lyman write-in.
- ND: Democratic-NPL.
- VT: DEM/PROG fusion.
- IN: secondary source.
- `cand_num` for third candidates depends on the CES list.

**AG** (IN MO MT NC OR PA UT VT WA WV) and **SoS** (MO MT NC OR VT WA WV)
- Confirm the CES asked these.
- Every other state needs skip rows.

**State legislatures**
- Chambers not up: see E12.
- NE is nonpartisan.
- NY fusion: skip the NY state senate, per precedent.
- WA "Prefers" labels.
- Ballotpedia specials.
- AR, FL and TX unopposed districts with NA votes.

**President**
- Withdrawn candidates (RFK Jr.) may still be listed in the CES.
- MEDSL blank-row excess in 9 states.
- NY fusion lines go through `collapse_fusion_lines`.
- PresCand slot order.
- Labels must match the normalized returns names ("Kamala D. Harris", "Donald J. Trump").

**CES file**
- Residence item probably dropped (`CC24_361b`).
- CSV missing codes: `-1`, `""`, `__NA__`.
- 5 House slots and 3 Senate slots plus `SenCand*Name2`.
- No `_post` name variables for AG or SoS.
- New `mena` race items.

## 4. Swarm plan (run once JD supplies the raw files)

**Inputs to collect first:**
- the CES 2024 file (the .dta if it exists) and its Dataverse version;
- the 2024 guide PDF and the questionnaire;
- every 2024 returns file in its final format (§4 of `2024-inclusion-change-inventory.md`);
- the second-source files (FEC, SoS) wherever they were pulled.

**Phase 0 (one agent): key and lookup integrity (F1).** Also stage the needed column extracts of the CES file to scratch (Parquet), so the other agents don't each reread the .dta.

**Phase 1 (parallel, about 8 agents):**
1. Guide vs. file, variables and labels: A7, A8, A9, A10.
2. Guide sampling and weighting text: A1–A6. Also drafts the 19 rows for `ces_weighting_stage_variables.csv`.
3. CES candidate lists vs. returns, statewide offices: B1–B7, B11, D1, D4, for President, Senate, Governor, AG and SoS.
4. CES candidate lists vs. returns, House: B1–B7, C1, C2, D1 and D3 by district. This is the biggest job; split it by state halves if needed.
5. Coverage and routing: B8, B9, B10, B12, B13, C3, D3. Also drafts the 2024 skip rows.
6. Returns integrity, federal and governor files: E1, E5, E7, E8, E9, E10, E14, E15, E16, E18, E19.
7. Returns integrity, state legislative, AG and SoS file: E2, E3, E4, E11, E12, E13, E17, plus the D2 near-duplicate scan.
8. Party coding across years and turnout: E6, G1, G2.

**Phase 2: verification.** Run one independent agent per phase-1 output. It re-derives a sample of hits and every blocker from the raw files, to drop false positives.

**Phase 3: merge.** Produce a single decisions list for JD, grouped as follows:
- **blockers:** the pipeline would stop, or a wrong number would result;
- **decisions:** places where a rule doesn't settle the case;
- **auto-resolved:** hits where a rule above applies. These come with proposed skip rows, overrides, modal exceptions, crosswalk entries and codebook rows.

## 5. Live defects in the 2006–2022 data found during this pass (for JD's later list)

JD's commit `de78291` already fixed ME-02 2022, the `ST_HOUSE_*` → `ST_REP_*` skip keys, and Senate fusion aggregation. Still open:

1. `CES_Reported_Errors.xlsx`: trailing spaces in 8 Race values, so Table 12 is missing those guide RMSEs and the guide-gap figure (`\GuideGapOverall`) is affected.
2. NH 2012 State Senate Hillsborough-37 "McGuire": a D line (5,581) and an R line (6,772), both counted as Democrat.
3. CT 2012 HD2 (Dan Carter) and CT 2016 HD90 (Fishbein): two R rows each, double-counted.
4. Ten even-year `special_election == TRUE` state-legislative rows are not removed (MI 2006 HD29, GA 2012 HD30, OH 2012 SD1 and SD17, HI 2014 SS, OK 2014 SD5, TN 2014 SD30, MI 2016 SH, OR 2016 SD3).
5. Seven dead rows in the special-removal list and 2 dead crosswalk entries. The `modal_exceptions` list is never checked against the overrides.
6. Galvin AK-AL is coded D in 2018 and IND in 2020.
7. ND SoS 2022 (Ohio names) is excluded but not described in the paper. Supplement C's "three state legislative contests are excluded" understates the exclusions (about 20 NY, CT and SC fusion chamber-years plus MS are also excluded). OK AG 2014 (Pruitt unopposed) is excluded while NC AG 2012 is kept.
8. Smaller items:
   - SD 2006 SoS has an extra digit in its total.
   - NE 2018 AG has a 0-vote off-ballot Democrat.
   - The TN 2008 "AG" row is a district attorney race.
   - The 2010 Senate codebook code 3 points to the party variable instead of the name.
   - The 2008 President codebook labels are permuted.
   - The 2008 CSV is read with warnings suppressed.
   - The Supplement F item 14 placeholder "[p.~?]".
