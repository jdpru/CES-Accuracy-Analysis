"""Shared drawing helpers for the full-page CES process figures.

Canvas: 1800 x 1120 viewBox units printed at 9 in x 5.6 in (a landscape page
with room for a caption), so 200 units = 1 in and 1 pt = 2.78 units.
"""
import random

W, H = 1800, 1120
PT = W / 9 / 72
F_TITLE = round(9.0 * PT, 1)    # panel titles
F_BODY = round(7.6 * PT, 1)     # subtitles, labels
F_SMALL = round(7.0 * PT, 1)    # notes, table cells, axis labels
F_LANE = round(7.0 * PT, 1)     # phase labels (caps)
F_BIG = round(10.5 * PT, 1)


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def text(x, y, s, cls="ts", anchor="start", extra=""):
    return f'<text class="{cls}" x="{x:.1f}" y="{y:.1f}" text-anchor="{anchor}" {extra}>{s}</text>'


def lines(x, y, rows, cls="ts", anchor="start", lh=None, size=F_BODY):
    lh = lh or size * 1.3
    return "\n".join(text(x, y + i * lh, r, cls, anchor) for i, r in enumerate(rows))


def rect(x, y, w, h, cls, rx=0, extra=""):
    return f'<rect class="{cls}" x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{rx}" {extra}/>'


def line(x1, y1, x2, y2, cls="edge", arrow=False, extra=""):
    m = ' marker-end="url(#ah)"' if arrow else ""
    return f'<line class="{cls}" x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}"{m} {extra}/>'


def path(d, cls="edge", arrow=False):
    m = ' marker-end="url(#ah)"' if arrow else ""
    return f'<path class="{cls}" d="{d}"{m}/>'


def person(x, y, w, cls):
    """Person icon whose top-left is (x, y); height is 1.6 x width."""
    return f'<use href="#person" x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{w * 1.6:.1f}" class="{cls}"/>'


def person_c(cx, base, w, cls):
    """Person icon centred on cx, standing on baseline y=base."""
    return person(cx - w / 2, base - w * 1.6, w, cls)


def ring(cx, cy, r=8.5, cls="ring"):
    """A target case: a record drawn from the frame, not yet a respondent."""
    return f'<circle class="{cls}" cx="{cx:.1f}" cy="{cy:.1f}" r="{r}"/>'


def badge(cx, cy, n, cls="badge"):
    return (f'<circle class="{cls}" cx="{cx}" cy="{cy}" r="{F_BODY * 0.78:.1f}"/>'
            f'<text class="t-badge" x="{cx}" y="{cy}" text-anchor="middle" dominant-baseline="central">{n}</text>')


def table(x, y, cols, rows, row_h=29, shade_from=None, cls_prefix="tb"):
    """cols: list of (header, width). Columns at index >= shade_from are tinted."""
    out = []
    tw = sum(w for _, w in cols)
    out.append(rect(x, y, tw, row_h, "tb-head"))
    cx = x
    for j, (hd, w) in enumerate(cols):
        if shade_from is not None and j >= shade_from:
            out.append(rect(cx, y, w, row_h * (len(rows) + 1), "tb-attach"))
        out.append(text(cx + w / 2, y + row_h * 0.66, hd, "t-cellh", "middle"))
        cx += w
    for i, r in enumerate(rows):
        yy = y + row_h * (i + 1)
        out.append(line(x, yy, x + tw, yy, "tb-rule"))
        cx = x
        for j, (v, (_, w)) in enumerate(zip(r, cols)):
            out.append(text(cx + w / 2, yy + row_h * 0.66, v, "t-cell", "middle"))
            cx += w
    yy = y + row_h * (len(rows) + 1)
    out.append(line(x, yy, x + tw, yy, "tb-rule"))
    out.append(rect(x, y, tw, row_h * (len(rows) + 1), "tb-frame"))
    return "\n".join(out), tw, row_h * (len(rows) + 1)


