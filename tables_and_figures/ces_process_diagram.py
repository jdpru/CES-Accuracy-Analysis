"""Flow diagram of the CES sample matching and weighting procedure.

Writes output/ces_matching_weighting_process.pdf (vector, fonts embedded),
styled to match the "Refined Blues" paper figures in figuresHQ.ipynb:
7 pt sans-serif type at 6.5 in wide, so it prints at 7 pt with
\\includegraphics[width=\\linewidth].

Run from tables_and_figures/:  python3 ces_process_diagram.py
"""
import os
import sys

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import to_rgb
from matplotlib.patches import FancyBboxPatch, Rectangle

# --- Paper style (copied from the figuresHQ color-scheme cell) ---------------
PAPER_INK = "#1f1f1f"
PAPER_MUTED = "#6b6b6b"
PAPER_RULE = "#d9d9d9"
PAPER_FIG_WIDTH = 6.5
MATCHING_ONLY = {"fill": "#6aa6c8", "hatch_color": "#466e84"}
MATCHING_WEIGHTING = {"fill": "#17436b"}

RC = {
    "font.family": "sans-serif",
    "font.sans-serif": ["Helvetica Neue", "Helvetica", "Arial", "Liberation Sans", "DejaVu Sans"],
    "font.size": 7,
    "text.color": PAPER_INK,
    "mathtext.default": "regular",
    "axes.unicode_minus": True,
    "hatch.linewidth": 0.6,
    "pdf.fonttype": 42,
}


def tint(color, amount):
    r, g, b = to_rgb(color)
    return (r + (1 - r) * amount, g + (1 - g) * amount, b + (1 - b) * amount)


BOX_FILL = tint("#17436b", 0.95)
BOX_EDGE = "#8a96a3"
TITLE_SIZE = 7
BODY_SIZE = 6.5
LINE = 0.118          # inches per text line at 6.5-7 pt
PAD_Y = 0.065
ARROW_LW = 0.7

W, H = PAPER_FIG_WIDTH, 7.4   # canvas; saved figure is cropped to content


def setup():
    fig = plt.figure(figsize=(W, H))
    ax = fig.add_axes([0, 0, 1, 1])
    ax.set_xlim(0, W)
    ax.set_ylim(0, H)
    ax.axis("off")
    return fig, ax


def box_height(lines):
    return 2 * PAD_Y + LINE * len(lines)


def draw_box(ax, cx, top, width, title, body, height=None, fill=BOX_FILL,
             edge=BOX_EDGE, lw=0.6):
    """A set of cases: bold title line plus muted description lines."""
    lines = [title] + body
    h = height if height is not None else box_height(lines)
    left = cx - width / 2
    ax.add_patch(FancyBboxPatch((left, top - h), width, h,
                                boxstyle="round,pad=0,rounding_size=0.045",
                                facecolor=fill, edgecolor=edge, linewidth=lw,
                                zorder=2))
    # Center the text block vertically in the box.
    block = LINE * len(lines)
    y = top - (h - block) / 2 - LINE / 2
    ax.text(cx, y, title, ha="center", va="center", fontsize=TITLE_SIZE,
            fontweight="bold", color=PAPER_INK, zorder=3)
    for line in body:
        y -= LINE
        ax.text(cx, y, line, ha="center", va="center", fontsize=BODY_SIZE,
                color=PAPER_MUTED, zorder=3)
    return {"left": left, "right": left + width, "top": top, "bottom": top - h,
            "cx": cx, "cy": top - h / 2}


def arrow(ax, x0, y0, x1, y1, color=PAPER_INK, ls="-", lw=ARROW_LW, head=True):
    ax.annotate("", xy=(x1, y1), xytext=(x0, y0),
                arrowprops=dict(arrowstyle="-|>" if head else "-", lw=lw,
                                color=color, linestyle=ls, mutation_scale=6,
                                shrinkA=0, shrinkB=0),
                zorder=1)


def step_label(ax, x, y_mid, lines, bold_first=False, size=BODY_SIZE):
    """Process text set beside a vertical arrow, vertically centered on it."""
    n = len(lines)
    y = y_mid + LINE * (n - 1) / 2
    for i, line in enumerate(lines):
        bold = bold_first and i == 0
        ax.text(x, y, line, ha="left", va="center", fontsize=size,
                color=PAPER_INK if bold else PAPER_MUTED,
                fontweight="bold" if bold else "normal")
        y -= LINE


