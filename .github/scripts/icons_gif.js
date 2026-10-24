// Record the home page's icon marquee as transparent PNG frames for the README GIF.
//
//   node .github/scripts/icons_gif.js <site url> <frames dir> [fps]
//
// Each row moves exactly one set of icons per loop, so the GIF loops without a
// jump. The loop length follows the app count to keep the speed at PX_PER_SEC.
// Set BROWSER_CHANNEL=msedge (or chrome) to use an installed browser locally.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const PX_PER_SEC = 80;
const [url, dir, fps = '25'] = process.argv.slice(2);
const FPS = +fps;

(async () => {
  fs.rmSync(dir, { recursive: true, force: true });
  fs.mkdirSync(dir, { recursive: true });
  const browser = await chromium.launch({ channel: process.env.BROWSER_CHANNEL || undefined });
  const page = await browser.newPage({ viewport: { width: 1280, height: 1000 }, deviceScaleFactor: 1 });
  await page.goto(url, { waitUntil: 'networkidle' });
  await page.addStyleTag({ content: `
    html,body{background:transparent!important}
    .bg,.hero:before,.pill,.cta{display:none!important}
    .hero{min-height:0!important;padding:70px 24px 40px!important}
  ` });
  // marquee icons are lazy; load them all before recording
  await page.evaluate(async () => {
    const imgs = [...document.querySelectorAll('.mq img')];
    imgs.forEach(i => { i.loading = 'eager'; });
    await Promise.all(imgs.map(i => i.complete ? 0 : new Promise(r => { i.onload = i.onerror = r; })));
    await document.fonts.ready;
  });
  await page.waitForTimeout(500);

  const { box, setWidth } = await page.evaluate(() => {
    const m = [...document.querySelectorAll('.mq')];
    const a = m[0].getBoundingClientRect(), b = m[m.length - 1].getBoundingClientRect();
    const row = document.querySelector('.row'), tiles = [...row.children];
    const unique = new Set(tiles.map(t => t.innerHTML)).size;
    return {
      box: { x: 0, y: Math.floor(a.top), width: 1280, height: Math.ceil(b.bottom - a.top) },
      setWidth: row.scrollWidth / tiles.length * unique,
    };
  });
  const N = Math.round(setWidth / PX_PER_SEC * FPS), T = N / FPS * 1000;

  await page.evaluate((T) => {
    for (const a of document.getAnimations()) {
      a.pause();
      if (a.animationName !== 'loop') continue;
      // the row's -50% covers `reps` icon sets; move one set per T
      const row = a.effect.target, tiles = [...row.children];
      const reps = tiles.length / 2 / new Set(tiles.map(t => t.innerHTML)).size;
      a.effect.updateTiming({ duration: reps * T });
    }
  }, T);
  for (let i = 0; i < N; i++) {
    await page.evaluate((t) => {
      for (const a of document.getAnimations()) if (a.animationName === 'loop') a.currentTime = t;
    }, i * T / N);
    await page.screenshot({ path: path.join(dir, `f${String(i).padStart(4, '0')}.png`), clip: box, omitBackground: true });
  }
  console.log(`frames=${N} loop=${(T / 1000).toFixed(1)}s box=${JSON.stringify(box)}`);
  await browser.close();
})();
