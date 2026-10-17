# CES process diagram (figure: fig:ces_process)

One SVG drives both the web version and the paper PDF.

    npm install @fontsource/ibm-plex-sans@5.0.20 @fontsource/ibm-plex-mono@5.0.13 playwright-core@1.47.2
    python3 build.py      # writes index.html (web page) and export.html (paper version)
    node render.js        # writes ces_matching_weighting_process.pdf (6.5 x 1.76 in, fonts embedded)

render.js points at a headless Chromium path; change `executablePath` to your local Chrome
(e.g. /Applications/Google Chrome.app/Contents/MacOS/Google Chrome). Copy the PDF to ../output/.
caption.html is the web caption; the LaTeX caption is in "Claude outputs/ces_process_figure.tex".
