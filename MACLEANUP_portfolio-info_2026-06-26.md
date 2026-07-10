# MacLeanup — Portfolio Info

Reference Date: 2026-06-26
Project Type: macOS cleanup & maintenance tool — a single-file Bash engine published as a zero-install npm CLI (`macleanup` / `mac-cleanup`), with an in-repo native macOS GUI (Tauri) wrapper
Project Slug: macleanup
Primary Email Reference: aoneahsan@gmail.com
Current Version Reviewed: CLI `4.6.1` (npm) · desktop GUI `4.6.1` (in repo, not yet published)
Last Portfolio Update: 2026-06-26
Next Eligible Update After: 2026-07-03

---

## Identity & Distribution (Authoritative)

| Field | Value |
| --- | --- |
| Project Slug | `macleanup` |
| Public Brand Name | MacLeanup |
| npm Package | `macleanup` — https://npmjs.com/package/macleanup |
| Install / CTA | `npx macleanup` (zero-install) · or `npm install -g macleanup` then `mac-cleanup` |
| Bin names | `mac-cleanup` and `macleanup` (both map to `bin/mac-cleanup.js`) |
| Repository | https://github.com/aoneahsan/macleanup (public; `git+https://github.com/aoneahsan/macleanup.git`) |
| Public URL (Live) | not provided (no marketing/site URL in master JSON) |
| Docs URL | not provided (docs live in-repo under `docs/`) |
| PyPI / Chrome / Play / App Store | N/A (this is a macOS CLI, not a mobile/browser/Python package) |
| Platform constraint | `os: ["darwin"]`, `cpu: ["x64","arm64"]`, `engines.node >= 14`; macOS 11+, bash 3.2+ |
| License | **MIT** (`LICENSE.md`; `package.json` declares `"MIT"`). Permissive OSI open source — use, modify, redistribute, sublicense, and sell, provided the copyright + license notice are kept. Matches the master JSON's `open-source` label. |
| Author | Ahsan Mahmood — aoneahsan@gmail.com — https://aoneahsan.com |
| Payment / Support URL | https://aoneahsan.com/payment?project-id=macleanup&project-identifier=macleanup |
| Funding | `https://aoneahsan.com` (declared in `package.json` `funding`) |
| Agent-Readable Pricing | N/A (free CLI; no paid tiers shipped on npm) |

> **Asks for next refresh:** confirm whether a docs/marketing site URL should be recorded (the `web` and `docs` links are empty in the master JSON). License is now **MIT** — the master JSON's `license: open-source` is accurate (no discrepancy). Decide if/when the Tauri desktop GUI ships to a public channel (it currently lives in `desktop/` but is not published).

---

## Brand Assets

### Logo (SVG — inline)

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 96" role="img" aria-label="MacLeanup">
  <defs>
    <linearGradient id="macleanup-grad" x1="6" y1="6" x2="90" y2="90" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#6E56F7"/>
      <stop offset="0.5" stop-color="#4F8DF0"/>
      <stop offset="1" stop-color="#19D3C5"/>
    </linearGradient>
  </defs>
  <!-- App-icon squircle -->
  <rect x="6" y="6" width="84" height="84" rx="22" fill="url(#macleanup-grad)"/>
  <!-- Hero "clean shine" sparkle -->
  <path fill="#FFFFFF"
        d="M48 22 C51.4 42.3 55.7 46.6 76 50 C55.7 53.4 51.4 57.7 48 78 C44.6 57.7 40.3 53.4 20 50 C40.3 46.6 44.6 42.3 48 22 Z"/>
  <!-- Accent sparkle -->
  <path fill="#FFFFFF" fill-opacity="0.9"
        d="M71 24 C72.6 30 74 31.4 80 33 C74 34.6 72.6 36 71 42 C69.4 36 68 34.6 62 33 C68 31.4 69.4 30 71 24 Z"/>
</svg>
```

> Derived from the real brand marks in `assets/logo/macleanup-mark.svg` and `macleanup-wordmark.svg` (squircle app-icon background with the violet→blue→teal gradient and a white "clean shine" four-point sparkle).

### Color Palette

| Role | Token | Hex | Usage |
| --- | --- | --- | --- |
| Primary | Violet | `#6E56F7` | Brand start of the icon gradient, wordmark text start |
| Primary — mid | Blue | `#4F8DF0` | Gradient midpoint, links/CTAs |
| Secondary | Teal | `#19D3C5` | Gradient end, accent / "fresh & clean" cue |
| Wordmark text — end | Cyan-teal | `#19A8C5` | End stop of the wordmark text gradient |
| Spark / surface | White | `#FFFFFF` | Hero sparkle, light surfaces |
| Status — success | Green | `#30A46C` / `#4ADE80` | "freed space" / success states (desktop GUI) |
| Status — danger | Red | `#FF453A` / `#FF6961` | Destructive-action warnings (desktop GUI) |
| Ink — dark | Near-black | `#1C1C1E` | Dark text / dark surfaces (desktop GUI) |

