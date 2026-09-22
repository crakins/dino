// Renders the App Store Connect Apple Watch screenshots from render.html.
// Usage (from repo root):  node Marketing/screenshots/tool/shoot.mjs
// Requires the `playwright` package and a Chromium build.
import { createRequire } from "node:module";
import { mkdirSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const require = createRequire(import.meta.url);
const { chromium } = require("playwright");

const here = dirname(fileURLToPath(import.meta.url));
const outRoot = resolve(here, "..");
const page_url = pathToFileURL(join(here, "render.html")).href;

// App Store Connect pixel sizes are @2x of the watch's point size.
// Safe-area insets approximate what watchOS gives a full-screen app on each case size.
const DEVICES = [
  { dir: "ultra-3_422x514",   w: 211, h: 257, top: 38, bottom: 18, clock: 16 },
  { dir: "ultra_410x502",     w: 205, h: 251, top: 37, bottom: 18, clock: 16 },
  { dir: "series-11_416x496", w: 208, h: 248, top: 36, bottom: 17, clock: 15.5 },
  { dir: "series-9_396x484",  w: 198, h: 242, top: 35, bottom: 17, clock: 15 },
  { dir: "series-6_368x448",  w: 184, h: 224, top: 32, bottom: 14, clock: 14 },
];

// App Store order. The system clock is drawn on UI screens; it is left off where it would sit on top
// of app content (the gameplay HUD charge ring, and Run Ended's season/time label).
const SCREENS = [
  ["01-home", "menu", true],
  ["02-bamboo-grove-summer", "bambooSummer", false],
  ["03-market-worlds", "marketWorlds", true],
  ["04-market-pandas", "marketPandas", true],
  ["05-quest", "quest", true],
  ["06-profile", "profile", true],
  ["07-bamboo-grove-winter", "bambooWinter", false],
  ["08-panda-jadepaw", "kinDetail", true],
  ["09-mist-terraces", "mistSpring", false],
  ["10-run-ended", "gameOver", false],
];

const browser = await chromium.launch(
  process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {}
);
for (const d of DEVICES) {
  const ctx = await browser.newContext({ viewport: { width: d.w, height: d.h }, deviceScaleFactor: 2 });
  const page = await ctx.newPage();
  mkdirSync(join(outRoot, d.dir), { recursive: true });
  for (const [file, screen, clock] of SCREENS) {
    const hash = `screen=${screen}&w=${d.w}&h=${d.h}&top=${d.top}&bottom=${d.bottom}&clock=${clock ? d.clock : 0}`;
    await page.goto(`${page_url}#${hash}`);
    await page.reload(); // hash-only navigation doesn't re-run the script
    await page.waitForFunction(() => window.__ready === true);
    const path = join(outRoot, d.dir, `${file}.png`);
    await page.locator("#screen").screenshot({ path });
    console.log(path);
  }
  await ctx.close();
}
await browser.close();
