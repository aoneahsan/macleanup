// Render the brand SVG (assets/logo/macleanup-mark.svg) to a 1024px PNG,
// then let the Tauri CLI generate the full platform icon set (.icns/.ico/png).
import { Resvg } from '@resvg/resvg-js';
import { readFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

const here = dirname(fileURLToPath(import.meta.url));
const svgPath = resolve(here, '..', '..', 'assets', 'logo', 'macleanup-mark.svg');
const iconsDir = resolve(here, '..', 'src-tauri', 'icons');
mkdirSync(iconsDir, { recursive: true });

const svg = readFileSync(svgPath, 'utf8');
const resvg = new Resvg(svg, { fitTo: { mode: 'width', value: 1024 } });
const png = resvg.render().asPng();
const sourcePng = resolve(iconsDir, 'icon-source.png');
writeFileSync(sourcePng, png);
console.log(`[gen:icons] rendered 1024px master -> ${sourcePng}`);

// Generate the full Tauri icon set from the master PNG.
execFileSync('npx', ['@tauri-apps/cli', 'icon', sourcePng], { stdio: 'inherit' });
console.log(`[gen:icons] icon set written to ${iconsDir}`);
