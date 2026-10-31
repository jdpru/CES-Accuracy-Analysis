# Process diagram (figure: fig:ces_process)

`process_diagram.pdf` is the paper figure (9 in wide, full landscape page via `sidewaysfigure`).
`manuscript.tex` includes it as `process_diagram/process_diagram.pdf`.

## Rebuild

    cd tables_and_figures/process_diagram
    npm install                     # playwright-core + IBM Plex fonts (package.json)
    python3 source/make.py            # writes source/export_*.html and source/ces-process-full.html
    CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" node source/render.js c

`node source/render.js c` writes `process_diagram.pdf` here.

## Layout

- `source/vc.py`: the figure (Version C). `LEGEND_BG = True` draws the colored panels behind
  Matched and post-stratified; `STYLE = "cube"` is the matching cube.
- `source/lib.py`: shared drawing helpers, colors, and text measurement. `source/make.py`: page and export assembly.
- Versions A and B, the two full-page candidates not chosen, were removed on Oct 31, 2026 (`source/va.py`, `source/vb.py` in git history).