def section_header(ax, x0, x1, y, text, align="left"):
    ax.plot([x0, x1], [y - 0.085, y - 0.085], color=PAPER_RULE, lw=0.6,
            solid_capstyle="butt", zorder=0)
    tx = x0 if align == "left" else (x0 + x1) / 2
    ax.text(tx, y, text, ha=align, va="center", fontsize=TITLE_SIZE,
            fontweight="bold", color=PAPER_INK, zorder=4,
            bbox=dict(facecolor="white", edgecolor="none", pad=1.5))


def estimate_tag(ax, box, kind, text):
    """Swatch + label to the left of a box, using the paper's method encoding."""
    sw, sh = 0.17, 0.10
    x_text = box["left"] - 0.12
    ax.text(x_text, box["cy"], text, ha="right", va="center",
            fontsize=TITLE_SIZE, color=PAPER_INK)
    # Measure text to place the swatch just left of it.
    fig = ax.figure
    renderer = fig.canvas.get_renderer()
    t = ax.texts[-1]
    bb = t.get_window_extent(renderer=renderer)
    inv = ax.transData.inverted()
    x_left = inv.transform((bb.x0, bb.y0))[0]
    sx = x_left - 0.06 - sw
    sy = box["cy"] - sh / 2
    if kind == "matching":
        ax.add_patch(Rectangle((sx, sy), sw, sh, facecolor=MATCHING_ONLY["fill"],
                               edgecolor=MATCHING_ONLY["hatch_color"], hatch="////",
                               linewidth=0, zorder=2))
    else:
        ax.add_patch(Rectangle((sx, sy), sw, sh, facecolor=MATCHING_WEIGHTING["fill"],
                               edgecolor="none", linewidth=0, zorder=2))
    # Leader from label to box.
    ax.plot([x_text + 0.03, box["left"] - 0.02], [box["cy"], box["cy"]],
            color=PAPER_RULE, lw=0.6, zorder=1)


