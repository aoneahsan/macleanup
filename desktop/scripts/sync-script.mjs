// Copy the canonical macleanup.sh from the repo root into the Tauri
// resources dir so it gets bundled inside the .app. Run before dev/build.
import { copyFileSync, mkdirSync, chmodSync, existsSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const src = resolve(here, '..', '..', 'macleanup.sh');
const destDir = resolve(here, '..', 'src-tauri', 'resources');
const dest = resolve(destDir, 'macleanup.sh');

if (!existsSync(src)) {
  console.error(`[sync:script] macleanup.sh not found at repo root: ${src}`);
  process.exit(1);
}
mkdirSync(destDir, { recursive: true });
copyFileSync(src, dest);
chmodSync(dest, 0o755);
console.log(`[sync:script] bundled macleanup.sh -> ${dest}`);
