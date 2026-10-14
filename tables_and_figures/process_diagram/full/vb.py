"""Version B: calendar along the bottom, two lanes that meet after fieldwork."""
from lib import *

# Time segments (x ranges)
X_BEFORE = (0, 540)
X_PRE = (540, 860)
X_ED = 860
X_POST = (860, 1080)
X_AFTER = (1100, W)

LANE_T = (64, 426)      # target lane y range
LANE_R = (452, 960)     # respondent lane y range
AXIS_Y = 1010


def lane(y0, y1, title, sub):
    return "\n".join([
        rect(0, y0, X_POST[1], y1 - y0, "zone", rx=14),
        text(22, y0 + 34, title, "tl"),
        text(22, y0 + 60, sub, "ts"),
    ])


def frame_table(x, y):
    cols = [("Age", 42), ("Sex", 38), ("Race", 62), ("Educ.", 52), ("State", 50), ("Party", 60), ("Voted", 62)]
    rows = [["44", "F", "White", "BA", "OH", "Dem", "Yes"],
            ["67", "M", "White", "HS", "TX", "Rep", "Yes"],
            ["29", "F", "Hisp.", "Some", "CA", "Dem", "No"],
            ["52", "M", "Black", "HS", "GA", "Dem", "Yes"],
            ["…"] * 7]
    t, tw, th = table(x, y, cols, rows, row_h=29, shade_from=5)
    acs_w = sum(w for _, w in cols[:5])
    by = y - 12
    o = [t,
         path(f"M{x},{by + 6} L{x},{by} L{x + acs_w - 4},{by} L{x + acs_w - 4},{by + 6}", "rule-ink"),
         text(x + (acs_w - 4) / 2, by - 8, "From the ACS", "tn-ink", "middle"),
         path(f"M{x + acs_w + 4},{by + 6} L{x + acs_w + 4},{by} L{x + tw},{by} L{x + tw},{by + 6}", "rule-ink"),
         text(x + acs_w + (tw - acs_w) / 2 + 2, by - 8, "Attached", "tn-ink", "middle")]
    return "\n".join(o), tw, th