def main(out_dir="output"):
    with plt.rc_context(RC):
        fig, ax = setup()

        col_w = 3.05
        xL, xR = col_w / 2, W - col_w / 2
        bw = 2.55
        xC = W / 2
        gap = 0.50           # vertical space between boxes in the top section

        # ---------------- Top section: two parallel tracks ------------------
        y = H - 0.10
        section_header(ax, 0, col_w, y, "Before data collection: target sample")
        section_header(ax, W - col_w, W, y, "Data collection: respondents")

        rows = [
            (("American Community Survey", ["Citizen records from an earlier year"]),
             ("Panel reservoir", ["YouGov's opt-in panel; from 2008,",
                                  "other companies' opt-in panels"])),
            (("Sampling frame", ["Synthetic file of US citizens"]),
             ("Invited respondents", ["Panelists asked to complete the",
                                      "pre-election questionnaire"])),
            (("Target sample", ["N cases; no survey data collected"]),
             ("Participating respondents", ["Pool of completed pre-election",
                                            "interviews, larger than N"])),
        ]
        left_steps = [
            ["Stratified sample of records;", "political and, in some years,",
             "religious variables attached", "from the CPS, Pew, and others"],
            ["Stratified random sample"],
        ]
        right_steps = [
            ["Invitations allocated by", "demographics, geography,", "and sample source"],
            ["Questionnaire completed;", "quality controls applied"],
        ]

        top = y - 0.26
        L, R = [], []
        for i, (lb, rb) in enumerate(rows):
            h = max(box_height([lb[0]] + lb[1]), box_height([rb[0]] + rb[1]))
            L.append(draw_box(ax, xL, top, bw, lb[0], lb[1], height=h))
            R.append(draw_box(ax, xR, top, bw, rb[0], rb[1], height=h))
            this_gap = gap if i < len(rows) - 1 else 0
            if i < len(rows) - 1:
                gap_i = 0.56 if i == 0 else gap
                top = L[-1]["bottom"] - gap_i
        for i in range(len(rows) - 1):
            for col, steps in ((L, left_steps), (R, right_steps)):
                a, b = col[i], col[i + 1]
                arrow(ax, a["cx"], a["bottom"], b["cx"], b["top"])
                step_label(ax, a["cx"] + 0.09, (a["bottom"] + b["top"]) / 2, steps[i])

        # ---------------- Lower section: selection and weighting -------------
        y2 = L[-1]["bottom"] - 0.34
        y_merge = y2 - 0.30
        section_header(ax, 0, W, y2, "After data collection: selection and weighting")

        # The two tracks converge on matching.
        for b in (L[-1], R[-1]):
            ax.plot([b["cx"], b["cx"]], [b["bottom"], y_merge], color=PAPER_INK,
                    lw=ARROW_LW, zorder=1, solid_capstyle="butt")
        ax.plot([L[-1]["cx"], R[-1]["cx"]], [y_merge, y_merge], color=PAPER_INK,
                lw=ARROW_LW, zorder=1, solid_capstyle="butt")
        # Small labels on the converging lines.
        ax.text((L[-1]["cx"] + xC) / 2, y_merge + 0.055, "each target case t",
                ha="center", va="bottom", fontsize=BODY_SIZE, color=PAPER_MUTED)
        ax.text((R[-1]["cx"] + xC) / 2, y_merge + 0.055, "each respondent i",
                ha="center", va="bottom", fontsize=BODY_SIZE, color=PAPER_MUTED)

        cw = 2.55
        lower_gap = 0.62
        m_top = y_merge - 0.62
        matched = draw_box(ax, xC, m_top, cw, "Matched sample",
                           ["The N respondents most similar", "to the N target cases"],
                           fill=tint(MATCHING_ONLY["fill"], 0.80),
                           edge=MATCHING_ONLY["hatch_color"], lw=0.8)
        arrow(ax, xC, y_merge, xC, matched["top"])
        step_label(ax, xC + 0.09, (y_merge + matched["top"]) / 2,
                   ["Matching",
                    "Nearest respondent by weighted distance,",
                    r"$D(t,i)=\Sigma_k\, w_k\, d_k(t_k, i_k)$"],
                   bold_first=True)

        fw = draw_box(ax, xC, matched["bottom"] - lower_gap, cw, "Frame-weighted sample",
                      ["Matched sample weighted toward", "the sampling frame"])
        arrow(ax, xC, matched["bottom"], xC, fw["top"])
        s1_mid = (matched["bottom"] + fw["top"]) / 2
        step_label(ax, xC + 0.09, s1_mid,
                   ["Weighting step 1: weighting to the frame",
                    "Propensity score weighting (2008–2012) or",
                    "entropy balancing (2014–2022)"],
                   bold_first=True)

        final = draw_box(ax, xC, fw["bottom"] - 0.84, cw, "Final weighted sample",
                         ["Weights released with the CES"],
                         height=fw["top"] - fw["bottom"],
                         fill=tint(MATCHING_WEIGHTING["fill"], 0.84),
                         edge=MATCHING_WEIGHTING["fill"], lw=0.8)
        arrow(ax, xC, fw["bottom"], xC, final["top"])
        step_label(ax, xC + 0.09, (fw["bottom"] + final["top"]) / 2,
                   ["Weighting step 2: post-stratification",
                    "Demographic margins and, in later waves, registration,",
                    "born-again status, and prior presidential vote; from",
                    "2014, state governor and US Senate results; then",
                    "trimming and normalization"],
                   bold_first=True)

        # The frame is the target of weighting step 1 (dashed reference line).
        fr = L[1]
        x_route = 0.08
        ax.plot([fr["left"], x_route, x_route, xC - 0.05],
                [fr["cy"], fr["cy"], s1_mid, s1_mid],
                color=PAPER_MUTED, lw=0.6, ls=(0, (3, 2)), zorder=1)
        arrow(ax, xC - 0.30, s1_mid, xC - 0.015, s1_mid, color=PAPER_MUTED, lw=0.6)
        ax.text(x_route + 0.08, s1_mid + 0.05, "Frame supplies the targets for step 1",
                ha="left", va="bottom", fontsize=BODY_SIZE, color=PAPER_MUTED)

        # Which estimates in the paper come from which sample.
        estimate_tag(ax, matched, "matching", "Matching-only estimates")
        estimate_tag(ax, final, "weighting", "Matching + weighting estimates")

        # Crop the canvas to the content (1 data unit stays 1 inch).
        lowest = final["bottom"] - 0.04
        fig.set_size_inches(W, H - lowest)
        ax.set_ylim(lowest, H)

        os.makedirs(out_dir, exist_ok=True)
        path = os.path.join(out_dir, "ces_matching_weighting_process.pdf")
        try:
            fig.savefig(path, bbox_inches="tight", pad_inches=0.02)
        except Exception as err:
            print(f"TrueType embedding failed ({err}); writing with Type 3 fonts")
            with plt.rc_context({"pdf.fonttype": 3}):
                fig.savefig(path, bbox_inches="tight", pad_inches=0.02)
        plt.close(fig)
        print(f"Saved: {path}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "output")
