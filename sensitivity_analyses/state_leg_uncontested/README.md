# C3: state legislative error and uncontested seats (exploratory; not in the paper)

The question: the CES state legislative items offered generic "Democratic candidate / Republican candidate" options in every year. Does state legislative error rise where many seats lacked one party's candidate? Run with `python3 run.py`; the outputs are `state_year_chamber.csv` and `results.txt`. Delete this folder to remove the analysis.

## Measures
For each state-year-chamber (759 of 760 with errors), from the returns:
- **opp_absent_votes**: the share of the chamber's votes cast in districts where the statewide winning party's opponent fielded no candidate. The median is 18%.
- **win_absent_votes**: the same, for districts where the winning party fielded no candidate.
- **pct_uncontested**: the share of districts missing either party. The median is 32%.

Signed error is the CES share minus the benchmark share for the statewide winning party, as in the paper.

The one unmatched contest is SC 2014 state senate. Its benchmark is a single-district special election, and the script excludes specials. That contest is a data problem of its own; see the main README.

## Results (OLS with year and chamber fixed effects, HC3 standard errors)
| | CES weights | Matching only |
|---|---|---|
| Change in signed error per point of opp_absent_votes | −0.17 (p < .001) | −0.23 (p < .001) |
| Change in signed error per point of win_absent_votes | +0.14 (p < .001) | +0.29 (p < .001) |
| R² | 0.19 | 0.23 |

Results by quartile of opp_absent_votes, CES weights:

| Quartile | Mean opp_absent_votes (%) | Mean signed error | RMSE |
|---|---|---|---|
| Q1 (fewest) | 3.0 | −0.9 | 7.1 |
| Q2 | 13.2 | −1.7 | 5.4 |
| Q3 | 23.2 | −1.9 | 6.0 |
| Q4 (most) | 43.2 | −6.7 | 9.2 |

- The top quartile holds **42% of state legislative squared error**.
- Dropping chambers with more than 25% of votes in opponent-absent districts (508 of 759 remain) lowers RMSE from 6.28 to 5.72 for state representative and from 7.88 to 6.54 for state senator.

## Reading
The mechanism is real and runs through the state legislative estimates generally, not just a few lopsided races. Where the winning party's opponent was missing from many districts, the CES understates the winner. Each 10 points of the vote cast in such districts lowers the winner's measured share by about 1.7 points. That is consistent with respondents in uncontested districts reporting a vote for a party that had no candidate. Where the winner itself was absent from districts, the sign reverses, as the mechanism predicts.

What this does and doesn't affect:
- **State legislative error levels.** These partly reflect the questionnaire, not only the sample.
- **The comparison of CES weights and anesrake (Table 13).** Not affected: it compares weighting schemes on the same responses. The state legislative rows of that table were unchanged in every sensitivity variant.
