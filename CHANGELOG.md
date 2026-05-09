# Changelog

All notable changes to **mac-cleanup** are documented here. Versions follow
[Semantic Versioning](https://semver.org/) — `MAJOR.MINOR.PATCH`.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/).

---

## [4.3.0] — 2026-05-10

### Added
- **`--profile NAME` presets.** Named bundles of section numbers users
  can invoke instead of memorising lists:
  - `dev` → 1, 2, 3, 4, 23 (developer caches + stale builds)
  - `minimal` → 5, 7, 8, 9, 10 (light, mostly-safe sweep)
  - `cache-only` → 3, 5, 6, 7, 9, 19 (every cache layer)
  - `deep` → 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 17, 19, 23, 26
  - `audit` → 0, 12, 18, 21, 25, 26 (read-only diagnostics)
- **`--exclude "L"`** comma-separated section list to skip. Composes
  cleanly on top of `--all`, `--only`, and `--profile`. Lets you
  subtract sections instead of always retyping the full list. Example:
  `mac-cleanup --profile deep --exclude 14,17`.
- **`--notify`** — fires a native macOS notification (via osascript)
  when the run finishes, with the amount of space freed in the body.
  Useful for long unattended runs and cron jobs.
- **`--check-update`** — opt-in npm registry version check. Curls
  `registry.npmjs.org/macleanup/latest`, compares with the installed
  `SCRIPT_VERSION`, and reports if a newer version is available.
  No telemetry, no automatic checks, no background traffic.
- **GitHub repo polish**:
  - `CODE_OF_CONDUCT.md` (single-maintainer flavour, Contributor
    Covenant inspired).
  - `.github/FUNDING.yml` — sponsor button pointing at the author's
    site.
  - `.github/ISSUE_TEMPLATE/` — structured bug-report and feature-
    request forms with required environment fields. Blank issues
    disabled. Security issues redirected to private email.

### Changed
- Refactored `main()` to resolve sections in a single pipeline:
  `--profile` → `--only` (override) → `--exclude` (filter) → run.
  This composability is now consistent across all three modes.
- `notify_user` is invoked at every successful exit path (interactive
  Q, `--only`, `--all`, `--profile`) so notifications never get
  dropped.
- `check_update_npm` runs early in `main()` so the advisory appears
  before any sections execute.

---

## [4.2.0] — 2026-05-09

### Added
- **`npx` distribution.** Published as
  [`macleanup`](https://www.npmjs.com/package/macleanup) on the public
  npm registry. Users can now run `npx macleanup` with zero install. A
  tiny `bin/mac-cleanup.js` launcher (zero runtime deps) validates
  Darwin and spawns bash with the bundled script. The package registers
  both `macleanup` (primary) and `mac-cleanup` (alias) as bin entries,
  so global-install users can invoke either name.
- **Public npm name `macleanup`** — short, descriptive, trademark-safe,
  and clearly distinct from any third-party Mac cleaner product. The
  internal script filename and historical command name `mac-cleanup`
  are preserved as a bin alias.
- **Persistent log + report locations.** Defaults moved from
  `<repo>/logs/` (which is wiped from npm's cache after `npx` runs) to
  `~/.mac-cleanup/{logs,reports}/`. Stable across every invocation,
  every install method.
- **New CLI flags**:
  - `--logs-dir PATH` — override the persistent logs directory.
  - `--reports-dir PATH` — override the persistent reports directory.
  - `--no-reports` — skip writing per-section `.txt` report files
    (logs still kept).
  - `--cleanup-logs-on-finish` — delete this run's log file at exit
    (default: keep all logs forever).
- **Environment overrides**: `MAC_CLEANUP_LOGS_DIR` and
  `MAC_CLEANUP_REPORTS_DIR` honoured before flag parsing.
- **Branded credits header** written to the top of every log file and
  every report file: tool name + version, author + contact, repo URL,
  npm URL, license summary, run timestamp, host. Each artefact is now
  self-attributing.
- **Sections 25 (launch-items) and 26 (du-report) write `.txt` reports**
  too. Reports added: `launch-audit-YYYY-MM-DD.txt`,
  `disk-usage-YYYY-MM-DD.txt`.
- Session summary now prints both `Logs dir:` and `Reports dir:` plus
  a credit footer linking back to the project.

### Changed
- `mkdir -p` now creates both `LOG_DIR` and `REPORTS_DIR` at startup,
  re-running after any `--logs-dir` / `--reports-dir` override.
- Every existing report writer now routes through a single
  `init_report_file` helper that respects `--no-reports` uniformly.
- The trap on `EXIT INT TERM` resets terminal colours only when colours
  were enabled in the first place.

### Migration
- If you used `<repo>/logs/` from a 4.1.x checkout, those files stay
  where they were. New runs write to `~/.mac-cleanup/`. Move the old
  ones over with:
  ```bash
  mkdir -p ~/.mac-cleanup/logs && mv path/to/repo/logs/* ~/.mac-cleanup/logs/
  ```

---

## [4.1.0] — 2026-05-09

### Added
- **Section 23 — Stale build artefacts.** Find regenerable directories
  (`node_modules`, `vendor`, `dist`, `build`, `.next`, `.nuxt`, `.turbo`,
  `.vite`, `.parcel-cache`, `.svelte-kit`, `.astro`, `.cache`, `target`,
  `Pods`, `coverage`, `.nyc_output`) untouched for N days. Sorted-by-size
  table, multi-select bulk delete with size-totalling confirmation.
- **Section 24 — Large stale files.** Find files ≥N GB whose **both**
  `atime` AND `mtime` are older than N days. Move to Trash for safety.
- **Section 25 — LaunchAgents / LaunchDaemons audit.** Inspect `.plist`
  launch items in `~/Library/LaunchAgents`, `/Library/LaunchAgents`, and
  `/Library/LaunchDaemons`. Flag entries whose `Program`/
  `ProgramArguments[0]` target binary no longer exists.
- **Section 26 — Disk-usage report.** Quick `du -sh` of top-level `$HOME`
  and `~/Library` children. Read-only diagnostic. Added to safe batch.
- **Multi-select prompt** with `all` / `none` / `1,3,5-7` / reverse-range
  syntax, used by sections 21, 23, 24, 25.
- **Threshold prompts** at the start of sections 21, 23, 24 — override
  defaults per-run without retyping flags.
- **Bulk-uninstall mode** for section 21 (apps unused N+ days) in
  addition to the existing one-by-one review.
- New CLI flags: `--version` / `-V`, `--list`, `--no-color`,
  `--scan-roots "p1:p2:p3"`, `--stale-build-days N`,
  `--large-file-days N`, `--large-file-size-gb N`.
- **Preflight checks**: refuse to run on non-Darwin, require bash 3.2+.
- **Hardened path quoting** for `osascript` (escapes `\` and `"` so weird
  filenames don't break Finder Trash moves).
- **Terminal colour reset** in the EXIT/INT/TERM trap so an interrupted
  run doesn't leave the shell coloured.
- Single-source `SECTION_CATALOGUE` shared by `--list`, `--help`, and
  the menu — labels can no longer drift out of sync.

### Changed
- Section 21 now offers a `[R]eview / [B]ulk / [N]o` mode chooser after
  listing idle apps.
- Companion-data discovery (sections 21) extracted into a reusable inner
  helper so bulk and review modes share the same logic.

### Documentation & release
- Added [README.md](README.md), [LICENSE.md](LICENSE.md),
  [NOTICE](NOTICE), [SECURITY.md](SECURITY.md),
  [CONTRIBUTING.md](CONTRIBUTING.md), CHANGELOG.md.
- Removed legacy `backups/` and `legacy/` folders (old modular split and
  one-off scripts) from the repository tree.

---

## [4.0.0] — 2026-04-17

### Changed
- **Complete rewrite** as a single self-contained script
  (`mac-cleanup.sh`) replacing the previous modular split (`lib/` +
  `sections/`) and four standalone legacy scripts. Identical feature set
  with a unified state, logging, and prompt model.
- All twenty-three pre-existing sections now share one `safe_rm_rf`,
  one `clean_dir_contents`, and one `confirm` / `confirm_yes` helper.
- `--all` no longer auto-runs destructive sections — only the ten
  read-only / cache-only sweeps.

### Added
- `--threshold N` for "unused app" detection (default 100 days).
- Top-level menu `[D]` toggle for dry-run, `[Y]` for assume-yes.
- Per-day rolling logs in `logs/`.

---

## [< 4.0]

The pre-4.0 codebase lived as `legacy/` (modular split) and `backups/`
(one-shot scripts). Those folders were removed when the project was
prepared for public release in 4.1.0.
