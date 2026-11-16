"""Collect variant results into comparison tables.

Writes to sensitivity_analyses/results/:
  prose_numbers_by_variant.csv   every prose_numbers.tex macro x variant
  headline_by_variant.csv        the macros behind the paper's main claims
  tables_changed.csv             which LaTeX exhibits differ from base, per variant
  tables_text/<table>.txt        each changed exhibit, flattened to text, all variants
"""
import re
from pathlib import Path
import pandas as pd
from run_variants import VARIANTS

HERE = Path(__file__).resolve().parent
RES = HERE / "results"

HEADLINE = [
    ("NObsCandidate", "Candidate-choice estimates (N)"),
    ("NeitherMeanBefore", "Neither matching nor weighting: matching-only mean RMSE (Table 8)"),
    ("NeitherMeanAfter", "Neither: CES-weighted mean RMSE (Table 8)"),
    ("NeitherCellsImproved", "Neither: cell pairs improved by weights"),
    ("NeitherCellsWorse", "Neither: cell pairs worsened by weights"),
    ("UsedMeanBefore", "Used: matching-only mean RMSE (Table 9)"),
    ("UsedMeanAfter", "Used: CES-weighted mean RMSE (Table 9)"),
    ("TrendSecMatchBeta", "Trend, secondary, matching: beta/yr"),
    ("TrendSecMatchP", "Trend, secondary, matching: p"),
    ("TrendSecWtdBeta", "Trend, secondary, weighted: beta/yr"),
    ("TrendSecWtdP", "Trend, secondary, weighted: p"),
    ("TrendPrimMatchP", "Trend, primary, matching: p"),
    ("TrendPrimWtdP", "Trend, primary, weighted: p"),
    ("CesThreeVarReduction", "CES weights: RMSE reduction, 4 unweighted vars (Table 13)"),
    ("AnesThreeVarIncrease", "anesrake: RMSE increase, 4 unweighted vars (Table 13)"),
    ("AnesHighestYears", "Years anesrake worst of three (Figure 5)"),
    ("ErrMeanMatching", "Mean |error|, matching (Figure 2)"),
    ("ErrMeanWeighted", "Mean |error|, weighted (Figure 2)"),
    ("ErrMedianWeighted", "Median |error|, weighted (Figure 2)"),
    ("ErrBeyondTwentyWeighted", "Share |error| > 20, weighted (Figure 2)"),
    ("AnchorRmse", "RMSE in smallest-n bin (Figure 4)"),
    ("GuideGapOverall", "Our RMSE minus CES guide RMSE (Table 12)"),
]


def macros(p):
    d = {}
    for line in open(p):
        m = re.match(r"\\newcommand\{\\(\w+)\}\{(.*?)\}", line.strip())
        if m:
            d[m.group(1)] = m.group(2).replace("$-$", "-")
    return d


def flat(p):
    out = []
    for l in open(p):
        if "&" in l and "\\\\" in l:
            l = re.sub(r"\\makebox\[[^\]]*\]\[\w\]\{([^}]*)\}", r"\1", l)
            l = re.sub(r"\\hspace\{[^}]*\}|\\multicolumn\{\d+\}\{\w\}|\\textit|\\textbf|~~", " ", l)
            l = l.replace("$-$", "-").replace("\\\\", "").replace("$", "")
            out.append(re.sub(r"\s+", " ", l).strip())
    return out


variants = [v for v in VARIANTS if (RES / v / "prose_numbers.tex").exists()]
pn = pd.DataFrame({v: macros(RES / v / "prose_numbers.tex") for v in variants})
pn.index.name = "macro"
pn.to_csv(RES / "prose_numbers_by_variant.csv")

hl = pn.reindex([m for m, _ in HEADLINE])
hl.insert(0, "label", [l for _, l in HEADLINE])
hl.to_csv(RES / "headline_by_variant.csv")

rows, tdir = [], RES / "tables_text"
tdir.mkdir(exist_ok=True)
base_tabs = sorted((RES / "base").glob("*/*.tex"))
for bt in base_tabs:
    rel = bt.relative_to(RES / "base")
    changed = {v: (RES / v / rel).exists() and flat(RES / v / rel) != flat(bt) for v in variants}
    rows.append({"table": str(rel), **changed})
    if any(changed.values()):
        with open(tdir / (rel.stem + ".txt"), "w") as fh:
            for v in variants:
                if (RES / v / rel).exists():
                    fh.write(f"===== {v}: {VARIANTS[v][2]}\n")
                    fh.write("\n".join(flat(RES / v / rel)) + "\n\n")
pd.DataFrame(rows).to_csv(RES / "tables_changed.csv", index=False)

errs = {v: [l.strip() for l in open(RES / v / "run.log") if "ERROR" in l or "dropped" in l] for v in variants}
for v in variants:
    print(v, "|", "; ".join(errs[v]) or "no exclusions, no errors")
print()
print(hl.to_string())