> The brand gradient (violet `#6E56F7` → blue `#4F8DF0` → teal `#19D3C5`) is defined in both logo SVGs. The status/ink colors are sampled from the Tauri desktop GUI source (`desktop/src`) and follow Apple system-color conventions.

---

## Update History (max 10 records)

| Date | Type | Notes |
| --- | --- | --- |
| 2026-07-10 | Updated | Relicensed the project from the custom Source-Available License v1.0 to **MIT** across `LICENSE.md`, `package.json`, README/docs, and the script header (removed `NOTICE`). This resolves the prior master-JSON `open-source` vs source-available discrepancy — MIT is genuinely OSI open source. |
| 2026-06-26 | Created | First portfolio file for MacLeanup. Facts sourced from `package.json` (v4.6.1), `README.md`, `CHANGELOG.md`, `LICENSE.md`, the `assets/logo/` SVGs, and the `desktop/` Tauri app. Identity table reconciled against the master JSON; license discrepancy (open-source vs source-available) flagged honestly. |

---

## One-Line Summary

MacLeanup is a safe-by-default macOS cleanup & maintenance CLI — one ~3,600-line Bash engine with 28 targeted sections, a real `--dry-run`, per-section confirmations, and zero-install delivery via `npx macleanup`, plus an in-repo native macOS GUI (Tauri) wrapper.

## Elevator Pitch

Most Mac cleaners either delete too aggressively (and break things) or do too little (and leave gigabytes behind). MacLeanup sits in the middle: a single, inspectable Bash script that confirms before every destructive action, tells you what each path is, has a genuine `--dry-run`, and skips Apple-managed caches. It ships as a zero-dependency npm package you can run with one command — `npx macleanup` — so there's no curl-pipe-bash, no Homebrew tap, no signing-key surface. Twenty-eight sections cover developer caches (Xcode, Gradle, npm/yarn/pnpm/brew/pip/pod/cargo/go), Docker prune, browser caches, stale `node_modules`/build artefacts, large dormant files, LaunchAgents audits, and more — each gated behind clear prompts, with the deepest/irreversible sections excluded from `--all` unless you explicitly opt in. Reports and logs are written to `~/.mac-cleanup/` so they survive every `npx` run.

## What This Project Is About

MacLeanup is a maintenance tool for macOS power users and developers who want to reclaim disk space without trusting an opaque "cleaner app." The whole tool is two files: `mac-cleanup.sh` (~3,593 lines of plain bash) and `bin/mac-cleanup.js` (~104 lines of Node that only spawns bash — no analytics, no network calls). The design is conservative by intent: destructive ops always prompt unless you pass `--yes`; `--dry-run` routes every delete through no-op helpers; apps are moved to Trash (recoverable) rather than `rm`-ed; system caches need explicit `sudo` and are skipped (not silently bypassed) if sudo is unavailable; and the deepest sections (root system caches, Time Machine snapshots, `/private/var/folders` wipe, app uninstall, large-stale-file deletes) are never part of `--all` unless you add `--i-understand-deep`. A two-condition delete gate (not used by active software AND untouched by both `atime` and `mtime` for ≥100 days, configurable) protects non-cache deletes in the riskiest sections. An optional native macOS GUI (Tauri) lives in `desktop/` and wraps the same script in `--json` mode without reimplementing any cleanup logic.

## Vision

A macOS maintenance tool people can actually trust — every line readable, every destructive action confirmed, every claim verifiable — delivered with zero install friction.

## Mission

Give Mac developers and power users a single, safe, inspectable command to reclaim disk space across caches, build artefacts, and dormant files; never delete without consent; never phone home; and make the safest path the default one.

## Tech Stack

