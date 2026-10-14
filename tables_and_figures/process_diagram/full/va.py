"""Version A: an eight-panel plate read in time order, two rows of four."""
from lib import *

GUT = 24
PW = (W - 3 * GUT) / 4
RIB = 30
PH = (H - 2 * (RIB + 10) - GUT) / 2
PAD = 22


def panel_xy(i):
    r, c = divmod(i, 4)
    x = c * (PW + GUT)
    y = (RIB + 10) + r * (PH + GUT + RIB + 10)
    return x, y


def ribbon(y, x0, x1, label):
    return "\n".join([
        text(x0, y + 20, label, "tl"),
        line(x0 + len(label) * F_LANE * 0.74 + 14, y + 13, x1 - 2, y + 13, "edge-soft", extra='marker-end="url(#ahm)"'),
    ])


def header(x, y, n, title, sub):
    out = [rect(x, y, PW, PH, "panel", rx=14), badge(x + PAD + 14, y + PAD + 16, n),
           text(x + PAD + 40, y + PAD + 24, title, "tt")]
    out.append(lines(x + PAD, y + PAD + 64, sub, "ts"))
    return "\n".join(out)


def p1(x, y):
    o = [header(x, y, 1, "Build the sampling frame",
                ["Citizen records from an earlier ACS,", "with political variables attached"])]
    cols = [("Age", 44), ("Sex", 40), ("Race", 66), ("Educ.", 54), ("State", 52), ("Party", 64), ("Voted", 68)]
    rows = [["44", "F", "White", "BA", "OH", "Dem", "Yes"],
            ["67", "M", "White", "HS", "TX", "Rep", "Yes"],
            ["29", "F", "Hisp.", "Some", "CA", "Dem", "No"],
            ["52", "M", "Black", "HS", "GA", "Dem", "Yes"],
            ["38", "F", "Asian", "Post", "WA", "Ind", "Yes"],
            ["71", "F", "White", "Some", "PA", "Rep", "Yes"],
            ["…", "…", "…", "…", "…", "…", "…"]]
    tx, ty = x + PAD, y + 196
    t, tw, th = table(tx, ty, cols, rows, row_h=30, shade_from=5)
    o.append(t)
    acs_w = sum(w for _, w in cols[:5])
    # brackets above the table
    by = ty - 14
    o.append(path(f"M{tx},{by + 6} L{tx},{by} L{tx + acs_w - 4},{by} L{tx + acs_w - 4},{by + 6}", "rule-ink"))
    o.append(text(tx + (acs_w - 4) / 2, by - 8, "ACS record", "tn-ink", "middle"))
    o.append(path(f"M{tx + acs_w + 4},{by + 6} L{tx + acs_w + 4},{by} L{tx + tw},{by} L{tx + tw},{by + 6}", "rule-ink"))
    o.append(text(tx + acs_w + (tw - acs_w) / 2 + 2, by - 8, "Attached", "tn-ink", "middle"))
    o.append(lines(tx, ty + th + 34, ["Attached values come from similar", "respondents in the CPS or Pew surveys"], "tn"))
    return "\n".join(o)


def p2(x, y):
    o = [header(x, y, 2, "Draw the target sample",
                ["A stratified random sample of the frame.", "No one is contacted at this stage."])]
    r = rng(2)
    fx, fy = x + PAD, y + 182
    bw, bh = 214, 92
    o.append(text(fx, fy - 12, "Frame, by stratum", "tn-ink"))
    for s in range(3):
        by = fy + s * (bh + 8)
        o.append(rect(fx, by, bw, bh, "band" if s % 2 == 0 else "band2", rx=6))
        for i in range(9):
            for j in range(4):
                cx = fx + 16 + i * 23
                cy = by + 16 + j * 20
                sel = r.random() < 0.2
                o.append(f'<circle class="{"dot-sel" if sel else "dot"}" cx="{cx}" cy="{cy}" r="{5.2 if sel else 4.6}"/>')
    o.append(text(fx, fy + 3 * (bh + 8) + 18, "Circled records are drawn", "tn"))
    # target grid
    gx = fx + bw + 66
    o.append(line(fx + bw + 10, fy + 1.5 * (bh + 8), gx - 12, fy + 1.5 * (bh + 8), "edge", arrow=True))
    o.append(text(gx, fy - 12, "Target sample", "tn-ink"))
    for i in range(4):
        for j in range(7):
            o.append(ring(gx + 10 + i * 27, fy + 14 + j * 40))
    o.append(text(gx, fy + 3 * (bh + 8) + 18, '<tspan font-style="italic">N</tspan> cases', "tn"))
    return "\n".join(o)


