"""Build race-level flags for the sensitivity analyses.

Writes flagged_races.csv: one row per (race, flag). A race is keyed exactly as
figuresHQ.ipynb keys contests: Year | State | Variable | District, with a
missing District read as 'statewide'.

Flags
-----
Analysis 1 (Supplement C cases still in the analysis)
  suppC_list_mismatch   CES candidate list did not match the ballot but the
                        contest was retained (KS/IA Senate 2014, CT SoS 2022,
                        HI-2 House 2006)
  suppC_nominee_bench   one of the eight contests benchmarked against a
                        major-party nominee rather than the top vote-getter
  suppC_fusion          a candidate's votes were summed over two or more
                        ballot lines (detail = share of the race's votes on
                        secondary lines, in points)
  suppC_special         benchmark is a special election (the only race for
                        that office that year)
  ces_manual_fix        CES file was hand-corrected before scoring (missing
                        candidate names/parties)
  returns_hand_fix      a returns row carries a note that it was hand-entered
                        or corrected (e.g. Ballotpedia typo)
Analysis 2 (question format)
  party_label_item      estimate comes from a party-label item (no candidate
                        names shown): all state legislative items, AG/SoS
                        2006-2016, Governor 2006-2008, House/Senate 2006
Also, for reference
  uncontested_gt90      winner's benchmark share > 90 percent

Run from the repo root or this folder:  python3 sensitivity_analyses/build_flags.py
"""
from pathlib import Path
import re
import pandas as pd

HERE = Path(__file__).resolve().parent
REPO = HERE.parent
RET = REPO / "data" / "Benchmarks" / "Election Returns"
MS = REPO / "tables_and_figures" / "input_tables" / "most_specific.xlsx"


def key(year, state, variable, district):
    d = "statewide" if pd.isna(district) or str(district) in ("nan", "") else str(district)
    return f"{int(year)}|{str(state).upper()}|{variable}|{d}"


def ms_key(df):
    return [key(y, s, v, d) for y, s, v, d in zip(df.Year, df.State, df.Variable, df.District)]


rows = []
def add(k, flag, detail=""):
    rows.append({"Race_Key": k, "Flag": flag, "Detail": detail})


# ---------------------------------------------------------------- analysis table
ms = pd.read_excel(MS)
ref = ms[(ms.Class == "Candidate Choice") & (ms.Weighting_Method == "CES-Provided Weights")
         & (ms.Validity_Scheme == "All")].copy()
ref["Race_Key"] = ms_key(ref)
in_analysis = set(ref.Race_Key)

# ---------------------------------------------------------------- hand-coded lists
for y, s, v, d, note in [
    (2014, "KANSAS", "U.S. Senate", None, "CES listed Barnhart (I), not on ballot"),
    (2014, "IOWA", "U.S. Senate", None, "CES listed Williams (I), not on ballot"),
    (2022, "CONNECTICUT", "Secretary of State", None, "CES file named Harris (R), not on ballot"),
    (2006, "HAWAII", "U.S. House", "District 2", "Hanabusa shown instead of nominee Hirono"),
]:
    add(key(y, s, v, d), "suppC_list_mismatch", note)

for y, s, v in [(2010, "ALASKA", "U.S. Senate"), (2012, "MAINE", "U.S. Senate"),
                (2018, "MAINE", "U.S. Senate"), (2012, "VERMONT", "U.S. Senate"),
                (2018, "VERMONT", "U.S. Senate"), (2016, "LOUISIANA", "U.S. Senate"),
                (2010, "RHODE ISLAND", "Governor"), (2018, "NORTH DAKOTA", "Secretary of State")]:
    add(key(y, s, v, None), "suppC_nominee_bench", "benchmarked to major-party nominee")

for y, s, v, d, note in [
    (2022, "ALASKA", "U.S. House", "District 1", "Begich party filled in by hand"),
    (2020, "WEST VIRGINIA", "Attorney General", None, "Petsonk party filled in by hand"),
    (2014, "OKLAHOMA", "Governor", None, "missing candidate names/parties filled in"),
]:
    add(key(y, s, v, d), "ces_manual_fix", note)

# ---------------------------------------------------------------- returns files
def fed(path, variable, district_fn):
    r = pd.read_excel(path)
    r = r[(r.get("stage", "gen") == "gen")]
    if "concurrent_special" in r:
        r = r[r.concurrent_special.fillna(False) != True]
    r["Race_Key"] = [key(y, s, variable, district_fn(d)) for y, s, d in zip(r.year, r.state, r.district)]
    r = r.rename(columns={"candidatevotes": "votes", "party_detailed": "party"})
    return r

house_d = lambda d: f"District {max(int(d), 1)}"
state_d = lambda d: None
frames = [
    fed(RET / "US_Senate_Returns_2006_2022.xlsx", "U.S. Senate", state_d),
    fed(RET / "US_House_Returns_2006_2022.xlsx", "U.S. House", house_d),
    fed(RET / "Governor_Returns_2006_2022.xlsx", "Governor", state_d),
    fed(RET / "President_Returns_2008_2020.xlsx", "President", state_d),
]