| Layer | Technology |
| --- | --- |
| Core engine | Bash 3.2+ (single file, `mac-cleanup.sh`, ~3,593 lines, zero runtime dependencies) |
| npm launcher | Node `>=14` (`bin/mac-cleanup.js`, ~104 lines — only spawns bash) |
| Distribution | npm package `macleanup` (zero-install via `npx`, or `npm i -g`); also runnable as a direct git checkout (`./mac-cleanup.sh`, no Node needed) |
| Platform | macOS 11+ only (`os: ["darwin"]`, `cpu: ["x64","arm64"]`) |
| Output formats | Human-readable menu, `--no-color`, `--quiet`, and `--json` one-line run summary (pipe to `jq`) |
| Persistence | `~/.mac-cleanup/{logs,reports}/` — dated session logs + per-section `.txt` reports with branded credits headers |
| Config | `~/.mac-cleanuprc` (key=value defaults), env vars (`MAC_CLEANUP_LOGS_DIR`, `MAC_CLEANUP_REPORTS_DIR`), CLI flags (flags override) |
| Desktop GUI (in repo) | Tauri (Rust core + React + Vite + TypeScript), macOS system WebView (~5–10 MB `.app`), Firebase Auth + Firestore for a Google-sign-in free-run gate |
| Quality gates | `bash -n` syntax check, `node -c`, version-parity check between `package.json` and the script's `MAC_CLEANUP_VERSION` fallback, `prepublishOnly` guard |
| License | MIT |

## Feature Catalog

- **Twenty-eight targeted sections** — from a read-only system health/process monitor (0) through developer caches (Xcode/DerivedData/simulators, Android/Gradle, package managers), Docker prune, user/system caches, logs, temp files, update caches, Trash, Time Machine local snapshots, orphaned app-data scan, `periodic` maintenance, deep `/private/var/folders` cache, installer-leftover and large-files reports, iOS/Xcode backups & archives, browser caches across the Chromium and Firefox families, DNS/mDNS reset, idle-app review/uninstall, purgeable-space trigger, stale build artefacts, large stale files, LaunchAgents/LaunchDaemons audit, disk-usage report, and macOS UI maintenance (QuickLook + font caches).
- **Real `--dry-run`** — every destructive call routes through helpers that no-op in dry mode; `--dry-run --all` previews the safe batch without touching anything.
- **Per-section confirmation** — destructive ops always prompt unless `--yes`; section 14 also requires a typed `yes`.
- **Two-condition delete gate** — non-cache deletes (sections 12, 21, 23, 24) only auto-delete when an item is both unused by active software AND untouched by `atime` AND `mtime` for ≥100 days (`--idle-days N`, `0` disables).
- **Age-aware cache pruning** — `--cache-age-days` keeps anything opened OR modified within the window, even if downloaded long ago.
- **Deep-section opt-in** — root system caches, Time Machine snapshots, `/private/var/folders` wipe, app uninstall, and large-stale-file deletes are excluded from `--all` unless `--i-understand-deep` is also passed.
- **Profiles** — named bundles: `dev`, `minimal`, `cache-only`, `deep`, `audit`; combine with `--exclude` to subtract sections.
- **Flexible scoping** — `--only "5,7,8,9"`, `--scan-roots`, `--exclude-path`, and per-section threshold flags (`--threshold`, `--cache-age-days`, `--stale-build-days`, `--large-file-days`, `--large-file-size-gb`).
- **Interactive multi-select** — `all`, ranges (`1,3,5-7,12`), reverse ranges that auto-swap.
- **Persistent logs & reports** — written to `~/.mac-cleanup/` (never inside the npx cache), each with a self-attributing credits header; `--no-reports`, `--cleanup-logs-on-finish`, `--prune-history N`, `--logs-dir`, `--reports-dir`.
- **Zero telemetry** — no network calls from the script; the Node launcher only spawns bash.
- **Built-in help/feedback** — `--contact`, `--feedback`, `--report-issue` (prefilled, local-first, nothing auto-sent), `--stats`, `--check-update`, plus a one-time welcome screen.
- **Toolchain-safety allowlist** — `CRITICAL_HOME_DIRS` refuses to enter `~/.bun`, `~/.pnpm-store`, `~/.volta`, etc. (added in 4.3.1 after a 4.3.0 regression).
- **Native macOS GUI (in repo)** — Tauri wrapper streaming the script's `--json` output to a React UI with dry-run preview and gated deep sections.

## Hidden Facts & Unique Angles