def p3(x, y):
    o = [header(x, y, 3, "Invite panelists",
                ["Opt-in online panels. Invitations are", "spread across demographic cells"])]
    r = rng(3)
    gx, gy = x + PAD, y + 190
    o.append(text(gx, gy - 14, "YouGov panel", "tn-ink"))
    o.append(text(gx + 10 * 25 + 18, gy - 14, "Other panels", "tn-ink"))
    for i in range(15):
        for j in range(6):
            xx = gx + i * 25 + (18 if i >= 10 else 0)
            yy = gy + j * 36
            inv = r.random() < 0.42
            o.append(person(xx, yy, 17, "pp-inv" if inv else "pp"))
    ly = gy + 6 * 36 + 22
    o.append(person(gx, ly - 22, 13, "pp-inv"))
    o.append(text(gx + 20, ly, "Invited", "tn"))
    o.append(person(gx + 100, ly - 22, 13, "pp"))
    o.append(text(gx + 120, ly, "Not invited", "tn"))
    o.append(text(gx, ly + 32, "Other companies' panels were added from 2008", "tn"))
    return "\n".join(o)


def p4(x, y):
    o = [header(x, y, 4, "Field the questionnaires",
                ["Completers of the pre-election wave are", "re-invited after Election Day"])]
    lab_w = 118
    ax0, ax1 = x + PAD + lab_w, x + PW - PAD - 4
    ay = y + 290

    def dx(day):  # day 0 = Sep 1, through Dec 31
        return ax0 + (ax1 - ax0) * day / 121
    r1, r2 = ay - 92, ay - 52
    o.append(text(x + PAD, r1 + 16, "Pre-election", "tn-ink"))
    o.append(text(x + PAD, r2 + 16, "Post-election", "tn-ink"))
    o.append(rect(dx(28), r1, dx(68) - dx(28), 22, "wave", rx=4))
    o.append(rect(dx(70), r2, dx(105) - dx(70), 22, "wave2", rx=4))
    o.append(line(ax0, ay, ax1, ay, "rule-ink"))
    for d, m in [(0, "Sep"), (30, "Oct"), (61, "Nov"), (91, "Dec")]:
        o.append(line(dx(d), ay, dx(d), ay + 6, "rule-ink"))
        o.append(text(dx(d) + 4, ay + 26, m, "tn"))
    ed = dx(68.5)
    o.append(line(ed, r1 - 18, ed, ay, "eday"))
    o.append(text(ed, r1 - 26, "Election Day", "t-eday", "middle"))
    o.append(text(x + PAD, ay + 26, "2022", "tn"))
    ax0 = x + PAD + 6
    # pool of completed interviews
    py = ay + 64
    o.append(text(ax0, py + 6, "Completed pre-election interviews", "tn-ink"))
    for i in range(14):
        for j in range(2):
            o.append(person(ax0 + i * 26, py + 22 + j * 36, 17, "pp-done"))
    o.append(text(ax0, py + 22 + 2 * 36 + 18, "A pool larger than N (2022: 80,233)", "tn"))
    return "\n".join(o)


def p5(x, y):
    o = [header(x, y, 5, "Match each target case",
                ["Each target case is paired with the most", "similar completed interview"])]
    lx = x + PAD + 30
    rx = x + PW - PAD - 60
    ty = y + 186
    o.append(text(lx + 9, ty - 14, "Target", "tn-ink", "middle"))
    o.append(text(rx + 9, ty - 14, "Pool", "tn-ink", "middle"))
    pool_matched = {0: 0, 1: 2, 2: 3, 3: 5, 4: 6}
    TS, PS = 46, 32
    for t in range(5):
        o.append(ring(lx + 9, ty + 24 + t * TS, 10))
    for k in range(7):
        cls = "pp-mo" if k in pool_matched.values() else "pp-fade"
        o.append(person(rx, ty + 8 + k * PS, 18, cls))
    for t, k in pool_matched.items():
        y1 = ty + 24 + t * TS
        y2 = ty + 8 + k * PS + 16
        o.append(path(f"M{lx + 24},{y1} C{lx + 130},{y1} {rx - 110},{y2} {rx - 8},{y2}", "pair"))
    my = y + 446
    o.append(text(x + PW / 2, my, 'D(t, i) = <tspan font-style="normal">\u03a3</tspan><tspan baseline-shift="sub" font-size="72%">k</tspan> w<tspan baseline-shift="sub" font-size="72%">k</tspan> d<tspan baseline-shift="sub" font-size="72%">k</tspan>(t<tspan baseline-shift="sub" font-size="72%">k</tspan>, i<tspan baseline-shift="sub" font-size="72%">k</tspan>)', "t-math", "middle"))
    o.append(text(x + PAD, my + 38, "Unpaired interviews are dropped", "tn"))
    return "\n".join(o)


WEIGHTS = [0.78, 1.32, 0.92, 1.18, 0.66, 1.05, 1.45, 0.86]


def bars(x, y, w, cur, tgt, label, cls="bar-mo", lw=124):
    o = [text(x, y + 14, label, "tn")]
    bx = x + lw
    o.append(rect(bx, y, w, 18, "bar-track", rx=3))
    o.append(rect(bx, y, w * cur, 18, cls, rx=3))
    o.append(line(bx + w * tgt, y - 5, bx + w * tgt, y + 23, "tick"))
    return "\n".join(o)


