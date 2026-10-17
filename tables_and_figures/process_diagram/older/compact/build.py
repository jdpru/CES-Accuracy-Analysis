"""Builds the CES process diagram as one SVG, used by both the artifact page
(index.html) and the paper export page (export.html -> PDF)."""
import pathlib

HERE = pathlib.Path(__file__).parent
W = 1400                       # viewBox width; prints at 6.5 in (215 units per inch)
PT = W / 6.5 / 72              # viewBox units per printed point (~2.99)

F_TITLE = round(7.2 * PT, 1)   # node titles
F_LABEL = round(6.8 * PT, 1)   # arrow labels
F_SMALL = round(6.5 * PT, 1)   # annotations, lane labels (POQ minimum 6.5 pt)

NW, NH = 160, 74               # node size (input tracks)
NB = 172                       # node width, selection and weighting row
LH = F_TITLE * 1.18            # title line height

# ---- geometry -------------------------------------------------------------
X0 = 20
G_C = 84                       # gap inside the respondent track
# Respondent track (row C)
xC = [X0, X0 + NW + G_C, X0 + 2 * (NW + G_C)]
TRACK_END = xC[2] + NW         # right edge shared by both tracks
# Target track (row A), right-aligned with row C
G_A = 150
xA = [TRACK_END - 2 * NW - G_A, TRACK_END - NW]
# Selection and weighting (row B)
CONV = 84
G_B = 56
xB0 = TRACK_END + CONV
xB = [xB0, xB0 + NB + G_B, xB0 + 2 * (NB + G_B)]
assert xB[2] + NB <= W - X0, xB[2] + NB

Y_DASH = 14
Y_LANE_A = 44
yA = 62                        # top of row A nodes
yC = yA + NH + 104             # top of row C nodes
Y_LANE_C = yC - 18
yB = (yA + yC) / 2             # row B sits midway, so the tracks converge on it
H = yC + NH + 64


def node(x, y, lines, cls="node", w=NW):
    out = [f'<rect class="{cls}" x="{x}" y="{y}" width="{w}" height="{NH}" rx="11"/>']
    if cls == "node matched":
        out.append(f'<rect class="hatch" x="{x}" y="{y}" width="{w}" height="{NH}" rx="11"/>')
    n = len(lines)
    cy = y + NH / 2
    first = cy - (n - 1) * LH / 2
    tcls = "t-title inv" if cls == "node final" else "t-title"
    for i, s in enumerate(lines):
        out.append(f'<text class="{tcls}" x="{x + w / 2}" y="{first + i * LH}" '
                   f'dominant-baseline="central" text-anchor="middle">{s}</text>')
    return "\n".join(out)


def note(x, y, s, cls="t-note", anchor="middle"):
    return f'<text class="{cls}" x="{x}" y="{y}" text-anchor="{anchor}">{s}</text>'


def harrow(x0, x1, y, cls="edge"):
    return f'<line class="{cls}" x1="{x0}" y1="{y}" x2="{x1 - 1}" y2="{y}" marker-end="url(#ah)"/>'


def gap_label(x0, x1, y_mid, lines, above=True):
    cx = (x0 + x1) / 2
    lh = F_LABEL * 1.15
    out = []
    if above:
        ys = [y_mid - 9 - (len(lines) - 1 - i) * lh for i in range(len(lines))]
    else:
        ys = [y_mid + 9 + F_LABEL * 0.8 + i * lh for i in range(len(lines))]
    for s, yy in zip(lines, ys):
        out.append(f'<text class="t-label" x="{cx}" y="{yy}" text-anchor="middle">{s}</text>')
    return "\n".join(out)


def step_label(cx, y_bottom, step, text):
    return (f'<text class="t-step" x="{cx}" y="{y_bottom - F_LABEL * 1.2}" text-anchor="middle">{step}</text>\n'
            f'<text class="t-label" x="{cx}" y="{y_bottom}" text-anchor="middle">{text}</text>')


