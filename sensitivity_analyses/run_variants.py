"""Rerun tables_and_figures/figuresHQ.ipynb with races excluded, one variant at a time.

The notebook is read, never modified. Each variant runs in a scratch directory
(SCRATCH, default ~/ces_sens_scratch) whose input_tables and ../data point at the
repo's files, and only its output/ folder (prose_numbers.tex and the LaTeX
tables) is copied back to sensitivity_analyses/results/<variant>/.

Exclusion: after the notebook's data-loading cell (the one that reads
most_specific.xlsx), every Candidate Choice row whose race key is flagged is
dropped from both most_specific and metrics_base, for all weighting methods and
validity schemes, so every table is recomputed on the same reduced set of races.

Usage:  python3 sensitivity_analyses/run_variants.py [variant ...]   (default: all)
"""
import json, os, shutil, sys, traceback, multiprocessing as mp
from pathlib import Path
import pandas as pd

HERE = Path(__file__).resolve().parent
REPO = HERE.parent
NB = REPO / "tables_and_figures" / "figuresHQ.ipynb"
SCRATCH = Path(os.environ.get("SCRATCH", Path.home() / "ces_sens_scratch"))
RESULTS = HERE / "results"

A1 = ["suppC_list_mismatch", "suppC_nominee_bench", "suppC_fusion", "suppC_special",
      "ces_manual_fix", "returns_hand_fix"]
STATE_LEG = ("State Representative", "State Senator")

# name: (flags to drop, optional extra filter on Race_Key, description)
VARIANTS = {
    "base":               ([], None, "No exclusions (should reproduce committed numbers)"),
    "A1_list_mismatch":   (["suppC_list_mismatch"], None, "Drop 4 retained CES/ballot list mismatches"),
    "A1_nominee_bench":   (["suppC_nominee_bench"], None, "Drop 8 contests benchmarked to a nominee"),
    "A1_fusion":          (["suppC_fusion"], None, "Drop contests with fusion-line aggregation"),
    "A1_special":         (["suppC_special"], None, "Drop contests benchmarked to a special election"),
    "A1_hand_fixes":      (["ces_manual_fix", "returns_hand_fix"], None, "Drop contests with hand-corrected CES or returns data"),
    "U_gt90":             (["uncontested_gt90"], None, "Drop races with winner > 90%"),
    "A1_all":             (A1, None, "Drop every Supplement C / hand-fix flag above"),
    "A1_all_plus_gt90":   (A1 + ["uncontested_gt90"], None, "A1_all plus races with winner > 90%"),
    "A2_named_only":      (["party_label_item"], None, "Keep only items that named candidates (drops all state legislative)"),
    "A2_named_statewide": (["party_label_item"], lambda k: k.split("|")[2] not in STATE_LEG,
                           "Drop party-label items except state legislative (no named alternative exists)"),
    "A2_generic_AG_SoS":  (["party_label_item"], lambda k: k.split("|")[2] in ("Attorney General", "Secretary of State"),
                           "Drop AG/SoS items with generic 'Democratic/Republican candidate' options (2006-2016)"),
}

FILTER_AFTER = "most_specific = pd.read_excel("


def drop_keys(variant):
    flags, extra, _ = VARIANTS[variant]
    if not flags:
        return set()
    f = pd.read_csv(HERE / "flagged_races.csv")
    keys = set(f.loc[f.Flag.isin(flags), "Race_Key"])
    if extra:
        keys = {k for k in keys if extra(k)}
    return keys


def run(variant):
    wd = SCRATCH / variant
    shutil.rmtree(wd, ignore_errors=True)
    wd.mkdir(parents=True)
    (wd / "input_tables").symlink_to(REPO / "tables_and_figures" / "input_tables")
    os.chdir(wd)

    import matplotlib; matplotlib.use("Agg")
    # Cache the two large workbooks as pickles; reading the xlsx dominates run time.
    real_read_excel = pd.read_excel
    cache = SCRATCH / "_cache"; cache.mkdir(exist_ok=True)
    def cached_read_excel(path, *a, **k):
        p = Path(path)
        if p.name in ("most_specific.xlsx", "metrics_base.xlsx") and not a and not k:
            pk = cache / (p.stem + ".pkl")
            if not pk.exists():
                real_read_excel(p).to_pickle(pk)
            return pd.read_pickle(pk)
        return real_read_excel(path, *a, **k)
    pd.read_excel = cached_read_excel

    keys = drop_keys(variant)
    ns = {"__name__": "__main__"}
    log = open(wd / "run.log", "w")
    log.write(f"variant {variant}: {len(keys)} race keys flagged\n")
    nb = json.load(open(NB))
    for i, c in enumerate(nb["cells"]):
        if c["cell_type"] != "code":
            continue
        src = "".join(c["source"])
        src = "\n".join(l for l in src.split("\n") if not l.lstrip().startswith(("%", "!")))
        try:
            exec(compile(src, f"cell{i}", "exec"), ns)
        except Exception as e:
            log.write(f"cell {i} ERROR: {e!r}\n")
        if FILTER_AFTER in src and keys:
            for name in ("most_specific", "metrics_base"):
                df = ns[name]
                k = (df.Year.astype(int).astype(str) + "|" + df.State.astype(str).str.upper() + "|"
                     + df.Variable.astype(str) + "|"
                     + df.District.fillna("statewide").astype(str).replace({"nan": "statewide", "": "statewide"}))
                m = (df.Class == "Candidate Choice") & k.isin(keys)
                ns[name] = df[~m].copy()
                log.write(f"{name}: dropped {int(m.sum())} rows\n")
        log.flush()
    log.write("FINISHED\n"); log.close()

    # Overwrite in place (files in the repo folder may not be deletable).
    out = RESULTS / variant
    out.mkdir(parents=True, exist_ok=True)
    shutil.copy(wd / "output" / "prose_numbers.tex", out)
    for sub in ("main", "supplementary"):
        if (wd / "output" / sub).exists():
            (out / sub).mkdir(exist_ok=True)
            for t in (wd / "output" / sub).glob("*.tex"):
                shutil.copy(t, out / sub)
    shutil.copy(wd / "run.log", out)
    return variant


if __name__ == "__main__":
    todo = sys.argv[1:] or list(VARIANTS)
    # Build the pickle cache once before forking.
    SCRATCH.mkdir(parents=True, exist_ok=True)
    if not (SCRATCH / "data").is_symlink():
        (SCRATCH / "data").symlink_to(REPO / "data")
    cache = SCRATCH / "_cache"; cache.mkdir(exist_ok=True)
    for n in ("most_specific", "metrics_base"):
        pk = cache / f"{n}.pkl"
        if not pk.exists():
            pd.read_excel(REPO / "tables_and_figures" / "input_tables" / f"{n}.xlsx").to_pickle(pk)
    with mp.get_context("fork").Pool(int(os.environ.get("JOBS", 3))) as pool:
        for v in pool.imap_unordered(run, todo):
            print("done", v, flush=True)
