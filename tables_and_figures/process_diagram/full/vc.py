"""Version C: follow one set of people from the panel to the released file."""
from lib import *

BAND_Y = (330, 860)          # vertical extent of the respondent stream
MID = sum(BAND_Y) / 2


def grid(x, cy, cols, rows, sx, sy, icon, cls_fn):
    """Icons in a grid centred vertically on cy; returns svg and bbox."""
    h = (rows - 1) * sy + icon * 1.6
    y0 = cy - h / 2
    o = []
    k = 0
    for j in range(rows):
        for i in range(cols):
            o.append(person(x + i * sx, y0 + j * sy, icon, cls_fn(k)))
            k += 1
    return "\n".join(o), (x, y0, x + (cols - 1) * sx + icon, y0 + h)


def ribbon_seg(x0, x1, y, label):
    return "\n".join([line(x0 + 2, y, x1 - 8, y, "rule"),
                      line(x0 + 2, y - 7, x0 + 2, y + 7, "rule-ink"),
                      text(x0 + 12, y - 12, label, "tl")])


def flow(b1, b2):
    """Soft band joining two column bounding boxes."""
    x1, y1a, y1b = b1[2] + 14, b1[1], b1[3]
    x2, y2a, y2b = b2[0] - 14, b2[1], b2[3]
    k = (x2 - x1) * 0.5
    return (f'<path class="band" d="M{x1},{y1a} C{x1 + k},{y1a} {x2 - k},{y2a} {x2},{y2a} '
            f'L{x2},{y2b} C{x2 - k},{y2b} {x1 + k},{y1b} {x1},{y1b} Z"/>')


def label(x, y, title, rows, cls="tsb"):
    o = [text(x, y, title, cls)]
    for i, r in enumerate(rows):
        o.append(text(x, y + 26 + i * 24, r, "tn"))
    return "\n".join(o)


W8 = [0.78, 1.32, 0.92, 1.18, 0.66, 1.05, 1.45, 0.86, 1.12, 0.74, 1.25, 0.95,
      1.02, 0.7, 1.36, 0.88, 1.08, 0.8, 1.2, 0.97, 0.69, 1.3, 1.0, 0.9]


