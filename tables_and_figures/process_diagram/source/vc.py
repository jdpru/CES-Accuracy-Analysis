"""Version C: follow one set of people from the panel to the released file."""
from lib import *

LEGEND_BG = True              # estimate colors on the panel background instead of the people
STYLE = "cube"               # matching section: cube | pairs | threads | slots | distance
BAND_Y = (410, 890)          # vertical extent of the respondent stream
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
# widen the spread a little so the weights read clearly as icon size (about 0.6x to 1.45x)
W8 = [min(1.45, max(0.62, 1 + (w - 1) * 1.35)) for w in W8]


def build():
    o = [svg_open("Schematic that follows one set of people through the CES procedure: many panelists, fewer invited, "
                  "fewer completing the pre-election interview, then a matched sample paired one to one with the "
                  "target cases drawn from the frame, then the same people reweighted to the frame and post-stratified.", h=980)]
    r = rng(11)

    # ---- chronology ribbon -------------------------------------------
    ry = 24

    # ---- target track (top) ------------------------------------------
    # The frame as a stack of layers: each layer is one variable, each dot
    # position one record. ACS variables in front, attached variables behind.
    fx, fy = 22, 140                         # fy - 40 is the title baseline
    COLS, ROWS, SP, MG = 10, 6, 14, 7
    CW, CH = 2 * MG + (COLS - 1) * SP, 2 * MG + (ROWS - 1) * SP
    LAYERS = ["dot"] * 4 + ["dot-att1", "dot-att2", "dot-att3"]
    LDX, LDY = 13, -11
    x0, y0 = fx, fy + 50                      # front card top-left
    rs = rng(5)
    picked = set(rs.sample(range(COLS * ROWS), 24))
    for k in reversed(range(len(LAYERS))):
        cx0, cy0 = x0 + k * LDX, y0 + k * LDY
        o.append(rect(cx0, cy0, CW, CH, "card", rx=4))
        for r_ in range(ROWS):
            for c_ in range(COLS):
                cls = LAYERS[k]
                if k == 0 and r_ * COLS + c_ in picked:
                    cls = "dot-pick"
                o.append(f'<circle class="{cls}" cx="{cx0 + MG + c_ * SP}" cy="{cy0 + MG + r_ * SP}" r="3.6"/>')
    nL = len(LAYERS) - 1
    stack_r = x0 + CW + nL * LDX
    back_top = y0 + nL * LDY
    frame_r = stack_r
    frame_mid = y0 + CH / 2
    o.append(text(fx, fy - 40, "Sampling frame", "tsb"))
    # legend
    lg = y0 + CH + 30
    o.append(f'<circle class="dot" cx="{fx + 6}" cy="{lg - 6}" r="4.4"/>')
    o.append(text(fx + 48, lg, "ACS variables", "tn"))
    for q, c in enumerate(["dot-att1", "dot-att2", "dot-att3"]):
        o.append(f'<circle class="{c}" cx="{fx + 6 + q * 13}" cy="{lg + 18}" r="4.4"/>')
    o.append(text(fx + 48, lg + 24, "Variables attached from other surveys", "tn"))
    o.append(f'<circle class="dot-pick" cx="{fx + 6}" cy="{lg + 42}" r="4.4"/>')
    o.append(text(fx + 48, lg + 48, "Records sampled into the target sample", "tn"))
    tx0 = stack_r + 66
    o.append(line(stack_r + 10, frame_mid, tx0 - 10, frame_mid, "edge", arrow=True))
    for i in range(6):
        for j in range(4):
            o.append(ring(tx0 + 10 + i * 26, frame_mid - 37.5 + j * 25, 8))
    o.append(text(tx0, fy - 40, "Target sample", "tsb"))
    o.append(text(tx0, fy - 16, "Drawn by stratum", "tn"))

    # ---- respondent stream -------------------------------------------
    cols = []
    # reservoir
    inv_fn = lambda k: "pp-inv" if r.random() < 0.46 else "pp"
    svg0a, b0a = grid(22, MID, 5, 12, 25, 39, 16, inv_fn)
    ox = b0a[2] + 30
    svg0b, b0b = grid(ox, MID, 4, 12, 25, 39, 16, inv_fn)
    o.append(svg0a); o.append(svg0b)
    o.append(text((b0a[0] + b0a[2]) / 2, b0a[1] - 16, "YouGov", "tn-ink", "middle"))
    o.append(text((b0b[0] + b0b[2]) / 2, b0a[1] - 16, "Other panels", "tn-ink", "middle"))
    o.append(line(ox - 16, b0a[1] - 4, ox - 16, b0a[3], "rule"))
    b0 = (22, b0a[1], b0b[2], b0a[3])
    cols.append(b0)
    # invited
    svg1, b1 = grid(365, MID, 6, 9, 26, 40, 17, lambda k: "pp-inv")
    cols.append(b1)
    # completed (pre-election)
    rm = rng(31)
    matched_idx = sorted(rm.sample(range(32), 24))
    mset = set(matched_idx)
    comp_fn = (lambda k: "pp-done" if k in mset else "pp-fade") if STYLE == "threads" else (lambda k: "pp-done")
    svg2, b2 = grid(615, MID, 4, 8, 27, 42, 18, comp_fn)
    cols.append(b2)
    cy0 = b2[1]
    py0 = MID - (7 * 44 + 30) / 2
    pairs = []
    drop_end = py0 - 22
    SP = 52                        # icon spacing within the last three columns
    CWD = 2 * SP + 30              # width of each of those columns
    GAPW = 128                     # gap between them (holds the weighting arrows)
    s2x = W - 200                  # leaves room for the left-aligned step 2 label
    s1x = s2x - GAPW - CWD
    mx = {"pairs": 1060, "slots": 1060}.get(STYLE, s1x - GAPW - CWD)
    drop_x = mx + 88
    if STYLE == "pairs":
        for c in range(3):
            for j in range(8):
                x = mx + c * 66
                y = py0 + j * 44
                pairs.append(ring(x + 8, y + 16, 7.5))
                pairs.append(line(x + 16, y + 16, x + 26, y + 16, "pair"))
                pairs.append(person(x + 28, y, 18, "pp-mo"))
        b3 = (mx, py0, mx + 2 * 66 + 46, py0 + 7 * 44 + 30)
    elif STYLE == "slots":
        for c in range(3):
            for j in range(8):
                cx, cy = mx + 20 + c * 62, py0 + 16 + j * 44
                pairs.append(ring(cx, cy, 17))
                pairs.append(person(cx - 7.5, cy - 13, 15, "pp-mo"))
        b3 = (mx, py0 - 4, mx + 2 * 62 + 40, py0 + 7 * 44 + 36)
    else:
        for c in range(3):
            for j in range(8):
                pairs.append(person(mx + 10 + c * SP, py0 + j * 44, 18, "pp-done" if LEGEND_BG else "pp-mo"))
        b3 = (mx, py0 - 4, mx + CWD, py0 + 7 * 44 + 30)
    if STYLE == "threads":
        # target cases wait in two staggered columns; each is joined to the completed interview it is matched to
        rx0 = 952
        drop_x = rx0 + 15
        RSP = 27
        ry0 = MID - 11.5 * RSP / 2 - 6
        ring_pos = sorted([(rx0 + c * 30, ry0 + j * RSP + c * RSP / 2) for j in range(12) for c in range(2)], key=lambda t: t[1])
        comp_pos = []
        for k in matched_idx:
            jj, ii = divmod(k, 4)
            comp_pos.append((b2[2] + 6, cy0 + jj * 42 + 15 + (ii - 1.5) * 4))
        for (x1, y1), (x2, y2) in zip(comp_pos, ring_pos):
            kx = (x2 - x1) * 0.5
            pairs.append(f'<path class="thread" d="M{x1},{y1} C{x1 + kx},{y1} {x2 - kx},{y2} {x2 - 9},{y2}"/>')
        for (x2, y2) in ring_pos:
            pairs.append(ring(x2, y2, 7.5))
    if STYLE == "distance":
        px, py, pw = 884, MID - 118, 196
        pairs.append(rect(px, py, pw, pw, "inset", rx=10))
        pairs.append(text(px + 12, py + 26, "Matching variables", "tn-ink"))
        ax0, ay0 = px + 22, py + pw - 22
        pairs.append(line(ax0, ay0, px + pw - 14, ay0, "rule-ink"))
        pairs.append(line(ax0, ay0, ax0, py + 44, "rule-ink"))
        pairs.append(text(px + pw - 14, ay0 + 22, "e.g., age", "tn", "end"))
        pairs.append(f'<text class="tn" x="{ax0 - 8}" y="{py + 48}" text-anchor="end" transform="rotate(-90 {ax0 - 8} {py + 48})">e.g., education</text>')
        rr = rng(41)
        resp = [(ax0 + 14 + rr.random() * (pw - 56), py + 52 + rr.random() * (pw - 92)) for _ in range(11)]
        tg = [(ax0 + 14 + rr.random() * (pw - 56), py + 52 + rr.random() * (pw - 92)) for _ in range(6)]
        used = set()
        for (tx, ty) in tg:
            best = min((q for q in range(len(resp)) if q not in used), key=lambda q: (resp[q][0] - tx) ** 2 + (resp[q][1] - ty) ** 2)
            used.add(best)
            pairs.append(line(tx, ty, resp[best][0], resp[best][1], "pair"))
        for q, (x, y) in enumerate(resp):
            pairs.append(f'<circle class="{"dot-mo" if q in used else "dot-fade"}" cx="{x:.1f}" cy="{y:.1f}" r="5"/>')
        for (tx, ty) in tg:
            pairs.append(ring(tx, ty, 6.5))
    if STYLE == "cube":
        # Three matching variables as a cube; target cases and completed interviews as points.
        S, DXd, DYd = 172, 74, -58
        x0c, y0c = 792, MID - (172 - 58) / 2

        def P(u, v, w):
            return (x0c + u * S + w * DXd, y0c + S - v * S + w * DYd)
        hull = [P(0, 0, 0), P(1, 0, 0), P(1, 0, 1), P(1, 1, 1), P(0, 1, 1), P(0, 1, 0)]
        pairs.append('<polygon class="cube-fill" points="' + " ".join(f"{x:.1f},{y:.1f}" for x, y in hull) + '"/>')
        for a, b in [((0, 0, 1), (1, 0, 1)), ((0, 0, 1), (0, 1, 1)), ((0, 0, 0), (0, 0, 1))]:
            pairs.append(line(*P(*a), *P(*b), "cube-back"))
        vis = [((0, 0, 0), (1, 0, 0)), ((1, 0, 0), (1, 1, 0)), ((1, 1, 0), (0, 1, 0)), ((0, 1, 0), (0, 0, 0)),
               ((1, 0, 0), (1, 0, 1)), ((1, 1, 0), (1, 1, 1)), ((0, 1, 0), (0, 1, 1)),
               ((1, 0, 1), (1, 1, 1)), ((0, 1, 1), (1, 1, 1))]
        for a, b in vis:
            pairs.append(line(*P(*a), *P(*b), "cube-edge"))
        # axis labels
        bx, byy = P(0.5, 0, 0)
        pairs.append(text(bx, byy + 26, "e.g., age", "tn", "middle"))
        lx_, ly_ = P(0, 0.5, 0)
        pairs.append(f'<text class="tn" x="{lx_ - 12:.1f}" y="{ly_:.1f}" text-anchor="middle" transform="rotate(-90 {lx_ - 12:.1f} {ly_:.1f})">e.g., education</text>')
        dx_, dy_ = P(1, 0, 0.5)
        pairs.append(f'<text class="tn" x="{dx_ + 14:.1f}" y="{dy_ + 18:.1f}" text-anchor="middle" transform="rotate(-36.9 {dx_ + 14:.1f} {dy_ + 18:.1f})">e.g., religion</text>')
        # points
        rc = rng(57)
        pts = []
        for _ in range(15):
            pts.append(("resp", (0.08 + rc.random() * 0.84, 0.08 + rc.random() * 0.84, 0.08 + rc.random() * 0.84)))
        for _ in range(3):
            pts.append(("tgt", (0.1 + rc.random() * 0.8, 0.1 + rc.random() * 0.8, 0.1 + rc.random() * 0.8)))
        hi = [(0.18, 0.72, 0.3), (0.55, 0.3, 0.45), (0.8, 0.74, 0.62)]
        hi_resp = [(u + 0.07, v - 0.06, w + 0.04) for u, v, w in hi]
        pts = [p_ for p_ in pts if min(sum((p_[1][d] - h[d]) ** 2 for d in range(3)) for h in hi) > 0.045]
        for t in hi:
            pts.append(("tgt", t))
        for q in hi_resp:
            pts.append(("hit", q))
        halos = []
        for t, q in zip(hi, hi_resp):
            (x1, y1), (x2, y2) = P(*t), P(*q)
            halos.append(((x1 + x2) / 2, (y1 + y2) / 2))
            pairs.append(f'<circle class="halo" cx="{(x1 + x2) / 2:.1f}" cy="{(y1 + y2) / 2:.1f}" r="19"/>')
        for kind, (u, v, w) in sorted(pts, key=lambda t: -t[1][2]):
            x, y = P(u, v, w)
            if kind == "tgt":
                pairs.append(ring(x, y, round(7.6 - 1.8 * w, 1)))
            else:
                pairs.append(f'<circle class="{"dot-mo" if kind == "hit" else "dot-done"}" cx="{x:.1f}" cy="{y:.1f}" r="{6.2 - 1.6 * w:.1f}"/>')
        for t, q in zip(hi, hi_resp):
            (x1, y1), (x2, y2) = P(*t), P(*q)
            pairs.append(line(x1, y1, x2, y2, "pair-strong"))
        # direct label for the closest pairs
        # the held target sample lands on one target case in the cube
        tgt_x, tgt_y = P(*hi[2])
        drop_x, drop_end = tgt_x, tgt_y - 10
        lab_y = P(0, 1, 1)[1] - 16
        lab_x = drop_x - 14 - 128          # label sits left of the drop line
        pairs.append(text(drop_x - 14, lab_y, "Matched cases", "tn-ink t-mo", "end"))
        import math
        for (hx, hy) in halos:
            ox, oy = lab_x + 62, lab_y + 6
            d = math.hypot(hx - ox, hy - oy)
            pairs.append(line(ox, oy, hx - (hx - ox) * 19 / d, hy - (hy - oy) * 19 / d, "leader"))
        # key
        ky = py0 + 7 * 44 + 30 + 30          # below the gray band, with breathing room
        kx = x0c
        pairs.append(ring(kx + 6, ky - 6, 5))
        pairs.append(text(kx + 20, ky, "Target case", "tn"))
        pairs.append(f'<circle class="dot-done" cx="{kx + 6}" cy="{ky + 22}" r="6"/>')
        pairs.append(text(kx + 20, ky + 28, "Completed interview", "tn"))
        b3 = (mx, py0 - 4, mx + CWD, py0 + 7 * 44 + 30)
    cols.append(b3)
    # step 1: same people, sized by weight
    s1 = []
    for k, wgt in enumerate(W8):
        c, j = divmod(k, 8)
        s1.append(person_c(s1x + 14 + c * SP, py0 + 30 + j * 44, 17 * wgt, "pp-done" if LEGEND_BG else "pp-mo"))
    b4 = (s1x, py0 - 4, s1x + CWD, py0 + 7 * 44 + 30)
    cols.append(b4)
    # final
    ra = rng(77)
    ADJ2 = [0.7 + ra.random() * 0.65 for _ in range(24)]   # per-person post-stratification factor, 0.70-1.35
    s2 = []
    for k, wgt in enumerate(W8):
        c, j = divmod(k, 8)
        # step 2 rescales each step 1 weight (post-stratification adjusts, it doesn't start over)
        w2 = min(1.45, max(0.62, wgt * ADJ2[k]))
        s2.append(person_c(s2x + 14 + c * SP, py0 + 30 + j * 44, 17 * w2, "pp-mw"))
    b5 = (s2x, py0 - 4, s2x + CWD, py0 + 7 * 44 + 30)
    cols.append(b5)

    for a, b in zip(cols[:-1], cols[1:]):
        o.append(flow(a, b))
    if LEGEND_BG:
        for b, cls in [(b3, "panel-mo"), (b5, "panel-mw")]:
            o.append(rect(b[0] - 14, b[1] - 16, b[2] - b[0] + 28, b[3] - b[1] + 30, cls, rx=12))
    o.append(svg1); o.append(svg2); o.extend(pairs); o.extend(s1); o.extend(s2)

    # target cases drop into the matched column
    o.append(f'<path class="ref" d="M{tx0 + 6 * 26 + 6},{frame_mid} L{drop_x},{frame_mid} L{drop_x},{drop_end}" marker-end="url(#ahm)"/>')
    o.append(text((tx0 + 6 * 26 + drop_x) / 2 + 40, frame_mid - 12, "held until fieldwork ends, then matched", "tn", "middle"))
    # frame supplies targets for step 1
    # labelled arrows across the two weighting gaps
    gaps = [((b3[2], b4[0]), ["Frame", "weighting"]), ((b4[2], b5[0]), [None, "Post-strat."])]
    gcs = []
    for (ga, gb), lab in gaps:
        gc = (ga + gb) / 2
        gcs.append(gc)
        o.append(line(ga + 16, MID + 14, gb - 16, MID + 14, "edge", arrow=True))
        if lab[0]:
            o.append(text(gc, MID - 32, lab[0], "tn-ink", "middle"))
        o.append(text(gc, MID - 8, lab[1], "tn-ink", "middle"))
    o.append(f'<path class="ref" d="M{stack_r - 12},{back_top - 4} L{stack_r - 12},{ry + 26} L{gcs[0]},{ry + 26} L{gcs[0]},{MID - 56}" marker-end="url(#ahm)"/>')
    o.append(text(gcs[0] - 8, ry + 50, "weighting step 1 makes the matched sample resemble the sampling frame", "tn", "end"))

    # Election Day between pre-election completes and selection
    ed = 748 if STYLE == "cube" else 860
    o.append(line(ed, BAND_Y[0] - 10, ed, BAND_Y[1] + 4, "eday"))
    o.append(text(ed, BAND_Y[0] - 22, "Election Day", "t-eday", "middle"))

    # ---- column labels, centred directly under each column ------------
    G = 40

    def col_label(b, rows):
        # titles (bold) centred under the column; the subtext is a left-aligned block centred under it
        cx = (b[0] + b[2]) / 2
        y = b[3] + G
        subs = [t for t, cls in rows if cls != "tsb"]
        sx = cx - max((text_width(t, "tn") for t in subs), default=0) / 2
        for t, cls in rows:
            if cls == "tsb":
                o.append(text(cx, y, t, cls, "middle"))
                y += 26
            else:
                o.append(text(cx, y, t, cls, "middle"))   # one alignment for the whole label
                y += 24
    col_label(b0, [("Panel reservoir", "tsb"), ("Opt-in online panels", "tn")])
    col_label(b1, [("Invited", "tsb")])
    col_label(b2, [("Completed", "tsb")])
    col_label(b3, [("Matched", "tsb"), ("Closest respondent", "tn"), ("to each target case", "tn")])
    col_label(b4, [("Weighting step 1:", "tsb"), ("Frame weighting", "tsb"), ("Via propensity scores", "tn"), ("or entropy balancing", "tn")])
    col_label(b5, [("Weighting step 2:", "tsb"), ("Post-stratification", "tsb"), ("To demographic and", "tn"), ("political margins", "tn")])

    # estimates the paper compares
    l2 = py0 - (37 if LEGEND_BG else 30)          # second line; labels sit above the columns they mark
    l1 = l2 - 24
    for b, sw, t1, t2 in [(b3, "sw-mo", None, "Matching only"), (b5, "sw-mw", "Matching +", "weighting")]:
        tw = max(text_width(t1 or "", "tsb"), text_width(t2, "tsb"))
        cls = "tsb " + ("t-mo" if sw == "sw-mo" else "t-mw")
        if LEGEND_BG:                  # the panel itself carries the color, so no swatch; lines centred on the panel
            cxp = (b[0] + b[2]) / 2
            if t1:
                o.append(text(cxp, l1, t1, cls, "middle"))
            o.append(text(cxp, l2, t2, cls, "middle"))
            continue
        else:
            x = (b[0] + b[2]) / 2 - (30 + tw) / 2
            o.append(rect(x, (l1 if t1 else l2) - 15, 22, 18, sw, rx=3))   # top of swatch = cap height of first line
            x += 30
        if t1:
            o.append(text(x, l1, t1, cls))
        o.append(text(x, l2, t2, cls))         # one-line labels sit on the lower line, next to the panel
    o.append("</svg>")
    return "\n".join(o)