def defs():
    return """<defs>
  <symbol id="person" viewBox="0 0 10 16" overflow="visible">
    <circle cx="5" cy="3.0" r="2.85" vector-effect="non-scaling-stroke"/>
    <path d="M0.6,16 L0.6,11.2 Q0.6,7.6 4,7.6 L6,7.6 Q9.4,7.6 9.4,11.2 L9.4,16 Z" vector-effect="non-scaling-stroke"/>
  </symbol>
  <marker id="ah" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto" markerUnits="userSpaceOnUse">
    <path d="M0,0.8 L9.5,5 L0,9.2 z" class="ah"/>
  </marker>
  <marker id="ahm" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto" markerUnits="userSpaceOnUse">
    <path d="M0,0.8 L9.5,5 L0,9.2 z" class="ahm"/>
  </marker>
  <pattern id="hatchsoft" width="10" height="10" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
    <rect width="10" height="10" class="hatch-bg"/>
    <line x1="0" y1="0" x2="0" y2="10" class="hatchline-soft"/>
  </pattern>
  <pattern id="hatchp" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
    <rect width="8" height="8" class="hatch-bg"/>
    <line x1="0" y1="0" x2="0" y2="8" class="hatchline"/>
  </pattern>
</defs>"""


def svg_open(aria, h=H):
    return (f'<svg class="diagram full" viewBox="0 0 {W} {h}" role="img" aria-label="{esc(aria)}" '
            f'xmlns="http://www.w3.org/2000/svg">\n' + defs())


