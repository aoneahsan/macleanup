# Changelog

All notable changes to **mac-cleanup** are documented here. Versions follow
[Semantic Versioning](https://semver.org/) — `MAJOR.MINOR.PATCH`.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/).

---

## [4.4.1] — 2026-05-10  •  DOCUMENTATION RELEASE

Documentation-only release. **No script behaviour changes.** A complete
end-user documentation set has been added under `docs/`, covering every
feature, flag, profile, and section of the tool in detail.

### Added
- **`docs/`** — 13-page documentation set (~5,000 lines):
  - `docs/README.md` — index and navigation
  - `docs/getting-started.md` — first-run walkthrough with requirements
  - `docs/installation.md` — all 3 install methods (`npx`, global `npm`,
    direct git checkout) with troubleshooting
  - `docs/cli-reference.md` — every command-line flag, with examples,
    defaults, exit codes, env vars, and common compounds
  - `docs/sections.md` — full reference for all 27 sections (paths
    touched, sudo requirements, confirmations, dry-run behaviour,
    reports written, CLI flags, safety rules, edge cases)
  - `docs/profiles.md` — all 5 named profiles (`dev`, `minimal`,
    `cache-only`, `deep`, `audit`) explained
  - `docs/safety-model.md` — design principles, the two-condition rule,
    `CRITICAL_HOME_DIRS` allowlist, sudo handling, dry-run guarantees
  - `docs/reports-and-logs.md` — output file layout, branding header,
    `--stats`, privacy, cleanup commands
  - `docs/recovery-guide.md` — restoring tools after a 4.3.0 run
    (`bun`, `pnpm`, `yarn`, `nvm`, `Volta`, `asdf`, `Deno`, `rbenv`,
    `pyenv`, `rustup`, brew autoremove victims)
  - `docs/examples-cookbook.md` — recipe-style commands for common
    goals (cron, dev cleanup, stale `node_modules`, large files, fleet
    use, anti-patterns)
  - `docs/faq.md` — plain-English answers to common questions
  - `docs/troubleshooting.md` — symptom → cause → fix mappings
  - `docs/author.md` — author/credits page with bio, links,
    "Hire Ahsan" section, citation snippet, license summary

### Changed
- README badge bumped to 4.4.1.

### Notes
- `docs/` is **not** included in the published npm tarball (the `files`
  array is unchanged). Read the docs on GitHub:
  <https://github.com/aoneahsan/macleanup/tree/main/docs>.
- No code paths were modified. `mac-cleanup --version` now reports
  `4.4.1`; everything else is byte-identical to 4.4.0.

---

## [4.4.0] — 2026-05-10  •  USER-FACING POLISH (final 4.x feature drop)

User-experience polish round, no behaviour changes to the cleanup
sections themselves. **Crash reporting + feedback channels are now
first-class** but the tool's no-telemetry promise is unchanged —
nothing is ever auto-sent.

### Added
- **`--contact`** — prints a tidy author contact card (email, website,
  LinkedIn, GitHub, npm, repo) and exits.
- **`--feedback`** — opens the system mail client with a prefilled
  subject + body addressed to the author. Falls back to printing the
  email address if `open` is unavailable.
- **`--report-issue`** (alias `--report-bug`) — collects environment
  info **entirely locally** (script version, macOS version, chip,
  RAM, bash version, Node version, latest log path), URL-encodes it
  into a GitHub issue body, and opens a pre-filled new-issue page in
  the browser. The last 50 lines of the most recent log are copied to
  the clipboard via `pbcopy` if available, so the user can paste them
  into the issue's "Latest log excerpt" section. **Nothing is
  transmitted until the user clicks Submit on github.com.**
- **`--stats`** — read-only summary of `~/.mac-cleanup/`: log count,
  report count, total sizes, oldest/newest log, recent reports list.
  Useful for checking history without `cd`-ing.
- **First-run welcome screen** — one-time intro shown the first time
  someone runs the tool on a machine (marker file
  `~/.mac-cleanup/.welcomed`). Explains the dry-run rule, the persistent
  paths, the two-condition safety rule, and the contact flags. Skipped
  for batch / non-TTY invocations.
- **EXIT-trap crash hint** — when the script exits non-zero (other
  than rc=2 which is "user error" from bad CLI args), it now prints a
  yellow hint pointing the user at `--report-issue` and `--feedback`.
  No log slurp, no auto-submit — just a reminder of the two channels.

### Changed
- Help groups improved: contact / feedback / stats flags listed
  together as "Get help" so they're discoverable.
- Internal: extracted `url_encode` helper (uses macOS-shipped python3)
  for the mailto + GitHub issue URL prefilling.

### Deliberately not added (per design)
- **No GUI.** A SwiftUI / Electron wrapper would push the install size
  from 50 KB to 100+ MB and require code-signing, breaking the
  "single bash file you can audit" promise that's in the README. The
  TUI gets all the polish.
- **No automatic crash collection.** Crash dumps are user-triggered
  via `--report-issue`. The tool never phones home.
- **No analytics, no opt-in telemetry, no install-count beacon, no
  feature-usage stats.** The whole network footprint stays at "zero
  unless you explicitly pass `--check-update`."

---

## [4.3.3] — 2026-05-10  •  TWO-CONDITION RULE FOR NON-CACHE DELETES

**The principle**: any uninstall/delete that targets a piece of software,
tool, or user data (i.e. **anything that isn't pure cache**) now must
satisfy **both**:

1. **Not used by any active software/tool** — the existing detection
   (no installed-app match for orphan data, broken target binary for
   LaunchAgents, no last-used signal for idle apps).
2. **Not touched by the user (atime AND mtime) for ≥ N days**, where
   N defaults to 100. Configurable via the new `--idle-days N`.

This is the second half of the rule the user explicitly asked for. It
prevents the failure mode where condition (a) was true but condition
(b) was missed, e.g. a Container directory whose owning app couldn't
be matched by bundle ID but was still being touched by something
(spotlight indexer, a service, a daemon).

### Fixed
- **Section 12 (orphaned app data)** now requires the candidate to be
  both orphan AND idle ≥ ${IDLE_THRESHOLD_DAYS_DEFAULT} days. Items orphan-shaped but touched
  recently are skipped with a count: *"Skipped N orphan-shaped entries
  that were touched within the last 100 days (probably still in use)."*
- **Section 23 (stale build artefacts)** now uses both `-atime +N` AND
  `-mtime +N` in the find expression, mirroring the rule. A
  `node_modules` whose IDE has been reading files (autocomplete /
  intellisense) keeps a recent atime even if `npm install` hasn't run
  in months — it'll no longer be flagged.

### Added
- **`--idle-days N`** — universal idle threshold for non-cache deletes
  in sections 12 and 23. Default 100. The dedicated
  `--stale-build-days N` still wins if the user passes it explicitly,
  but `--idle-days N` is now the canonical knob for "I want a stricter
  100-day rule everywhere."
- **Sections 16 (iOS backups) and 17 (Xcode archives)** now display
  per-item age in days plus a tag — `[idle ≥100d]` for safe-to-delete
  items, `(recent — likely keep)` otherwise. Doesn't auto-skip (these
  sections are interactive review by design), but lets the user apply
  the rule by hand without consulting external tooling.
- New constant `IDLE_THRESHOLD_DAYS_DEFAULT=100` exported as the
  single source of truth so future sections can reuse it.

### Coverage map
| Section | Condition (a) — not in active use | Condition (b) — idle ≥100d |
|---:|---|---|
| 12 — Orphan app data | ✅ no installed-app match | ✅ atime+mtime check (NEW) |
| 16 — iOS backups | n/a (user data) | ✅ age tag in UI |
| 17 — Xcode archives | n/a (project artefacts) | ✅ age tag in UI |
| 21 — Idle apps | n/a (user-owned) | ✅ already (5-source last-used check) |
| 23 — Stale build artefacts | n/a (regenerable) | ✅ atime+mtime (NEW) |
| 24 — Large stale files | n/a (user files) | ✅ already |
| 25 — Orphan LaunchAgents | ✅ target binary missing | n/a (broken plist is bad regardless of age) |

### Migration
No flag changes required. Behaviour is purely safer-by-default. To get
the old (4.3.2) behaviour back you'd have to explicitly pass
`--idle-days 0`.

---

## [4.3.2] — 2026-05-10  •  AGE-AWARE CACHE PRUNING

**The 100-day rule, now applied to every cache.**
`npx macleanup@latest` will fetch this version.

### Fixed
- **Sections 1 (Xcode), 2 (Android/Gradle), 3 (package managers) no
  longer wipe entire caches.** Previously these used `clean_dir_contents`
  which deleted every file regardless of whether it had been touched
  recently. That was the bug behind reports like *"my Gradle 8.13
  distribution that I use every 1–2 months got deleted"* — the file's
  mtime stayed at download time but its atime was recent each time
  Gradle ran.
  Now uses a new `clean_dir_unused` helper that requires **both atime
  AND mtime ≥ N days old** before removing a file. Anything you've
  actually invoked, even rarely, keeps a recent atime and survives
  every pass.

### Changed
- **Default age threshold for cache pruning is now 100 days.**
  Configurable via `--cache-age-days N`. Use `--cache-age-days 0` to
  restore the pre-4.3.2 full-wipe behaviour.
- **Affected directories** (now age-aware):
  - Section 1: `Xcode/DerivedData`, `iOS/tvOS/watchOS DeviceSupport`,
    `Xcode/Logs`, `Xcode/DocumentationCache`, `Caches/com.apple.dt.Xcode`
  - Section 2: `~/.gradle/caches`, `~/.gradle/wrapper/dists`,
    `~/.android/cache`, `~/.android/build-cache`
  - Section 3: `~/.pub-cache`, `~/.cargo/registry/cache`,
    `~/.cargo/git/db`, `~/go/pkg/mod/cache`, `~/.bundle/cache`,
    `~/.gem/cache`
- **Section 3 no longer runs `go clean -modcache` by default.** That
  command wipes the entire Go module cache — same problem as the
  Gradle wipe. Now uses age-aware prune; `go clean -modcache` is only
  run when `--cache-age-days 0` is explicitly passed.
- Confirmation prompts updated to mention the threshold (e.g. *"Prune
  Gradle distributions unused for 100+ days?"*) so you know what's
  actually being asked.

### Added
- New flag: `--cache-age-days N` (default 100, 0 for full wipe).
- New helper: `clean_dir_unused dir days` — finds files where both
  atime and mtime are ≥ N days old, removes them, then collapses
  newly-empty directories in up to 4 passes so nested empties roll up.

### Unchanged (deliberately)
These full-wipes are still appropriate because the data either
regenerates instantly or is explicitly opted-in:
- Browser caches (section 19) — pages re-cache on next visit.
- `~/Library/Caches/<non-Apple-app>` (section 5) — apps regenerate.
- `~/Library/Saved Application State` — state, not data.
- `~/Library/Updates` — installer downloads.
- `~/.Trash` (section 10) — that's the whole point of Trash.
- `~/Library/Developer/CoreSimulator` — only wiped when user
  explicitly chooses "Wipe ALL CoreSimulator data".
- Tool-builtin commands: `npm cache clean --force`, `yarn cache clean`,
  `pnpm store prune`, `pip cache purge`, `pod cache clean --all`,
  `brew cleanup -s`. These are designed by their tool authors to be
  safe and to wipe only redownloadable artefacts.

### Migration
No flag changes required. Behaviour change is purely safer-by-default.
If you scripted `npx macleanup --all --yes` and want exactly the old
wipe-everything behaviour: add `--cache-age-days 0`.

---

## [4.3.1] — 2026-05-10  •  SAFETY FIX

**Users on 4.3.0: please upgrade immediately.**
`npx macleanup@latest` will fetch this version.

### Fixed
- **Section 23 no longer enters toolchain or config directories.**
  4.3.0 could match `node_modules`-shaped folders nested inside
  `~/.bun`, `~/.pnpm-store`, `~/.local/share/pnpm`, `~/.npm-packages`,
  `~/.volta`, `~/.asdf`, etc. and flag them for deletion. Selecting
  "all" in the multi-select prompt would then break globally-installed
  tools that lived under those toolchain managers. **Fixed via a hard
  `CRITICAL_HOME_DIRS` allowlist** (35+ entries: `.nvm`, `.bun`,
  `.fnm`, `.volta`, `.asdf`, `.deno`, `.rbenv`, `.pyenv`, `.rustup`,
  `.cargo`, `.gradle`, `.m2`, `.cocoapods`, `.pub-cache`, `.npm`,
  `.yarn`, `.pnpm-store`, `.pnpm`, `.npm-packages`, `.cache`,
  `.config`, `.docker`, `.android`, `.vscode`, `.cursor`, `.idea`,
  `.claude`, `.ssh`, `.gnupg`, `.aws`, `.azure`, `.gcloud`, `.kube`,
  `.git`, …) — section 23 now refuses to enter these regardless of
  mtime, regardless of whether their basename matches a pattern.
  Defended in two layers: in the `find` predicates *and* in a
  post-find filter that skips any candidate whose path falls under
  any critical dir.
- **Section 23 no longer silently falls back to scanning `$HOME`.**
  If none of the standard dev folders exist (`~/Projects`, `~/Code`,
  `~/Developer`, `~/dev`, `~/repos`, `~/work`, `~/Documents`,
  `~/Desktop`, `~/Downloads`), the section now exits with a clear
  message instructing the user to pass `--scan-roots`. Implicit
  `$HOME` scan was the trigger for the toolchain-dir bug.
- **Removed `.cache` from `STALE_BUILD_PATTERNS`.** It matched
  `~/.cache` and any project's nested `.cache/` indiscriminately,
  which was always too broad. Per-tool cache cleaning continues in
  section 3 where the matching is precise.

### Changed
- **`brew autoremove` is now opt-in via `--brew-autoremove`.** It was
  previously part of section 3's default flow. `brew autoremove` can
  uninstall formulae that were originally installed as dependencies
  and are now considered unused — in practice this can take down
  `node`, `python`, `openssl`, etc. and silently break every globally
  installed tool that depended on them. Section 3 now stops at
  `brew cleanup -s` (cache + old versions only) unless you explicitly
  pass `--brew-autoremove`.
- `~/Downloads` was added to the standard dev-folder list since it's
  often where ad-hoc projects accumulate.

### Added
- New flag: `--brew-autoremove` to opt back into the previous behaviour.
- New README section: **🚑 Recovery — if 4.3.0 broke a global tool**.
  Step-by-step commands to restore bun, pnpm globals, yarn, nvm, npm
  globals, Volta, asdf, fnm, Deno, rbenv, pyenv, rustup, plus
  `brew log`-based recovery for autoremoved formulae.

### Migration
No flag changes required for existing users. The behavioural changes
are all *safer defaults*. To get the old behaviour back you'd have to
explicitly pass `--brew-autoremove` and explicitly pass `--scan-roots`
(deliberately).

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