def svg(aria):
    midA, midC, midB = yA + NH / 2, yC + NH / 2, yB + NH / 2
    p = []
    p.append(f'<svg class="diagram" viewBox="0 0 {W} {H:.0f}" role="img" aria-label="{aria}" '
             f'xmlns="http://www.w3.org/2000/svg">')
    p.append(f'''<defs>
  <marker id="ah" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse" markerUnits="userSpaceOnUse">
    <path d="M0,0.8 L9.5,5 L0,9.2 z" class="ah"/>
  </marker>
  <marker id="ahm" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto" markerUnits="userSpaceOnUse">
    <path d="M0,0.8 L9.5,5 L0,9.2 z" class="ahm"/>
  </marker>
  <pattern id="hatchp" width="9" height="9" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
    <line x1="0" y1="0" x2="0" y2="9" class="hatchline"/>
  </pattern>
</defs>''')
    # Phase panel behind selection and weighting
    px = xB0 - 30
    p.append(f'<rect class="panel" x="{px}" y="{Y_LANE_A - 22}" width="{W - px - 4}" height="{H - Y_LANE_A + 14}" rx="16"/>')

    # Lane labels
    p.append(note(X0, Y_LANE_A, "BEFORE DATA COLLECTION", "t-lane", "start"))
    p.append(note(X0, Y_LANE_C, "DURING DATA COLLECTION", "t-lane", "start"))
    p.append(note(W - X0 - 8, Y_LANE_A, "AFTER DATA COLLECTION", "t-lane", "end"))

    # Row A: target track
    p.append(node(xA[0], yA, ["Sampling", "frame"]))
    p.append(node(xA[1], yA, ["Target", "sample"]))
    p.append(harrow(xA[0] + NW, xA[1], midA))
    p.append(gap_label(xA[0] + NW, xA[1], midA, ["stratified", "random draw"], above=True))
    p.append(note(xA[0] + NW / 2, yA + NH + 24, "built from the ACS"))
    p.append(note(xA[1] + NW / 2, yA + NH + 24, "<tspan font-style=\"italic\">N</tspan> cases"))

    # Row C: respondent track
    p.append(node(xC[0], yC, ["Panel", "reservoir"]))
    p.append(node(xC[1], yC, ["Invited", "respondents"]))
    p.append(node(xC[2], yC, ["Participating", "respondents"]))
    p.append(harrow(xC[0] + NW, xC[1], midC))
    p.append(harrow(xC[1] + NW, xC[2], midC))
    p.append(gap_label(xC[0] + NW, xC[1], midC, ["invite"], above=True))
    p.append(gap_label(xC[1] + NW, xC[2], midC, ["respond"], above=True))
    p.append(note(xC[0] + NW / 2, yC + NH + 24, "opt-in panels"))
    p.append(note(xC[2] + NW / 2, yC + NH + 24, "pool larger than <tspan font-style=\"italic\">N</tspan>"))

    # Convergence: both tracks feed matching
    x0, x1 = TRACK_END, xB0
    k = CONV * 0.62
    p.append(f'<path class="edge" d="M{x0},{midA} C{x0 + k},{midA} {x1 - k},{midB} {x1 - 1},{midB}" marker-end="url(#ah)"/>')
    p.append(f'<path class="edge" d="M{x0},{midC} C{x0 + k},{midC} {x1 - k},{midB} {x1 - 1},{midB}"/>')
    p.append(f'<text class="t-label strong" x="{x0 + 24}" y="{midB + 1}" dominant-baseline="central" text-anchor="end">match</text>')

    # Row B: selection and weighting
    p.append(node(xB[0], yB, ["Matched", "sample"], "node matched", NB))
    p.append(node(xB[1], yB, ["Frame-weighted", "sample"], "node", NB))
    p.append(node(xB[2], yB, ["Final weighted", "sample"], "node final", NB))
    p.append(harrow(xB[0] + NB, xB[1], midB))
    p.append(harrow(xB[1] + NB, xB[2], midB))
    s1 = xB[0] + NB + G_B / 2
    s2 = xB[1] + NB + G_B / 2
    p.append(step_label(s1, yB - 16, "STEP 1", "weight to frame"))
    p.append(step_label(s2, yB - 16, "STEP 2", "post-stratify"))
    # Frame supplies the targets for step 1
    fx = xA[0] + NW - 30
    top1 = yB - 16 - F_LABEL * 1.2 - F_SMALL - 2
    p.append(f'<polyline class="ref" points="{fx},{yA} {fx},{Y_DASH} {s1},{Y_DASH} {s1},{top1}" marker-end="url(#ahm)"/>')
    p.append(note(s1 - 10, Y_DASH + F_SMALL + 12, "weighting targets", "t-note", "end"))
    # Which estimates each sample yields (labels as in the results figures)
    p.append(note(xB[0] + NB / 2, yB + NH + 25, "Matching only", "t-est mo"))
    p.append(note(xB[0] + NB / 2, yB + NH + 25 + F_SMALL * 1.25, "estimates", "t-note"))
    p.append(note(xB[2] + NB / 2, yB + NH + 25, "Matching + weighting", "t-est mw"))
    p.append(note(xB[2] + NB / 2, yB + NH + 25 + F_SMALL * 1.25, "estimates", "t-note"))
    p.append("</svg>")
    return "\n".join(p)