- **Two files, everything else is documentation** — the entire tool is `mac-cleanup.sh` (~3,593 lines of bash) + a ~104-line Node spawner. You can read every line before you run it, which is the whole point.
- **Zero-install, zero-trust delivery** — `npx macleanup` avoids curl-pipe-bash, a Homebrew tap, and any signing-key surface; npm fetches it, runs it, reclaims the cache, and your reports survive in `~/.mac-cleanup/`.
- **`atime` AND `mtime`, not just `mtime`** — a Gradle distribution you invoke monthly, or a `node_modules` your IDE reads for autocomplete, keeps recent atime and survives every pass. This two-clock rule is the safety insight most cleaners miss.
- **Permissive MIT license** — README states it plainly: read, run, learn, fork, redistribute, and build on it, with the copyright + license notice kept.
- **Ships a built-in recovery guide** — the README documents how a 4.3.0 bug could break global toolchains and exactly how to restore bun/pnpm/yarn/nvm/Volta/brew, then explains the 4.3.1 allowlist fix. Owning and documenting a regression is rare.
- **Deep sections are opt-in even when unattended** — `--yes` alone never enables the irreversible sections; you must add `--i-understand-deep`.
- **Same flags everywhere** — identical interface across `npx`, the global `mac-cleanup` bin, and a raw `./mac-cleanup.sh` checkout.
- **The GUI reimplements nothing** — the Tauri desktop app runs the bundled script in `--json` mode, so safety rules and dry-run guarantees come straight from the one source of truth.
- **Version parity is enforced at publish time** — `prepublishOnly` fails the publish if `package.json`'s version isn't the script's `MAC_CLEANUP_VERSION` fallback.

## Benefits for Users

- **Mac developers** — reclaim gigabytes from Xcode/DerivedData, Gradle, package-manager caches, Docker, and stale `node_modules` with one command and a dev profile.
- **Power users / sysadmins** — scriptable, unattended sweeps (`--all --yes --quiet`, `--json | jq`) for cron, plus audit-only profiles that change nothing.
- **The cautious** — a real `--dry-run`, per-section prompts, Trash-not-`rm` for apps, and deep sections gated behind explicit opt-in.
- **The privacy-minded** — zero network calls, zero telemetry; everything stays in `~/.mac-cleanup/`.
- **The skeptical** — two readable files; inspect the exact `rm`/`sudo` behaviour before trusting it.

## Value & Potential

MacLeanup pairs a sharply-scoped problem (macOS disk reclamation) with a trust-first engineering posture that reads well in portfolio and hiring conversations: a single auditable Bash engine, a zero-install npm delivery path, a documented safety model, and a permissive MIT license. It is already shipped on npm at v4.6.1 with a 28-section feature surface and a detailed changelog. Growth paths are concrete: publishing the in-repo Tauri desktop GUI to a public channel, an optional docs/marketing site, and broader profile presets — all without changing the conservative core. Monetization, if any, routes through the GUI's sign-in gate and aoneahsan.com/payment rather than the free CLI.

## Resume / CV Bullets

- Built MacLeanup, a safe-by-default macOS cleanup & maintenance CLI — a single ~3,593-line zero-dependency Bash engine spanning 28 sections — and published it to npm (`macleanup`, v4.6.1) with zero-install `npx` delivery via a ~104-line Node launcher.
- Designed a layered safety model: a genuine `--dry-run` (every delete routed through no-op helpers), per-section confirmations, Trash-not-`rm` app removal, sudo-gated system sections, and irreversible sections excluded from `--all` unless an explicit `--i-understand-deep` flag is added.
- Implemented a two-condition delete gate using both `atime` and `mtime` (≥100 days, configurable) plus a `CRITICAL_HOME_DIRS` allowlist to protect toolchain directories — shipped after owning and documenting a prior regression with a full user recovery guide.
- Delivered a configurable interface (profiles, `--only`/`--exclude`, per-section thresholds, `~/.mac-cleanuprc`, env vars, `--json` summaries) with persistent self-attributing logs/reports in `~/.mac-cleanup/` and zero telemetry (no network calls).
- Wrapped the same engine in a native macOS GUI (Tauri: Rust + React + Vite) that streams the script's `--json` output without reimplementing cleanup logic, with a Firebase-backed Google-sign-in free-run gate.

## LinkedIn / Portfolio Paragraph