CSS = f"""
.full {{ display:block; width:100%; height:auto; font-family:var(--sans); }}
.full text {{ fill:var(--ink); }}
.full .tt {{ font-size:{F_TITLE}px; font-weight:600; letter-spacing:-0.1px; }}
.full .tbig {{ font-size:{F_BIG}px; font-weight:600; letter-spacing:-0.2px; }}
.full .ts {{ font-size:{F_BODY}px; fill:var(--muted); }}
.full .ts-ink {{ font-size:{F_BODY}px; fill:var(--ink); }}
.full .tsb {{ font-size:{F_BODY}px; fill:var(--ink); font-weight:600; }}
.full .tn {{ font-size:{F_SMALL}px; fill:var(--muted); }}
.full .tn-ink {{ font-size:{F_SMALL}px; fill:var(--ink); }}
.full .tl {{ font-size:{F_LANE}px; font-weight:600; fill:var(--muted); letter-spacing:1.8px; }}
.full .t-badge {{ font-size:{F_SMALL}px; font-weight:600; fill:var(--on-ink); }}
.full .badge {{ fill:var(--ink); }}
.full .t-cell {{ font-size:{F_SMALL}px; fill:var(--ink); font-variant-numeric:tabular-nums; }}
.full .t-cellh {{ font-size:{F_SMALL}px; fill:var(--ink); font-weight:600; }}
.full .t-mo {{ fill:var(--mo-text); font-weight:600; }}
.full .t-mw {{ fill:var(--mw-text); font-weight:600; }}
.full .t-math {{ font-size:{F_BODY}px; fill:var(--ink); font-style:italic; }}
.full .panel {{ fill:var(--panel); stroke:var(--rule); stroke-width:1; }}
.full .panel-soft {{ fill:var(--panel); stroke:none; }}
.full .zone {{ fill:var(--zone); stroke:none; }}
.full .band {{ fill:var(--band); stroke:none; }}
.full .band2 {{ fill:var(--band2); stroke:none; }}
.full .rule {{ stroke:var(--rule); stroke-width:1.2; fill:none; }}
.full .rule-ink {{ stroke:var(--ink); stroke-width:1.4; fill:none; }}
.full .edge {{ stroke:var(--ink); stroke-width:1.6; fill:none; }}
.full .edge-soft {{ stroke:var(--muted); stroke-width:1.2; fill:none; }}
.full .pair {{ stroke:var(--mo-line); stroke-width:1.6; fill:none; }}
.full .ref {{ stroke:var(--muted); stroke-width:1.4; fill:none; stroke-dasharray:6 5; }}
.full .ah {{ fill:var(--ink); }}
.full .ahm {{ fill:var(--muted); }}
.full .tb-head {{ fill:var(--node); }}
.full .tb-attach {{ fill:var(--attach); }}
.full .tb-rule {{ stroke:var(--rule); stroke-width:1; }}
.full .tb-frame {{ fill:none; stroke:var(--node-line); stroke-width:1.2; }}
.full .dot {{ fill:var(--pp); }}
.full .row-sel {{ fill:var(--plate); stroke:var(--ink); stroke-width:1.6; }}
.full .thread {{ stroke:var(--mo-line); stroke-width:1.1; fill:none; opacity:0.75; }}
.full .inset {{ fill:var(--plate); stroke:var(--node-line); stroke-width:1.2; }}
.full .dot-mo {{ fill:var(--mo); }}
.full .dot-fade {{ fill:var(--pp); }}
.full .cube-fill {{ fill:var(--plate); stroke:none; }}
.full .cube-edge {{ stroke:var(--node-line); stroke-width:1.3; fill:none; }}
.full .cube-back {{ stroke:var(--node-line); stroke-width:1; stroke-dasharray:4 4; fill:none; }}
.full .dot-done {{ fill:var(--pp-done); }}
.full .pair-strong {{ stroke:var(--mo-line); stroke-width:2.2; }}
.full .leader {{ stroke:var(--mo-line); stroke-width:0.9; opacity:0.7; }}
.full .halo {{ fill:var(--mo-fill); stroke:var(--mo-line); stroke-width:1; }}
.full .beam {{ stroke:var(--ink); stroke-width:2; stroke-linecap:round; }}
.full .string {{ stroke:var(--muted); stroke-width:1; }}
.full .pan {{ fill:var(--node); stroke:var(--ink); stroke-width:1.4; }}
.full .hatchline-soft {{ stroke:var(--mo); stroke-width:1.4; opacity:0.45; }}
.full .panel-mo {{ fill:url(#hatchsoft); stroke:var(--mo-line); stroke-width:1.2; }}
.full .panel-mw {{ fill:var(--mw-fill); stroke:var(--mw); stroke-width:1.6; }}
.full .pp-onmw {{ fill:#ffffff; }}
.full .dot-pick {{ fill:var(--ink); }}
.full .card {{ fill:var(--plate); stroke:var(--node-line); stroke-width:1; }}
.full .dot-att1 {{ fill:var(--att1); }}
.full .dot-att2 {{ fill:var(--att2); }}
.full .dot-att3 {{ fill:var(--att3); }}
.full .ring {{ fill:var(--plate); stroke:var(--ink); stroke-width:2; }}
.full .dot-sel {{ fill:var(--plate); stroke:var(--ink); stroke-width:1.6; }}
.full .pp {{ fill:var(--pp); }}
.full .pp-inv {{ fill:var(--pp-inv); }}
.full .pp-done {{ fill:var(--pp-done); }}
.full .pp-mo {{ fill:var(--mo); }}
.full .pp-mw {{ fill:var(--mw); }}
.full .pp-fade {{ fill:var(--pp); opacity:0.55; }}
.full .pp-ghost {{ fill:var(--ghost); stroke:var(--ink); stroke-width:1.1; }}
.full .bar-mo {{ fill:url(#hatchp); stroke:var(--mo-line); stroke-width:1; }}
.full .bar-mw {{ fill:var(--mw); }}
.full .bar-mid {{ fill:var(--bar-mid); }}
.full .bar-frame {{ fill:none; stroke:var(--ink); stroke-width:1.6; }}
.full .bar-track {{ fill:var(--node); }}
.full .hatch-bg {{ fill:var(--mo-fill); }}
.full .hatchline {{ stroke:var(--mo); stroke-width:2; }}
.full .sw-mo {{ fill:url(#hatchp); stroke:var(--mo-line); stroke-width:1.2; }}
.full .sw-mw {{ fill:var(--mw); }}
.full .chip {{ fill:var(--plate); stroke:var(--node-line); stroke-width:1.2; }}
.full .eday {{ stroke:var(--accent); stroke-width:2; }}
.full .t-eday {{ fill:var(--accent); font-weight:600; font-size:{F_SMALL}px; }}
.full .wave {{ fill:var(--wave); }}
.full .wave2 {{ fill:var(--wave2); }}
.full .tick {{ stroke:var(--ink); stroke-width:2.4; }}
"""