SVG_CSS = f"""
.diagram {{ display:block; width:100%; height:auto; font-family:var(--sans); }}
.diagram .node {{ fill:var(--node); stroke:var(--node-line); stroke-width:1.3; }}
.diagram .node.matched {{ fill:var(--mo-fill); stroke:var(--mo-line); stroke-width:1.6; }}
.diagram .hatch {{ fill:url(#hatchp); stroke:none; }}
.diagram .hatchline {{ stroke:var(--mo-hatch); stroke-width:2.2; }}
.diagram .node.final {{ fill:var(--mw); stroke:var(--mw-line); stroke-width:1.6; }}
.diagram .panel {{ fill:var(--panel); stroke:none; }}
.diagram .edge {{ fill:none; stroke:var(--ink); stroke-width:1.5; }}
.diagram .ah {{ fill:var(--ink); }}
.diagram .ref {{ fill:none; stroke:var(--muted); stroke-width:1.3; stroke-dasharray:5 4; }}
.diagram .ahm {{ fill:var(--muted); }}
.diagram text {{ fill:var(--ink); }}
.diagram .t-title {{ font-size:{F_TITLE}px; font-weight:600; letter-spacing:-0.1px; }}
.diagram .t-title.inv {{ fill:var(--on-mw); }}
.diagram .t-label {{ font-size:{F_LABEL}px; fill:var(--muted); }}
.diagram .t-label.strong {{ fill:var(--ink); font-weight:500; }}
.diagram .t-step {{ font-size:{F_SMALL}px; font-weight:600; fill:var(--ink); letter-spacing:1.4px; }}
.diagram .t-note {{ font-size:{F_SMALL}px; fill:var(--muted); }}
.diagram .t-lane {{ font-size:{F_SMALL}px; font-weight:500; fill:var(--muted); letter-spacing:1.6px; }}
.diagram .t-est {{ font-size:{F_SMALL}px; font-weight:600; }}
.diagram .t-est.mo {{ fill:var(--mo-text); }}
.diagram .t-est.mw {{ fill:var(--mw-text); }}
"""

LIGHT = """
  --bg:#edf0f3; --plate:#ffffff; --ink:#1b2631; --muted:#5b6876; --rule:#d5dce3;
  --node:#f3f5f8; --node-line:#b9c4cf; --panel:#f1f5f9;
  --mo-fill:#e3eff6; --mo-line:#6aa6c8; --mo-hatch:#b9d7e8; --mo-text:#3d7194;
  --mw:#17436b; --mw-line:#17436b; --on-mw:#ffffff; --mw-text:#17436b;
"""
DARK = """
  --bg:#0e141a; --plate:#151d25; --ink:#e3e9ef; --muted:#93a1ae; --rule:#2a3540;
  --node:#1d2731; --node-line:#3d4b58; --panel:#19232d;
  --mo-fill:#1c3242; --mo-line:#6aa6c8; --mo-hatch:#2a4a60; --mo-text:#8cc0de;
  --mw:#17436b; --mw-line:#5d93c4; --on-mw:#ffffff; --mw-text:#8db8e0;
  color-scheme:dark;
"""

ARIA = ("Flow diagram. Before data collection, a target sample of N cases is drawn from a sampling frame "
        "built from the ACS. During data collection, panel reservoir members are invited and some complete "
        "the questionnaire. After data collection, the two tracks are matched to form the matched sample, "
        "which is weighted to the frame and then post-stratified to give the final weighted sample.")