MacLeanup is a safe-by-default macOS cleanup & maintenance tool I built as a single, inspectable Bash engine (~3,593 lines, zero dependencies) and published to npm so anyone can run it with one command: `npx macleanup`. It covers 28 targeted sections — developer caches (Xcode, Gradle, npm/yarn/pnpm/brew/pip/pod/cargo/go), Docker prune, browser caches, stale `node_modules`, large dormant files, LaunchAgents audits, and more — and treats safety as the product: a real `--dry-run`, per-section confirmations, Trash-not-`rm` for apps, sudo-gated system sections, and a two-condition delete gate (untouched by both `atime` and `mtime` for 100+ days) so the tools and files you actually use survive every pass. There's no telemetry and no network calls; logs and reports stay on your machine. An in-repo native macOS GUI (Tauri) wraps the same script in `--json` mode without reimplementing a single delete. It's MIT licensed — read it, run it, fork it, build on it.

## Social Content Angles (for ChatGPT content project)

- Why a Mac cleaner should be two readable files, not a closed binary you have to trust.
- The `atime` AND `mtime` rule: how to delete stale `node_modules` without nuking the ones your IDE still reads.
- Zero-install, zero-trust: shipping a system tool as `npx macleanup` instead of curl-pipe-bash.
- Designing a real `--dry-run` — routing every destructive call through a no-op helper.
- Owning a regression in public: the 4.3.0 toolchain bug, the recovery guide, and the `CRITICAL_HOME_DIRS` fix.
- Why I gate the scariest sections behind `--i-understand-deep` even when you pass `--yes`.
- Choosing a license: why MIT maximizes adoption for a free developer tool while keeping the author protected by the AS-IS warranty disclaimer.
- Wrapping a CLI in a Tauri GUI that reimplements nothing (the script's `--json` mode is the contract).
- 28 cleanup sections, one bash file: how I keep it maintainable.
- No telemetry by design: a system tool that makes zero network calls.

## SEO / AEO Metadata

- Meta description (150–160 chars): MacLeanup is a safe-by-default macOS cleanup CLI — 28 sections, real dry-run, per-section confirms, zero telemetry. Run it with `npx macleanup`.
- Primary keywords: macOS cleanup tool, mac disk space cleaner, npx mac cleanup, free up mac storage, clear Xcode DerivedData, delete stale node_modules, macOS maintenance CLI, mac cache cleaner, safe mac cleaner, command-line mac cleanup.
- Long-tail / GEO keywords (AI-search): "safe macOS cleanup tool with dry-run", "reclaim mac disk space from developer caches", "zero-install mac cleaner via npx", "delete stale node_modules safely by atime and mtime", "open source mac cleanup script you can read".
- Suggested og:title: MacLeanup — the safe, inspectable macOS cleanup CLI
- Suggested og:description: 28 sections, a real `--dry-run`, per-section confirmations, and zero telemetry — run it with one command: `npx macleanup`.

## Known Constraints (honest framing)

- **macOS only** — `os: ["darwin"]`, x64/arm64, macOS 11+, bash 3.2+. Not for Linux/Windows.
- **MIT licensed** — permissive OSI open source: use, modify, redistribute, sublicense, and sell, keeping the copyright + license notice. The master JSON's `license: open-source` is now accurate.
- **It runs `rm -rf` and `sudo`** — safe-by-default, but the user is responsible for verifying outputs; back up (Time Machine / `tmutil snapshot`) before any cleanup run.
- **Section 14 needs a reboot** and a typed `yes`; the deepest sections require `--i-understand-deep` to run unattended.
- **Desktop GUI is in-repo, not published** — the Tauri app under `desktop/` (with a Firebase sign-in gate) is built but not on a public download channel yet.
- **No marketing/site or docs URL recorded** — `web` and `docs` are empty in the master JSON; docs currently live in-repo under `docs/`.
- **No automated test suite** — verification is via `bash -n`, `node -c`, and a version-parity guard rather than unit tests.

## Generic Hashtags (always include in posts)

#Aoneahsan #AhsanMahmood #Zaions #BestOpenSourceCommunityProject #TopFree #SaaSApp

## Top 20 Hashtags

#MacLeanup #macOS #MacCleanup #DiskCleanup #CLI #Bash #DeveloperTools #npm #npx #MacApp #DevOps #SysAdmin #OpenSource #MITLicense #Tauri #NodeJS #MacOSdev #CleanMyMac #DiskSpace #BuildInPublic

---

## File Usage Rule

Refresh at least once per week (MANDATORY). Do not refresh more than once per 3 days. Keep only the 10 most recent history records. Filename always carries the last-updated date. Final destination: `/Users/pc/Documents/ahsan-work/ahsan-notebook/static/assets/personal/projects-info-as-portfolio-item/apps/MACLEANUP_portfolio-info_<YYYY-MM-DD>.md`.