def build():
    o = [svg_open("Schematic that follows one set of people through the CES procedure: many panelists, fewer invited, "
                  "fewer completing the pre-election interview, then a matched sample paired one to one with the "
                  "target cases drawn from the frame, then the same people reweighted to the frame and post-stratified.")]
    r = rng(11)

    # ---- chronology ribbon -------------------------------------------
    ry = 40
    o.append(ribbon_seg(0, 380, ry, "BEFORE FIELDWORK"))
    o.append(ribbon_seg(380, 1010, ry, "FIELDWORK"))
    o.append(ribbon_seg(1010, W, ry, "AFTER FIELDWORK"))

    # ---- target track (top) ------------------------------------------
    fx, fy = 22, 104
    for i in range(8):
        for j in range(5):
            o.append(f'<circle class="dot" cx="{fx + 8 + i * 19}" cy="{fy + 8 + j * 19}" r="4.4"/>')
    o.append(label(fx, fy + 5 * 19 + 30, "Sampling frame", ["ACS records with", "political variables"]))
    tx0 = 214
    o.append(line(fx + 8 * 19 + 4, fy + 46, tx0 - 10, fy + 46, "edge", arrow=True))
    for i in range(6):
        for j in range(4):
            o.append(ring(tx0 + 10 + i * 26, fy + 8 + j * 25, 8))
    o.append(label(tx0, fy + 5 * 19 + 30, "Target sample", ['<tspan font-style="italic">N</tspan> cases, drawn', "by stratum"]))

    # ---- respondent stream -------------------------------------------
    cols = []
    # reservoir
    svg0, b0 = grid(22, MID, 10, 13, 25, 39, 16, lambda k: "pp-inv" if r.random() < 0.46 else "pp")
    o.append(svg0); cols.append(b0)
    # invited
    svg1, b1 = grid(400, MID, 6, 9, 26, 40, 17, lambda k: "pp-inv")
    cols.append(b1)
    # completed (pre-election)
    svg2, b2 = grid(660, MID, 4, 8, 27, 42, 18, lambda k: "pp-done")
    cols.append(b2)
    # matched: 24 pairs, ring + person
    mx = 1060
    pairs = []
    py0 = MID - (7 * 44 + 30) / 2
    for c in range(3):
        for j in range(8):
            x = mx + c * 66
            y = py0 + j * 44
            pairs.append(ring(x + 8, y + 16, 7.5))
            pairs.append(line(x + 16, y + 16, x + 26, y + 16, "pair"))
            pairs.append(person(x + 28, y, 18, "pp-mo"))
    b3 = (mx, py0, mx + 2 * 66 + 46, py0 + 7 * 44 + 30)
    cols.append(b3)
    # step 1: same people, sized by weight
    s1x = 1340
    s1 = []
    for k, wgt in enumerate(W8):
        c, j = divmod(k, 8)
        s1.append(person_c(s1x + 14 + c * 46, py0 + 30 + j * 44, 19 * wgt, "pp-mo"))
    b4 = (s1x, py0 - 4, s1x + 2 * 46 + 30, py0 + 7 * 44 + 30)
    cols.append(b4)
    # final
    s2x = 1600
    s2 = []
    for k, wgt in enumerate(W8):
        c, j = divmod(k, 8)
        w2 = min(1.38, max(0.72, wgt * 1.04 + (0.08 if k % 5 == 0 else -0.03)))
        s2.append(person_c(s2x + 14 + c * 46, py0 + 30 + j * 44, 19 * w2, "pp-mw"))
    b5 = (s2x, py0 - 4, s2x + 2 * 46 + 30, py0 + 7 * 44 + 30)
    cols.append(b5)

    for a, b in zip(cols[:-1], cols[1:]):
        o.append(flow(a, b))
    o.append(svg1); o.append(svg2); o.extend(pairs); o.extend(s1); o.extend(s2)

    # target cases drop into the matched column
    o.append(f'<path class="ref" d="M{tx0 + 6 * 26 + 6},{fy + 46} L{mx + 88},{fy + 46} L{mx + 88},{py0 - 22}" marker-end="url(#ahm)"/>')
    o.append(text((tx0 + 6 * 26 + mx + 88) / 2 + 40, fy + 34, "held until fieldwork ends, then matched", "tn", "middle"))
    # frame supplies targets for step 1
    o.append(f'<path class="ref" d="M{fx + 4 * 19},{fy - 6} L{fx + 4 * 19},{ry + 26} L{s1x + 60},{ry + 26} L{s1x + 60},{py0 - 22}" marker-end="url(#ahm)"/>')
    o.append(text(s1x + 52, ry + 50, "frame supplies step 1 targets", "tn", "end"))

    # Election Day between pre-election completes and selection
    ed = 900
    o.append(line(ed, BAND_Y[0] - 40, ed, BAND_Y[1] + 30, "eday"))
    o.append(text(ed, BAND_Y[0] - 50, "Election Day", "t-eday", "middle"))

    # ---- column labels -------------------------------------------------
    ly = 940
    o.append(label(22, ly, "Panel reservoir", ["YouGov and other opt-in panels"]))
    o.append(label(400, ly, "Invited", ["Spread across", "demographic cells"]))
    o.append(label(660, ly, "Completed", ["Pre-election interviews,", 'a pool larger than <tspan font-style="italic">N</tspan>']))
    o.append(label(mx, ly, "Matched", ["Each target case paired", "with its nearest interview"]))
    o.append(label(s1x, ly, "Weighted to frame", ["Step 1; icon size", "shows the weight"]))
    o.append(label(s2x, ly, "Post-stratified", ["Step 2; final", "released weights"]))
    # counts (2022)
    o.append(text(660, ly + 84, "2022: 80,233", "tn-ink"))
    o.append(text(mx, ly + 84, "2022: 60,000", "tn-ink"))

    # estimates the paper compares
    ey = BAND_Y[1] + 10
    for x, sw, t1 in [(mx, "sw-mo", "Matching only"), (W - 268, "sw-mw", "Matching + weighting")]:
        o.append(rect(x, ey - 14, 24, 18, sw, rx=3))
        o.append(text(x + 32, ey, t1, "tsb " + ("t-mo" if sw == "sw-mo" else "t-mw")))
    o.append("</svg>")
    return "\n".join(o)
