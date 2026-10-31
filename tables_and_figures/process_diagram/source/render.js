// Export the process diagram (Version C) to a 9-inch-wide vector PDF, plus a PNG preview.
const { chromium } = require('../node_modules/playwright-core');
const path = require('path');
const fs = require('fs');
(async () => {
  const dir = __dirname;
  // Set CHROME to a local Chrome, e.g. CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  const exe = process.env.CHROME || '/opt/pw-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell';
  const browser = await chromium.launch({ executablePath: exe });
  const only = process.argv[2];
  for (const k of ['c']) {
    if (only && only !== k) continue;
    const f = path.join(dir, `export_${k}.html`);
    if (!fs.existsSync(f)) continue;
    const page = await browser.newPage({ deviceScaleFactor: 2 });
    await page.goto('file://' + f);
    await page.evaluate(() => document.fonts.ready);
    const box = await page.locator('svg').boundingBox();
    // Version C is the paper figure: written straight to ../process_diagram.pdf
    const out = k === 'c' ? path.join(dir, '..', 'process_diagram.pdf') : path.join(dir, `ces_process_full_${k}.pdf`);
    await page.pdf({ path: out, width: box.width + 'px',
      height: Math.ceil(box.height) + 'px', printBackground: true, pageRanges: '1' });
    await page.locator('svg').screenshot({ path: path.join(dir, `prev_${k}.png`) });
    await page.close();
  }
  await browser.close();
})();
