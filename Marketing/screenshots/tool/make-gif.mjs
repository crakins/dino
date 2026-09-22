// Renders the countdown + Bamboo Grove run animation frames from render.html (screen=anim).
// Usage: node make-gif.mjs <outDir> [seed] [w h]   then: python3 frames-to-gif.py <outDir> <out.gif>
import { createRequire } from "node:module";
import { mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const require = createRequire(import.meta.url);
const { chromium } = require("playwright");
const here = dirname(fileURLToPath(import.meta.url));
const [outDir, seed = "7", w = "211", h = "257"] = process.argv.slice(2);
mkdirSync(outDir, { recursive: true });

const browser = await chromium.launch();
const page = await (await browser.newContext({ viewport: { width: +w, height: +h }, deviceScaleFactor: 2 })).newPage();
await page.goto(pathToFileURL(join(here, "render.html")).href + `#screen=anim&w=${w}&h=${h}&top=0&bottom=0&seed=${seed}&fps=20&run=11`);
await page.waitForFunction(() => window.__ready === true);
const info = await page.evaluate(() => window.animInfo);
console.log(JSON.stringify(info));
if (process.env.DRY) { await browser.close(); process.exit(0); }
for (let i = 0; i < info.frames; i++) {
  await page.evaluate(i => window.renderFrame(i), i);
  await page.locator("#screen").screenshot({ path: join(outDir, `f${String(i).padStart(4, "0")}.png`) });
}
await browser.close();