leg = pd.read_excel(RET / "State_Legislative_and_Constitutional_Offices_2006_2023.xlsx")
leg = leg[leg.concurrent_special.fillna(False) != True].copy()
leg["year"] = pd.to_datetime(leg.election_date).dt.year
office_map = {"State House": "State Representative", "State Senate": "State Senator",
              "Attorney General": "Attorney General", "Secretary of State": "Secretary of State"}
leg = leg[leg.office.isin(office_map)].copy()
leg["Variable"] = leg.office.map(office_map)
# State legislative contests are scored as statewide party aggregates.
leg["Race_Key"] = [key(y, s, v, None) for y, s, v in zip(leg.year, leg.state, leg.Variable)]
leg["subrace"] = leg.office_district.astype(str) + "|" + leg.district.astype(str)
leg = leg.rename(columns={"party_original": "party", "special_election": "special"})

# Fusion: candidate on >1 ballot line within a single contest.
def fusion(df, sub_cols):
    g = df.groupby(sub_cols + ["candidate"])
    multi = g.filter(lambda x: x["party"].nunique() > 1)
    if multi.empty:
        return
    tot = df.groupby("Race_Key").votes.sum()
    for (rk, *_), grp in multi.groupby(sub_cols + ["candidate"]):
        pass
    sec = (multi.groupby(sub_cols + ["candidate"])
                .apply(lambda x: x.votes.sum() - x.votes.max(), include_groups=False)
                .reset_index(name="secondary_votes"))
    sec = sec.groupby("Race_Key").secondary_votes.sum()
    for rk, v in sec.items():
        add(rk, "suppC_fusion", f"{100 * v / tot[rk]:.2f}")

for f in frames:
    f = f.copy(); f["subrace"] = ""
    fusion(f, ["Race_Key", "subrace"])
fusion(leg, ["Race_Key", "subrace"])

# Special elections used as the contest: the race has special-election rows and
# no regular rows (Supplement C's "only election was a special" rule). Checked on
# the unfiltered returns, because such specials can also be marked concurrent.
def raw_fed(path, variable, district_fn):
    r = pd.read_excel(path)
    r["Race_Key"] = [key(y, s, variable, district_fn(d)) for y, s, d in zip(r.year, r.state, r.district)]
    return r[["Race_Key", "special"]]
raw = [raw_fed(RET / "US_Senate_Returns_2006_2022.xlsx", "U.S. Senate", state_d),
       raw_fed(RET / "US_House_Returns_2006_2022.xlsx", "U.S. House", house_d),
       raw_fed(RET / "Governor_Returns_2006_2022.xlsx", "Governor", state_d)]
leg_raw = pd.read_excel(RET / "State_Legislative_and_Constitutional_Offices_2006_2023.xlsx")
leg_raw = leg_raw[leg_raw.office.isin(office_map)].copy()
leg_raw["Race_Key"] = [key(pd.Timestamp(d).year, s, office_map[o], None)
                       for d, s, o in zip(leg_raw.election_date, leg_raw.state, leg_raw.office)]
raw.append(leg_raw.rename(columns={"special_election": "special"})[["Race_Key", "special"]])
for r in raw:
    sp = r.special.astype("boolean").fillna(False)
    only_special = sp.groupby(r.Race_Key).all()
    for rk in only_special[only_special].index:
        add(rk, "suppC_special", "special election only")

# Hand-corrected returns rows.
hand = re.compile(r"manual|incorrect|originally|extra digit|human error|changed to|endorsed by", re.I)
for f in frames + [leg]:
    if "notes" in f:
        n = f[f.notes.astype(str).str.contains(hand)]
        for rk, note in zip(n.Race_Key, n.notes):
            add(rk, "returns_hand_fix", str(note)[:120])

# ---------------------------------------------------------------- analysis 2 + reference
for rk, spec, b in zip(ref.Race_Key, ref.Specificity, ref.Benchmark):
    if spec == "Party":
        add(rk, "party_label_item", "")
    if pd.notna(b) and b > 90:
        add(rk, "uncontested_gt90", f"{b:.1f}")

out = pd.DataFrame(rows).drop_duplicates(["Race_Key", "Flag"])
out["In_Analysis"] = out.Race_Key.isin(in_analysis)
out = out.merge(ref[["Race_Key", "Benchmark", "CES_Weighted", "Error", "n_respondents", "Specificity"]],
                on="Race_Key", how="left")
out.to_csv(HERE / "flagged_races.csv", index=False)

summary = out[out.In_Analysis].groupby("Flag").Race_Key.nunique()
print("Races flagged (and present in the analysis table):")
print(summary.to_string())
missing = out[~out.In_Analysis & out.Flag.isin(["suppC_list_mismatch", "suppC_nominee_bench", "ces_manual_fix"])]
if len(missing):
    print("\nHand-listed races NOT found in the analysis table (check keys):")
    print(missing[["Race_Key", "Flag"]].to_string(index=False))