def page(caption_html):
    return f"""<title>CES Matching and Weighting</title>
<meta name="claude:viewport-fit-sides" content="cover">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400&family=IBM+Plex+Sans:ital,wght@0,400;0,500;0,600;1,500&family=IBM+Plex+Serif:ital,wght@1,400&display=swap">
<style>
/* Layout: one wide figure plate on a cool paper ground, caption set beneath like a journal figure. */
:root {{ {LIGHT}
  --sans:"IBM Plex Sans", "Helvetica Neue", Helvetica, Arial, sans-serif;
  --mono:"IBM Plex Mono", ui-monospace, Menlo, monospace;
  --serif:"IBM Plex Serif", Georgia, serif;
}}
@media (prefers-color-scheme: dark) {{ :root:not([data-theme="light"]) {{ {DARK} }} }}
:root[data-theme="dark"] {{ {DARK} }}
body {{ background:var(--bg); color:var(--ink); font-family:var(--sans); }}
.wrap {{ max-width:1180px; margin:0 auto; padding-block:48px 64px;
  padding-left:max(16px, env(safe-area-inset-left, 0px)); padding-right:max(16px, env(safe-area-inset-right, 0px)); }}
.eyebrow {{ font-family:var(--mono); font-size:12px; letter-spacing:0.14em; text-transform:uppercase; color:var(--muted); margin:0 0 10px; }}
h1 {{ font-family:var(--serif); font-style:italic; font-weight:400; font-size:clamp(26px, 3.4vw, 38px); line-height:1.15; margin:0 0 28px; text-wrap:balance; }}
.plate {{ background:var(--plate); border:1px solid var(--rule); border-radius:14px; padding:28px 28px 22px; }}
.scroll {{ overflow-x:auto; }}
.scroll .diagram {{ min-width:820px; }}
figure {{ margin:0; }}
figcaption {{ max-width:68ch; margin-top:22px; font-size:14.5px; line-height:1.6; color:var(--muted); }}
figcaption b {{ color:var(--ink); font-weight:600; }}
{SVG_CSS}
</style>
<div class="wrap">
  <p class="eyebrow">Cooperative Election Study · Figure</p>
  <h1>How a CES sample is selected and weighted</h1>
  <figure class="plate">
    <div class="scroll">
{svg(ARIA)}
    </div>
    <figcaption>{caption_html}</figcaption>
  </figure>
</div>
"""


def export_page():
    fonts = HERE / "node_modules/@fontsource"
    ff = ""
    for fam, w, f in [("IBM Plex Sans", 400, "ibm-plex-sans/files/ibm-plex-sans-latin-400-normal.woff2"),
                      ("IBM Plex Sans", 500, "ibm-plex-sans/files/ibm-plex-sans-latin-500-normal.woff2"),
                      ("IBM Plex Sans", 600, "ibm-plex-sans/files/ibm-plex-sans-latin-600-normal.woff2"),
                      ("IBM Plex Mono", 400, "ibm-plex-mono/files/ibm-plex-mono-latin-400-normal.woff2")]:
        ff += f'@font-face{{font-family:"{fam}";font-weight:{w};src:url("file://{fonts / f}") format("woff2");}}\n'
    ff += (f'@font-face{{font-family:"IBM Plex Sans";font-weight:500;font-style:italic;'
           f'src:url("file://{fonts}/ibm-plex-sans/files/ibm-plex-sans-latin-500-italic.woff2") format("woff2");}}\n')
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
{ff}
:root {{ {LIGHT} --sans:"IBM Plex Sans", sans-serif; --mono:"IBM Plex Mono", monospace; --panel:#f3f6f9; }}
@page {{ margin:0; }}
html,body {{ margin:0; background:#fff; }}
{SVG_CSS}
.diagram {{ width:6.5in; }}
</style></head><body>
{svg(ARIA)}
</body></html>"""


if __name__ == "__main__":
    cap = (HERE / "caption.html").read_text() if (HERE / "caption.html").exists() else "Caption pending."
    (HERE / "index.html").write_text(page(cap))
    (HERE / "export.html").write_text(export_page())
    print("H =", H, "aspect", W / H, "printed height in:", round(6.5 * H / W, 2))
