// Renders export.html to a vector PDF sized to the figure, plus PNG previews.
const { chromium } = require('playwright-core');
const path = require('path');
(async () => {
  const dir = __dirname;
  const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell' });
  const page = await browser.newPage({ deviceScaleFactor: 2 });
  await page.goto('file://' + path.join(dir, 'export.html'));
  await page.evaluate(() => document.fonts.ready);
  const box = await page.locator('svg').boundingBox();
  await page.pdf({ path: path.join(dir, 'ces_matching_weighting_process.pdf'),
    width: box.width + 'px', height: Math.ceil(box.height) + 'px', printBackground: true, pageRanges: '1' });
  await page.locator('svg').screenshot({ path: path.join(dir, 'export.png') });
  // Artifact page previews (fonts fall back offline; layout check only)
  for (const scheme of ['light', 'dark']) {
    const p2 = await browser.newPage({ viewport: { width: 1280, height: 900 }, colorScheme: scheme });
    await p2.route('**/fonts.googleapis.com/**', r => r.abort());
    await p2.goto('file://' + path.join(dir, 'index.html'));
    await p2.addStyleTag({ content: (await page.content()).match(/@font-face[^}]+}/g).join('\n') });
    await p2.evaluate(() => document.fonts.ready);
    await p2.screenshot({ path: path.join(dir, `page-${scheme}.png`), fullPage: true });
  }
  await browser.close();
})();
