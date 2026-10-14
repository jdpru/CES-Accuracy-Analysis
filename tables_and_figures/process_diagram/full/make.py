"""Assemble the comparison page and per-version export pages."""
import pathlib, sys
sys.path.insert(0, str(pathlib.Path(__file__).parent))
from lib import CSS, LIGHT, DARK
import va
try:
    import vb
except ImportError:
    vb = None
try:
    import vc
except ImportError:
    vc = None

HERE = pathlib.Path(__file__).parent
FONTS = HERE.parent / "node_modules/@fontsource"

VERSIONS = [("a", "Version A", "Eight-panel plate", va)]
if vb: VERSIONS.append(("b", "Version B", "Calendar with two lanes", vb))
if vc: VERSIONS.append(("c", "Version C", "Follow the respondents", vc))


def export(svg):
    ff = ""
    for fam, w, st, f in [("IBM Plex Sans", 400, "normal", "ibm-plex-sans/files/ibm-plex-sans-latin-400-normal.woff2"),
                          ("IBM Plex Sans", 400, "italic", "ibm-plex-sans/files/ibm-plex-sans-latin-400-italic.woff2"),
                          ("IBM Plex Sans", 500, "normal", "ibm-plex-sans/files/ibm-plex-sans-latin-500-normal.woff2"),
                          ("IBM Plex Sans", 600, "normal", "ibm-plex-sans/files/ibm-plex-sans-latin-600-normal.woff2")]:
        ff += f'@font-face{{font-family:"{fam}";font-weight:{w};font-style:{st};src:url("file://{FONTS / f}") format("woff2");unicode-range:U+0000-024F,U+2000-206F,U+20AC,U+2122,U+2191,U+2193,U+2212;}}\n'
    for st in ("normal", "italic"):
        ff += (f'@font-face{{font-family:"IBM Plex Sans";font-weight:400;font-style:{st};'
               f'src:url("file://{FONTS}/ibm-plex-sans/files/ibm-plex-sans-greek-400-{st}.woff2") format("woff2");unicode-range:U+0370-03FF;}}\n')
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
{ff}
:root {{ {LIGHT} --sans:"IBM Plex Sans", sans-serif; }}
@page {{ margin:0; }}
html,body {{ margin:0; background:#fff; }}
{CSS}
.full {{ width:9in; }}
</style></head><body>
{svg}
</body></html>"""


def page(sections):
    return f"""<title>CES Process, Full Page</title>
<meta name="claude:viewport-fit-sides" content="cover">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400&family=IBM+Plex+Sans:ital,wght@0,400;0,500;0,600;1,400&family=IBM+Plex+Serif:ital,wght@1,400&display=swap">
<style>
/* Layout: a contact sheet of full-page figure candidates, each on its own plate at landscape-page proportions. */
:root {{ {LIGHT}
  --sans:"IBM Plex Sans", "Helvetica Neue", Helvetica, Arial, sans-serif;
  --mono:"IBM Plex Mono", ui-monospace, Menlo, monospace;
  --serif:"IBM Plex Serif", Georgia, serif;
}}
@media (prefers-color-scheme: dark) {{ :root:not([data-theme="light"]) {{ {DARK} }} }}
:root[data-theme="dark"] {{ {DARK} }}
body {{ background:var(--bg); color:var(--ink); font-family:var(--sans); }}
.wrap {{ max-width:1320px; margin:0 auto; padding-block:48px 72px;
  padding-left:max(16px, env(safe-area-inset-left, 0px)); padding-right:max(16px, env(safe-area-inset-right, 0px)); }}
.eyebrow {{ font-family:var(--mono); font-size:12px; letter-spacing:0.14em; text-transform:uppercase; color:var(--muted); margin:0 0 10px; }}
h1 {{ font-family:var(--serif); font-style:italic; font-weight:400; font-size:clamp(26px, 3.4vw, 38px); line-height:1.15; margin:0 0 12px; text-wrap:balance; }}
.dek {{ max-width:70ch; color:var(--muted); font-size:15px; line-height:1.6; margin:0 0 20px; }}
nav {{ display:flex; flex-wrap:wrap; gap:8px; margin:0 0 36px; }}
nav a {{ font-family:var(--mono); font-size:12.5px; letter-spacing:0.06em; color:var(--ink); text-decoration:none;
  border:1px solid var(--rule); background:var(--plate); border-radius:999px; padding:7px 14px; }}
nav a:hover, nav a:focus-visible {{ border-color:var(--ink); outline:none; }}
section {{ margin:0 0 56px; scroll-margin-top:24px; }}
.vhead {{ display:flex; align-items:baseline; gap:14px; flex-wrap:wrap; margin:0 0 14px; }}
.vhead h2 {{ font-size:20px; font-weight:600; margin:0; letter-spacing:-0.01em; }}
.vhead .tag {{ font-family:var(--mono); font-size:12px; letter-spacing:0.12em; text-transform:uppercase; color:var(--muted); }}
.vnote {{ max-width:72ch; color:var(--muted); font-size:14.5px; line-height:1.6; margin:12px 0 0; }}
.sheet {{ background:var(--plate); border:1px solid var(--rule); border-radius:14px; padding:24px; overflow-x:auto; }}
.sheet .full {{ min-width:980px; }}
{CSS}
</style>
<div class="wrap">
  <p class="eyebrow">Cooperative Election Study · Full-page figure candidates</p>
  <h1>How a CES sample is selected and weighted</h1>
  <p class="dek">Three ways to fill a landscape page (9 × 5.6 in, leaving room for a caption). All illustrations are schematic: the icons, bars, and shares show how each step works, not real CES values. Dates and counts are from the 2022 guide.</p>
  <nav>{"".join(f'<a href="#{k}">{lab} · {name}</a>' for k, lab, name, _ in VERSIONS)}</nav>
{sections}
</div>
"""


NOTES = {
    "a": "Eight steps in reading order, grouped under before, during, and after fieldwork. Each panel shows the mechanism of its step: a frame table with attached columns, stratified draws, invitations, the field calendar, nearest-neighbor pairing, weights as icon size, and margins pulled to targets.",
    "b": "A calendar runs along the bottom, so position on the page is time. The target sample is fixed before fieldwork and waits while respondents are recruited and interviewed; the two lanes meet at matching once fieldwork ends.",
    "c": "One set of people, followed from the panel to the released file. Each column is a stage, with the same icons getting fewer and then heavier or lighter. The least text of the three.",
}

if __name__ == "__main__":
    secs = []
    for k, lab, name, mod in VERSIONS:
        svg = mod.build()
        (HERE / f"export_{k}.html").write_text(export(svg))
        secs.append(f"""  <section id="{k}">
    <div class="vhead"><span class="tag">{lab}</span><h2>{name}</h2></div>
    <div class="sheet">
{svg}
    </div>
    <p class="vnote">{NOTES[k]}</p>
  </section>""")
    (HERE / "ces-process-full.html").write_text(page("\n".join(secs)))
    print("built", [v[0] for v in VERSIONS])
