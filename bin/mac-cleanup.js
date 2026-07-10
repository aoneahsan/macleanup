#!/usr/bin/env node
/* eslint-disable no-console */
/**
 * mac-cleanup — Node.js launcher for the bundled bash script.
 *
 * This file exists for one reason: enable `npx macleanup` so users can
 * run the tool with zero install. It does NOT reimplement
 * anything in JavaScript. All logic lives in mac-cleanup.sh — the launcher
 * just validates the host platform, locates the script, and execs bash
 * with the user's argv forwarded through.
 *
 * Author : Ahsan Mahmood <aoneahsan@gmail.com>
 * Repo   : https://github.com/aoneahsan/macleanup
 * License: MIT (see LICENSE.md). AS IS, no warranty.
 */
'use strict';

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

// ── Platform guard ──────────────────────────────────────────────────────
if (process.platform !== 'darwin') {
  console.error(
    'mac-cleanup: this tool only runs on macOS. Detected platform: ' +
      process.platform,
  );
  process.exit(1);
}

// ── Locate the bash script that ships next to this launcher ─────────────
// __dirname == <package>/bin, so the script is one level up.
const scriptPath = path.resolve(__dirname, '..', 'mac-cleanup.sh');
if (!fs.existsSync(scriptPath)) {
  console.error(
    'mac-cleanup: bundled script not found at ' +
      scriptPath +
      '\nThe package may be corrupted. Try `npx --yes macleanup` again.',
  );
  process.exit(1);
}

// Try to make sure the script is executable. npm preserves the +x bit
// on publish, but old caches or odd extraction paths sometimes don't.
try {
  fs.chmodSync(scriptPath, 0o755);
} catch (_) {
  /* best-effort */
}

// ── Pick a bash interpreter ─────────────────────────────────────────────
// `/usr/bin/env bash` works for the script's shebang, but we explicitly
// invoke `bash` so the script is found even when the user's PATH does not
// expose its directory. The script self-checks for bash 3.2+ at startup.
const bashCmd = 'bash';

// ── Single-source the version ───────────────────────────────────────────
// package.json is the source of truth. Export it so the bash script reports
// the exact published version (MAC_CLEANUP_VERSION) instead of a hand-kept
// literal that could drift.
let pkgVersion = '';
try {
  pkgVersion = require('../package.json').version || '';
} catch (_) {
  /* best-effort — direct checkouts fall back to the literal in the script */
}
const childEnv = pkgVersion
  ? Object.assign({}, process.env, { MAC_CLEANUP_VERSION: pkgVersion })
  : process.env;

// ── Forward argv + stdio + signals ──────────────────────────────────────
const child = spawn(bashCmd, [scriptPath, ...process.argv.slice(2)], {
  stdio: 'inherit',
  env: childEnv,
});

// Propagate common terminate signals so Ctrl+C inside npx hits the bash
// child too — without this, npx may catch the signal and leave a zombie.
const FORWARD_SIGNALS = ['SIGINT', 'SIGTERM', 'SIGHUP', 'SIGQUIT'];
for (const sig of FORWARD_SIGNALS) {
  process.on(sig, () => {
    if (child && !child.killed) {
      try {
        child.kill(sig);
      } catch (_) {
        /* ignore */
      }
    }
  });
}

child.on('error', (err) => {
  console.error('mac-cleanup: failed to launch bash: ' + err.message);
  process.exit(127);
});

child.on('exit', (code, signal) => {
  if (signal) {
    // Re-raise the same signal so our own exit reflects how we died.
    process.kill(process.pid, signal);
    return;
  }
  process.exit(code == null ? 0 : code);
});