def build():
    o = [svg_open("Calendar view of the CES procedure. Before fieldwork, a sampling frame is built from the ACS "
                  "and a target sample is drawn; it is held while panelists are invited and interviewed in the "
                  "pre-election wave and re-interviewed after Election Day. After fieldwork, each target case is "
                  "matched to a completed interview, and the matched sample is weighted to the frame and then "
                  "post-stratified.")]

    # ---- lanes --------------------------------------------------------
    o.append(lane(*LANE_T, "TARGET SAMPLE", "Built from records; no one is contacted"))
    o.append(lane(*LANE_R, "RESPONDENTS", "Opt-in panelists who are invited and interviewed"))
    o.append(rect(X_AFTER[0], LANE_T[0], X_AFTER[1] - X_AFTER[0], LANE_R[1] - LANE_T[0], "zone", rx=14))
    o.append(text(X_AFTER[0] + 22, LANE_T[0] + 34, "SELECTION AND WEIGHTING", "tl"))

    # ---- target lane --------------------------------------------------
    t, tw, th = frame_table(22, 176)
    o.append(t)
    o.append(text(22, 176 + th + 30, "Sampling frame", "tsb"))
    o.append(text(22, 176 + th + 56, "Earlier ACS; CPS or Pew values attached", "tn"))
    gx, gy = 430, 140
    o.append(line(22 + tw + 6, 176 + th / 2, gx - 10, 176 + th / 2, "edge", arrow=True))
    for i in range(4):
        for j in range(6):
            o.append(ring(gx + 10 + i * 28, gy + 14 + j * 34, 9))
    o.append(text(gx, gy + 6 * 34 + 26, "Target sample", "tsb"))
    o.append(text(gx, gy + 6 * 34 + 52, '<tspan font-style="italic">N</tspan> cases, stratified', "tn"))
    # held through fieldwork
    hy = gy + 2.5 * 34 + 14
    o.append(line(gx + 4 * 28 + 6, hy, X_AFTER[0] + 66, hy, "ref", extra='marker-end="url(#ahm)"'))
    o.append(text((X_PRE[0] + X_POST[1]) / 2 + 30, hy - 14, "held unchanged until fieldwork ends", "tn", "middle"))

    # ---- respondent lane ---------------------------------------------
    r = rng(7)
    cx0, cy0 = 22, 560
    o.append(text(cx0, cy0 - 14, "YouGov panel", "tn-ink"))
    o.append(text(cx0 + 12 * 24 + 22, cy0 - 14, "Other panels", "tn-ink"))
    invited = []
    for i in range(18):
        for j in range(8):
            xx = cx0 + i * 24 + (22 if i >= 12 else 0)
            yy = cy0 + j * 36
            inv = r.random() < 0.4
            o.append(person(xx, yy, 16, "pp-inv" if inv else "pp"))
    ly = cy0 + 8 * 36 + 20
    o.append(person(cx0, ly - 21, 13, "pp-inv"))
    o.append(text(cx0 + 20, ly, "Invited", "tn"))
    o.append(person(cx0 + 96, ly - 21, 13, "pp"))
    o.append(text(cx0 + 116, ly, "Not invited", "tn"))
    o.append(text(cx0, ly + 30, "Invitations spread across demographic cells", "tn"))

    # completes accumulate through the pre-election wave
    base = 900
    weeks = 6
    wx0 = X_PRE[0] + 26
    step = (X_PRE[1] - X_PRE[0] - 40) / weeks
    o.append(line(X_PRE[0] - 34, 700, X_PRE[0] + 6, 700, "edge", arrow=True))
    heights = [2, 4, 6, 7, 8, 9]
    for k, hgt in enumerate(heights):
        for m in range(hgt):
            for c in range(2):
                o.append(person(wx0 + k * step + c * 20, base - (m + 1) * 34, 15, "pp-done"))
    o.append(text(X_PRE[0] + 20, 530, "Pre-election interviews", "tsb"))
    o.append(text(X_PRE[0] + 20, 556, "Completes accumulate", "tn"))

    # post-election wave: completers re-interviewed
    px0 = X_POST[0] + 24
    o.append(text(px0, 530, "Post-election", "tsb"))
    o.append(text(px0, 556, "All completers re-invited", "tn"))
    rr = rng(9)
    for i in range(5):
        for j in range(9):
            took = rr.random() < 0.72
            o.append(person(px0 + i * 30, 594 + j * 34, 15, "pp-done" if took else "pp-fade"))
    # pool to matching
    o.append(line(X_POST[1] + 2, 760, X_AFTER[0] + 66, 760, "edge", arrow=True))
    o.append(text(X_POST[1] + 6, 790, 'pool &gt; <tspan font-style="italic">N</tspan>', "tn"))

    # ---- after fieldwork ---------------------------------------------
    ax = X_AFTER[0]
    mx_l, mx_r = ax + 50, ax + 200
    o.append(text(ax + 22, 140, "Match", "tt"))
    o.append(lines(ax + 22, 172, ["Each target case paired with", "the closest interview"], "tn"))
    mt = {0: 0, 1: 1, 2: 3, 3: 4, 4: 6, 5: 7, 6: 9}
    TS, PS = 66, 46
    ty0 = 290
    for t in range(7):
        o.append(ring(mx_l, ty0 + t * TS, 10))
    for k in range(10):
        cls = "pp-mo" if k in mt.values() else "pp-fade"
        o.append(person(mx_r, ty0 - 16 + k * PS, 19, cls))
    for t, k in mt.items():
        y1 = ty0 + t * TS
        y2 = ty0 - 16 + k * PS + 17
        o.append(path(f"M{mx_l + 14},{y1} C{mx_l + 80},{y1} {mx_r - 70},{y2} {mx_r - 6},{y2}", "pair"))
    o.append(text(ax + 22, 790 + 40, "Matched sample", "tsb"))
    o.append(rect(ax + 22, 852, 262, 72, "chip", rx=10))
    o.append(rect(ax + 36, 874, 30, 26, "sw-mo", rx=3))
    o.append(text(ax + 78, 884, "Matching only", "tsb t-mo"))
    o.append(text(ax + 78, 908, "estimates, unweighted", "tn"))

    # steps 1 and 2 stacked on the right
    sx = ax + 300
    sw = X_AFTER[1] - sx - 22
    o.append(line(mx_r + 34, 280, sx - 12, 280, "edge", arrow=True))
    # Step 1
    o.append(text(sx, 140, "Step 1 · Weight to the frame", "tt"))
    o.append(lines(sx, 172, ["Propensity scores (2008–2012)", "or entropy balancing (2014–2022)"], "tn"))
    W8 = [0.78, 1.32, 0.92, 1.18, 0.66, 1.05, 1.45]
    cx = sx + 6
    for wgt in W8:
        o.append(person_c(cx + 16, 300, 21 * wgt, "pp-mo"))
        cx += 42
    o.append(line(sx, 304, sx + 7 * 42, 304, "rule"))
    o.append(text(sx, 330, "Weights shown as icon size", "tn"))
    for k, (lab, cur, tgt) in enumerate([("HS or less", 0.30, 0.38), ("BA", 0.27, 0.20)]):
        yy = 362 + k * 32
        o.append(text(sx, yy + 14, lab, "tn"))
        o.append(rect(sx + 128, yy, 200, 18, "bar-track", rx=3))
        o.append(rect(sx + 128, yy, 200 * cur * 2, 18, "bar-mo", rx=3))
        o.append(line(sx + 128 + 200 * tgt * 2, yy - 5, sx + 128 + 200 * tgt * 2, yy + 23, "tick"))
    o.append(text(sx, 446, "Tick: share in the frame", "tn"))
    # weighting-targets reference from the frame (top route)
    tx = 22 + tw
    o.append(f'<polyline class="ref" points="{tx + 2},{176 + 12} {tx + 16},{176 + 12} {tx + 16},40 {sx + 150},40 {sx + 150},104" marker-end="url(#ahm)"/>')
    o.append(text(760, 30, "the frame supplies the step 1 targets", "tn", "middle"))
    # Step 2
    o.append(line(sx + 150, 470, sx + 150, 506, "edge", arrow=True))
    o.append(text(sx, 548, "Step 2 · Post-stratify", "tt"))
    o.append(lines(sx, 580, ["Rake to demographic and political", "margins; trim and normalize"], "tn"))
    for k, (lab, cur, tgt) in enumerate([("Registered", 0.80, 0.74), ("Prior vote", 0.52, 0.58), ("Senate result", 0.56, 0.53)]):
        yy = 640 + k * 32
        o.append(text(sx, yy + 14, lab, "tn"))
        o.append(rect(sx + 128, yy, 200, 18, "bar-track", rx=3))
        o.append(rect(sx + 128, yy, 200 * cur, 18, "bar-mid", rx=3))
        o.append(line(sx + 128 + 200 * tgt, yy - 5, sx + 128 + 200 * tgt, yy + 23, "tick"))
    o.append(text(sx, 756, "Tick: target margin", "tn"))
    # Final
    cx = sx + 6
    for wgt in W8:
        o.append(person_c(cx + 16, 840, 21 * min(1.38, max(0.72, wgt * 1.04)), "pp-mw"))
        cx += 42
    o.append(rect(sx, 852, sw, 72, "chip", rx=10))
    o.append(rect(sx + 14, 874, 30, 26, "sw-mw", rx=3))
    o.append(text(sx + 56, 884, "Matching + weighting", "tsb t-mw"))
    o.append(text(sx + 56, 908, "estimates, final weights", "tn"))

    # ---- calendar axis ------------------------------------------------
    o.append(line(0, AXIS_Y, W, AXIS_Y, "rule-ink"))
    segs = [(X_BEFORE, "Before fieldwork", "months earlier"),
            (X_PRE, "Pre-election wave", "late Sept. to early Nov."),
            (X_POST, "Post-election wave", "to mid-Dec."),
            (X_AFTER, "After fieldwork", "")]
    for (a, b), t1, t2 in segs:
        o.append(line(a, AXIS_Y - 8, a, AXIS_Y + 8, "rule-ink"))
        o.append(text(a + 10, AXIS_Y + 34, t1, "tsb"))
        if t2:
            o.append(text(a + 10, AXIS_Y + 60, t2, "tn"))
    # Election Day line through both lanes
    o.append(line(X_ED, 470, X_ED, AXIS_Y + 8, "eday"))
    o.append(text(X_ED, AXIS_Y + 34, "", "tn"))
    o.append(f'<rect x="{X_ED - 62}" y="{LANE_R[0] + 14}" width="124" height="26" rx="13" class="chip"/>')
    o.append(text(X_ED, LANE_R[0] + 33, "Election Day", "t-eday", "middle"))
    o.append("</svg>")
    return "\n".join(o)