def p6(x, y):
    o = [header(x, y, 6, "Weight to the frame",
                ["Step 1. Propensity scores (2008–2012) or", "entropy balancing (2014–2022)"])]
    gx, base = x + PAD + 8, y + 250
    cx = gx
    for wgt in WEIGHTS:
        s = 22 * wgt
        o.append(person_c(cx + 18, base, s, "pp-mo"))
        cx += 46
    o.append(line(gx, base + 4, gx + 46 * 8 - 10, base + 4, "rule"))
    o.append(text(gx, base + 30, "Each respondent gets a weight (icon size)", "tn"))
    by = base + 74
    o.append(text(gx, by, "Share by education group", "tn-ink"))
    sh = [("HS or less", 0.30, 0.38), ("Some college", 0.30, 0.30), ("BA", 0.27, 0.20), ("Postgrad", 0.13, 0.12)]
    for k, (lab, cur, tgt) in enumerate(sh):
        o.append(bars(gx, by + 20 + k * 34, 230, cur * 2.2, tgt * 2.2, lab))
    ly = by + 20 + 4 * 34 + 14
    o.append(rect(gx, ly - 13, 26, 16, "bar-mo", rx=2))
    o.append(text(gx + 34, ly, "Matched sample", "tn"))
    o.append(line(gx + 196, ly - 16, gx + 196, ly + 6, "tick"))
    o.append(text(gx + 208, ly, "Frame share", "tn"))
    return "\n".join(o)


def p7(x, y):
    o = [header(x, y, 7, "Post-stratify",
                ["Step 2. Rake to demographic and political", "margins, then trim and normalize"])]
    gx = x + PAD + 8
    by = y + 196
    o.append(text(gx, by, "Share after step 1, by margin", "tn-ink"))
    ms = [("Age 18–29", 0.62, 0.70), ("Registered", 0.80, 0.74), ("Prior vote", 0.52, 0.58),
          ("Gov. result", 0.47, 0.51), ("Senate result", 0.56, 0.53)]
    for k, (lab, cur, tgt) in enumerate(ms):
        yy = by + 20 + k * 36
        o.append(bars(gx, yy, 230, cur, tgt, lab, "bar-mid"))
    ly = by + 20 + 5 * 36 + 14
    o.append(rect(gx, ly - 13, 26, 16, "bar-mid", rx=2))
    o.append(text(gx + 34, ly, "Frame-weighted", "tn"))
    o.append(line(gx + 196, ly - 16, gx + 196, ly + 6, "tick"))
    o.append(text(gx + 208, ly, "Target margin", "tn"))
    o.append(text(gx, ly + 34, "Election results used from 2014 on", "tn"))
    return "\n".join(o)


def p8(x, y):
    o = [header(x, y, 8, "Release the data",
                ["The matched sample and its final weights,", "the two versions this paper compares"])]
    gx, base = x + PAD + 8, y + 250
    cx = gx
    for wgt in WEIGHTS:
        s = 22 * min(1.38, max(0.72, wgt * 1.04))
        o.append(person_c(cx + 18, base, s, "pp-mw"))
        cx += 46
    o.append(line(gx, base + 4, gx + 46 * 8 - 10, base + 4, "rule"))
    o.append(text(gx, base + 30, "Final weighted sample", "tn-ink"))
    cy = base + 70
    for k, (sw, t1, t2) in enumerate([("sw-mo", "Matching only", "matched sample, unweighted"),
                                      ("sw-mw", "Matching + weighting", "matched sample, final weights")]):
        yy = cy + k * 74
        o.append(rect(gx, yy, PW - 2 * PAD - 16, 60, "chip", rx=10))
        o.append(rect(gx + 14, yy + 18, 34, 24, sw, rx=3))
        o.append(text(gx + 62, yy + 26, t1, "tsb t-mo" if k == 0 else "tsb t-mw"))
        o.append(text(gx + 62, yy + 48, t2, "tn"))
    return "\n".join(o)


def build():
    o = [svg_open("Eight-panel plate showing the CES procedure in time order: build the sampling frame, "
                  "draw the target sample, invite panelists, field the questionnaires, match each target case, "
                  "weight to the frame, post-stratify, and release the matched sample with its final weights.")]
    _, y0 = panel_xy(0)
    o.append(ribbon(y0 - RIB - 10, 0, 2 * PW + GUT, "BEFORE FIELDWORK"))
    o.append(ribbon(y0 - RIB - 10, 2 * PW + 2 * GUT, W, "FIELDWORK · FALL OF THE ELECTION YEAR"))
    _, y4 = panel_xy(4)
    o.append(ribbon(y4 - RIB - 10, 0, W, "AFTER FIELDWORK"))
    for i, f in enumerate([p1, p2, p3, p4, p5, p6, p7, p8]):
        x, y = panel_xy(i)
        o.append(f(x, y))
    o.append("</svg>")
    return "\n".join(o)