LIGHT = """--bg:#edf0f3; --plate:#ffffff; --ink:#1b2631; --on-ink:#ffffff; --muted:#5b6876; --rule:#d5dce3;
  --node:#eef2f6; --node-line:#b9c4cf; --panel:#f7f9fb; --zone:#f1f5f9; --band:#f0f3f6; --band2:#e6ebf0; --attach:#e4edf4;
  --pp:#ccd4dc; --pp-inv:#8e9dab; --pp-done:#52697e;
  --mo:#6aa6c8; --mo-fill:#e3eff6; --mo-line:#5a95b8; --mo-text:#3d7194;
  --mw:#17436b; --mw-text:#17436b; --accent:#a8742f; --wave:#c9dbe7; --wave2:#dfe7ee; --ghost:#ffffff; --bar-mid:#9fb0bf; --att1:#3f8a7e; --att2:#8a6aa0; --att3:#b4613f; --mw-fill:#d6e0ea;"""
DARK = """--bg:#0e141a; --plate:#151d25; --ink:#e3e9ef; --on-ink:#0e141a; --muted:#93a1ae; --rule:#2c3742;
  --node:#1e2832; --node-line:#3d4b58; --panel:#18212a; --zone:#1a242e; --band:#1b252f; --band2:#222d38; --attach:#1f3242;
  --pp:#3a4652; --pp-inv:#6f7f8f; --pp-done:#a9bccd;
  --mo:#6aa6c8; --mo-fill:#1c3242; --mo-line:#6aa6c8; --mo-text:#8cc0de;
  --mw:#4f86b8; --mw-text:#8db8e0; --accent:#d29a52; --wave:#244257; --wave2:#1f2c37; --ghost:#151d25; --bar-mid:#5f6f7e; --att1:#6cbcae; --att2:#b597cb; --att3:#de8e6b; --mw-fill:#1c3550; color-scheme:dark;"""


def rng(seed):
    return random.Random(seed)


# ---- text measurement (IBM Plex Sans metrics) so blocks of left-aligned text can be centred
_FONT_DIR = __import__("pathlib").Path(__file__).parent.parent / "node_modules/@fontsource/ibm-plex-sans/files"
_METRICS = {}


def text_width(s, cls="tn"):
    """Approximate rendered width of s in viewBox units for the given text class."""
    weight, size = {"tn": (400, F_SMALL), "tn-ink": (400, F_SMALL), "ts": (400, F_BODY),
                    "tsb": (600, F_BODY)}.get(cls.split()[0], (400, F_SMALL))
    if weight not in _METRICS:
        try:
            from fontTools.ttLib import TTFont
            f = TTFont(str(_FONT_DIR / f"ibm-plex-sans-latin-{weight}-normal.woff2"))
            _METRICS[weight] = (f.getBestCmap(), f["hmtx"].metrics, f["head"].unitsPerEm)
        except Exception:
            _METRICS[weight] = None
    m = _METRICS[weight]
    if m is None:
        return len(s) * size * (0.56 if weight == 600 else 0.5)
    cmap, hmtx, upm = m
    return sum(hmtx.get(cmap.get(ord(ch), ".notdef"), (upm * 0.5, 0))[0] for ch in s) * size / upm
