"""C3 check (exploratory, not in the paper): does state legislative error track uncontested seats?

The CES state legislative items offered generic "Democratic candidate / Republican
candidate" options in every year. In a district where one party fielded no
candidate, a respondent can still choose that party. If this matters, the CES
should understate the statewide winning party's share more where the winner's
opponent was absent from many districts.

For each state-year-chamber, from the returns:
  pct_uncontested     share of districts missing a Democrat or a Republican
  opp_absent_votes    share of the chamber's votes cast in districts where the
                      statewide winning party's opponent fielded no candidate
  win_absent_votes    share cast in districts where the winning party fielded none
Joined to the paper's state legislative errors (most_specific, Validity 'All').
Signed error = CES share minus benchmark share for the statewide winning party.

Outputs (this folder): state_year_chamber.csv, results.txt
"""
from pathlib import Path
import numpy as np
import pandas as pd
import statsmodels.formula.api as smf

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent

leg = pd.read_excel(REPO / "data/Benchmarks/Election Returns/State_Legislative_and_Constitutional_Offices_2006_2023.xlsx")
leg = leg[leg.office.isin(["State House", "State Senate"])].copy()
leg = leg[(leg.special_election.fillna(False) != True) & (leg.concurrent_special.fillna(False) != True)]
leg["Year"] = pd.to_datetime(leg.election_date).dt.year
leg = leg[leg.Year % 2 == 0]
leg["State"] = leg.state.str.upper()
leg["Variable"] = leg.office.map({"State House": "State Representative", "State Senate": "State Senator"})
leg["dist"] = leg.office_district.astype(str) + "|" + leg.district.astype(str)

# A candidate counts as a party's nominee if any of their ballot lines is that party (fusion).
cand_party = (leg.groupby(["State", "Year", "Variable", "dist", "candidate"]).party_simplified
                 .agg(lambda p: "D" if (p == "Democrat").any() else ("R" if (p == "Republican").any() else "O")))
d = cand_party.reset_index(name="p")
dist = d.groupby(["State", "Year", "Variable", "dist"]).p.agg(has_D=lambda p: (p == "D").any(),
                                                            has_R=lambda p: (p == "R").any()).reset_index()
votes = leg.groupby(["State", "Year", "Variable", "dist"]).votes.sum().rename("votes").reset_index()
dist = dist.merge(votes, on=["State", "Year", "Variable", "dist"])

ms = pd.read_excel(REPO / "tables_and_figures/input_tables/most_specific.xlsx")
e = ms[(ms.Class == "Candidate Choice") & (ms.Validity_Scheme == "All")
       & ms.Variable.isin(["State Representative", "State Senator"])
       & ms.Weighting_Method.isin(["CES-Unweighted", "CES-Provided Weights"])]
e = e.pivot_table(index=["State", "Year", "Variable", "Category", "Benchmark", "n_respondents"],
                  columns="Weighting_Method", values="Error").reset_index()
e = e.rename(columns={"CES-Unweighted": "err_matching", "CES-Provided Weights": "err_weighted"})

def summarize(g, winner):
    w = "has_D" if winner == "Democrat" else "has_R"
    o = "has_R" if winner == "Democrat" else "has_D"
    tot = g.votes.sum()
    return pd.Series({
        "n_districts": len(g),
        "pct_uncontested": 100 * (~(g.has_D & g.has_R)).mean(),
        "opp_absent_votes": 100 * g.loc[~g[o], "votes"].sum() / tot,
        "win_absent_votes": 100 * g.loc[~g[w], "votes"].sum() / tot,
    })

rows = []
for _, r in e.iterrows():
    g = dist[(dist.State == r.State) & (dist.Year == r.Year) & (dist.Variable == r.Variable)]
    if len(g):
        rows.append({**r.to_dict(), **summarize(g, r.Category).to_dict()})
df = pd.DataFrame(rows)
df.to_csv(HERE / "state_year_chamber.csv", index=False)

out = []
P = lambda *a: out.append(" ".join(str(x) for x in a))
P(f"State-year-chambers matched: {len(df)} of {len(e)} with errors")
P(f"Median % districts uncontested: {df.pct_uncontested.median():.1f}; "
  f"median % of votes in districts without the winner's opponent: {df.opp_absent_votes.median():.1f}")
P("")
for est in ["err_weighted", "err_matching"]:
    P(f"=== {est} (signed: CES minus benchmark, winning party)")
    m = smf.ols(f"{est} ~ opp_absent_votes + win_absent_votes + C(Year) + C(Variable)", df).fit(cov_type="HC3")
    for k in ["opp_absent_votes", "win_absent_votes"]:
        P(f"  {k:18s} b = {m.params[k]:+.3f} per pt  (SE {m.bse[k]:.3f}, p = {m.pvalues[k]:.3g})")
    P(f"  N = {int(m.nobs)}, R2 = {m.rsquared:.2f}")
    df["q"] = pd.qcut(df.opp_absent_votes, 4, labels=["Q1 (fewest)", "Q2", "Q3", "Q4 (most)"])
    t = df.groupby("q", observed=True).agg(n=(est, "size"), opp_absent=("opp_absent_votes", "mean"),
                                           mean_signed=(est, "mean"),
                                           rmse=(est, lambda x: np.sqrt((x ** 2).mean())))
    P(t.round(2).to_string())
    P("")

# How much of state legislative squared error sits in the most-uncontested quartile?
w = df.err_weighted ** 2
P(f"Share of weighted squared error in top quartile of opp_absent_votes: "
  f"{100 * w[df.q == 'Q4 (most)'].sum() / w.sum():.0f}%")
# RMSE if state-year-chambers with >25% of votes in opponent-absent districts are dropped
for cut in [10, 25, 50]:
    keep = df.opp_absent_votes <= cut
    P(f"Drop chambers with >{cut}% opponent-absent votes: keep {keep.sum()}/{len(df)}; "
      + ", ".join(f"{v}: {np.sqrt((df.loc[keep & (df.Variable == v), 'err_weighted'] ** 2).mean()):.2f} "
                  f"(all {np.sqrt((df.loc[df.Variable == v, 'err_weighted'] ** 2).mean()):.2f})"
                  for v in ["State Representative", "State Senator"]))
(HERE / "results.txt").write_text("\n".join(out) + "\n")
print("\n".join(out))
