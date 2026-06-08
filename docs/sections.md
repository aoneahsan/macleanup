# Sections (0–27) — The Twenty-Eight Cleanup Sections

> Every cleanup operation `mac-cleanup` performs lives inside one of 28
> numbered sections. This page is the complete reference: what each
> section cleans, which paths it touches, whether it needs `sudo`, what
> confirmations it asks for, and which CLI flags tune its behaviour.

Use the table of contents to jump to a section, or read top-to-bottom
once to build a full mental map.

> **About the format** — Each section reference follows the same shape:
> _what it does_, _paths touched_, _sudo_, _confirmations_, _dry-run
> behaviour_, _reports written_, _CLI flags_, _safety rules_, _edge cases_.
> If you only need to know "is this safe?" — read the _safety rules_ box.

---

## Table of contents

| # | Section | Sudo? | Type |
|---|---|:-:|---|
| [0](#section-0--system-health--process-monitor) | System health & process monitor | — | Read-only |
| [1](#section-1--xcode-caches-deriveddata-simulators) | Xcode caches, DerivedData, simulators | — | Cache prune |
| [2](#section-2--android--gradle-caches) | Android / Gradle caches | — | Cache prune |
| [3](#section-3--package-manager-caches) | Package manager caches | — | Cache prune |
| [4](#section-4--docker-prune) | Docker prune | — | System prune |
| [5](#section-5--user-caches) | User caches (`~/Library/Caches`) | — | Selective wipe |
| [6](#section-6--system-caches) | System caches (`/Library/Caches`) | sudo | Selective wipe |
| [7](#section-7--logs) | Logs (user + system) | sudo | Time-window prune |
| [8](#section-8--temp-files) | Temp files | — | Time-window prune |
| [9](#section-9--update-caches) | Update caches | sudo | Wipe |
| [10](#section-10--empty-trash) | Empty Trash | — | Wipe (confirmed) |
| [11](#section-11--time-machine-local-snapshots) | Time Machine local snapshots | sudo | Snapshot delete |
| [12](#section-12--orphaned-app-data) | Orphaned app data scan | — | Interactive sweep |
| [13](#section-13--system-maintenance-periodic) | System maintenance (`periodic`) | sudo | System task |
| [14](#section-14--deep-cache-privatevarfolders) | Deep cache `/private/var/folders` ⚠ **needs reboot** | sudo | Deep wipe |
| [15](#section-15--installer-leftovers-report) | Installer leftovers report | — | Read-only |
| [16](#section-16--ios--ipados-device-backups) | iOS / iPadOS device backups | — | Per-item review |
| [17](#section-17--xcode-archives) | Xcode archives | — | Per-item review |
| [18](#section-18--large-files-report) | Large files report | — | Read-only |
| [19](#section-19--browser-caches) | Browser caches | — | Wipe (confirmed) |
| [20](#section-20--dns--mdns-reset) | DNS / mDNS reset | sudo | System action |
| [21](#section-21--apps-unused-n-days) | Apps unused N+ days | — | Bulk uninstall (multi-select) |
| [22](#section-22--purgeable-space-trigger) | Purgeable space trigger | — | System action |
| [23](#section-23--stale-build-artefacts) | Stale build artefacts | — | Bulk delete (multi-select) |
| [24](#section-24--large-stale-files) | Large stale files | — | Bulk move-to-Trash |
| [25](#section-25--launchagents--launchdaemons-audit) | LaunchAgents / LaunchDaemons audit | sudo* | Per-item review |
| [26](#section-26--disk-usage-report) | Disk usage report | — | Read-only |
| [27](#section-27--macos-ui-maintenance-quicklook--font-caches) | macOS UI maintenance: QuickLook + font caches | sudo† | UI cache reset |

\* Sudo only when removing items under `/Library/`.
† Sudo only for the optional system-wide font-cache clear.

---

## Section 0 — System health & process monitor

> **Read-only diagnostic.** No deletions. Nothing is touched.

The first stop in any cleanup session: a snapshot of the machine's current
state. Run this before and after a big sweep to see what changed.

**What it reports:**

- **macOS version** (`sw_vers -productVersion`)
- **Chip** (`uname -m`) and a friendly label — Apple Silicon / Intel
- **RAM** in GB (`sysctl -n hw.memsize`)
- **Uptime** (`uptime`)
- **Disk free** (`df -h /`)
- **Memory pressure** (`memory_pressure` if available, otherwise `vm_stat`)
- **Top 5 CPU processes** (`ps -Aceo pcpu,pid,comm | sort -k1 -n -r`)
- **Top 5 memory processes** (`ps -Aceo pmem,pid,comm | sort -k1 -n -r`)
- **Battery** (laptops only) — cycle count, condition, max capacity, state of charge (`system_profiler SPPowerDataType`)
- **SSD SMART status** (`diskutil info disk0`)

| Field | Value |
|---|---|
| Sudo required | No |
| Confirmations | None |
| Dry-run | Identical output (no operations to skip) |
| Reports written | None |
| CLI flags | None |
| Safety rules | None — purely informational |
| Skip conditions | Gracefully handles missing `memory_pressure`, missing battery (desktops), missing SMART data |

**When to use it:** Always run this once at the start of a session to
baseline. The disk-free number plus the [Section 26](#section-26--disk-usage-report)
report tells you which other sections are worth running.

---

## Section 1 — Xcode caches, DerivedData, simulators

> Prunes Xcode build caches, DeviceSupport directories, and removes
> unavailable simulators. Optionally wipes all simulator state.

If you've ever opened Xcode and watched `~/Library/Developer/Xcode/DerivedData`
balloon to 60 GB, this section is for you. It is **age-aware** — recently
built projects survive even if the parent folder is huge.

**Paths touched (age-aware prune via `clean_dir_unused`):**

- `~/Library/Developer/Xcode/DerivedData`
- `~/Library/Developer/Xcode/iOS DeviceSupport`
- `~/Library/Developer/Xcode/tvOS DeviceSupport`
- `~/Library/Developer/Xcode/watchOS DeviceSupport`
- `~/Library/Developer/Xcode/Logs`
- `~/Library/Developer/Xcode/DocumentationCache`
- `~/Library/Caches/com.apple.dt.Xcode`

**Simulator operations:**

- Removes unavailable simulators: `xcrun simctl delete unavailable`
- **Optional confirm:** Wipe `~/Library/Developer/CoreSimulator` entirely
  (loses every simulator's saved state — apps remain, but reset to first-run)

| Field | Value |
|---|---|
| Sudo required | No |
| Confirmations | Optional `[y/N]` for the CoreSimulator wipe |
| Dry-run | Prints `[dry-run] xcrun simctl delete unavailable` and `[dry-run] would clear …` for each path |
| Reports written | None |
| CLI flags | [`--cache-age-days N`](cli-reference.md#--cache-age-days-n), [`--dry-run`](cli-reference.md#--dry-run) |
| Safety rules | The atime+mtime rule keeps recently-built projects' DerivedData alive even when older entries are pruned |
| Skip conditions | Skipped entirely if `~/Library/Developer/Xcode` is missing **and** `xcrun` is not on PATH |

**Tip:** A single `DerivedData` cleanup right before re-installing Xcode
saves ~30 minutes of "Xcode is preparing…" later. Pair with section 17
(Xcode archives) for a complete Xcode reset.

---

## Section 2 — Android / Gradle caches

> Prunes Gradle build caches and Android SDK build caches, age-aware.

**Paths touched:**

- `~/.gradle/caches` — pruned if files are unused (atime+mtime) ≥ `--cache-age-days`
- `~/.gradle/wrapper/dists` — **optional confirm**, since prune may force
  Gradle to re-download a distribution on next build
- `~/.android/cache`
- `~/.android/build-cache`

| Field | Value |
|---|---|
| Sudo required | No |
| Confirmations | Optional `[y/N]` for `~/.gradle/wrapper/dists` |
| Dry-run | Prints `[dry-run] would prune …` for each directory |
| Reports written | None |
| CLI flags | [`--cache-age-days N`](cli-reference.md#--cache-age-days-n), [`--dry-run`](cli-reference.md#--dry-run) |
| Safety rules | Gradle distributions you invoke even once a month keep recent atime and survive |
| Skip conditions | Gracefully handles missing directories |

**Why the atime rule matters here:** A Gradle distribution invoked once
a month keeps a recent atime even if its files were downloaded 6 months
ago. Without the atime check, you'd re-download multi-hundred-MB Gradle
ZIPs on every build after each cleanup pass.

---

## Section 3 — Package manager caches

> The biggest single-section reclaimer for developers. Cleans every
> common package manager's cache.

**Tools recognised (each only runs if the binary is on PATH):**

| Tool | Action |
|---|---|
| `npm` | `npm cache clean --force` |
| `yarn` | `yarn cache clean` |
| `pnpm` | `pnpm store prune` |
| `pod` (CocoaPods) | `pod cache clean --all` |
| `pip` | `pip cache purge` |
| `pip3` | `pip3 cache purge` |
| `brew` (Homebrew) | `brew cleanup -s` always; `brew autoremove` only if `--brew-autoremove` is set |
| `go` | Age-aware prune of `~/go/pkg/mod/cache`; only `go clean -modcache` if `--cache-age-days 0` is explicitly set |

**Paths touched (age-aware via `clean_dir_unused`):**

- `~/.pub-cache` (Flutter — optional confirm, default Yes)
- `~/.cargo/registry/cache`
- `~/.cargo/git/db`
- `~/go/pkg/mod/cache`
- `~/.bundle/cache`
- `~/.gem/cache`

**Additional modern dev caches pruned (age-gated; cache _subpaths_ only, never
the toolchain roots):**

- `~/.bun/install/cache` (Bun)
- `~/.ccache` (ccache)
- `~/.cache/uv` (uv)
- `~/.cache/deno` (Deno)
- `~/.composer/cache` (Composer)
- `~/.nvm/.cache` (nvm download cache)

> These are explicit cache subdirectories only. The toolchain roots
> themselves (`~/.bun`, `~/.nvm`, `~/.cache`, …) are in
> `CRITICAL_HOME_DIRS` and are never entered, so installed binaries and
> tool state are never touched. Caches that live under `~/Library/Caches`
> (Deno, SwiftPM, Carthage, sccache) are already swept by Section 5 and so
> are not repeated here.

| Field | Value |
|---|---|
| Sudo required | No |
| Confirmations | Optional `[y/N]` (default Yes) for the Flutter pub-cache prune |
| Dry-run | Prints `[dry-run] COMMAND` for each manager |
| Reports written | None |
| CLI flags | [`--cache-age-days N`](cli-reference.md#--cache-age-days-n), [`--brew-autoremove`](cli-reference.md#--brew-autoremove), [`--dry-run`](cli-reference.md#--dry-run) |
| Safety rules | `brew autoremove` is **opt-in** since 4.3.1 — see the warning below |
| Skip conditions | Gracefully handles missing tools; logs warnings if a `cache clean` command fails |

> **Why `brew autoremove` is off by default:** It can uninstall formulae
> originally installed as dependencies and now considered "unused" — in
> practice this can remove `node`, `python`, `openssl`, breaking every
> globally-installed tool that depended on them. If you want it, opt in
> with `--brew-autoremove`. See [Recovery Guide](recovery-guide.md) for
> the 4.3.0 incident this rule was added to prevent.

---

## Section 4 — Docker prune

> Prunes unused Docker containers, images, networks, and build cache.
> Volumes are **preserved by default** and only removed via a separate,
> explicit confirmation (see below).

**Default action:** `docker system prune -a -f`

This **does not** include `--volumes`. Named-volume data — for example the
only copy of a database for a stopped project — is left untouched, because
that data is irreversible to recover. Images, containers, networks, and
build cache are all recoverable (re-pulled or rebuilt), so they are pruned.

**Optional volume action:** `docker volume prune -f`

Offered **separately**, behind a literal-`yes` confirmation (you must type
the word `yes`, not just `y`). This permanently deletes data in all unused
named volumes and is **not** recoverable.

| Field | Value |
|---|---|
| Sudo required | No |
| Confirmations | **Required** — image/container prune asks `[y/N]` (default No); volume prune asks a separate literal-`yes` prompt |
| Dry-run | Prints `[dry-run] docker system prune -a -f`, and (if you confirm volumes) `[dry-run] docker volume prune -f` |
| Reports written | None |
| CLI flags | [`--dry-run`](cli-reference.md#--dry-run) |
| Safety rules | Mandatory confirmation for both prunes. Volume prune **never runs unattended**: in batch mode (`--yes`) it is skipped with a note; interactively it runs only after you type `yes`. |
| Skip conditions | Skipped if `docker` not installed; skipped if Docker daemon not running (you're prompted to start Docker Desktop) |

**Heads up:** the default `-a` prune removes **every image and container
not currently referenced by a running container** — including images you'd
otherwise have to re-pull. On a developer machine this often reclaims
20–60 GB. **Volumes are excluded from this**, so your stopped-project
databases survive a default run.

**Reachability with `--only 4 --yes`:** this prunes images, containers,
networks, and build cache, but **will not** delete volumes — the batch-mode
guard skips the volume step entirely. To remove volumes you must run
Section 4 interactively and type `yes` at the volume prompt.

---

## Section 5 — User caches

> Sweeps `~/Library/Caches` while preserving Apple, browser, and password
> manager entries.

**Paths touched:**

- `~/Library/Caches/*` — selective deletion (see preserve list below)
- `~/Library/Saved Application State` — **optional**, default Yes (causes
  windows not to reopen on relaunch)
- `~/Library/Logs/DiagnosticReports`

**Preserved (never deleted):** a maintained allowlist (`USER_CACHE_PRESERVE`,
matched via `find ! -name`) so the patterns have a single source of truth.

- `com.apple.*`
- Browsers — `com.google.Chrome*`, `org.mozilla.firefox*`, `com.apple.Safari*`,
  `com.brave.*`, `BraveSoftware*`, `Company` (Arc), `com.microsoft.edgemac*`,
  `com.operasoftware.Opera*`, `com.operasoftware.OperaGX*`,
  `com.vivaldi.Vivaldi*`, `com.thebrowser.Browser*`, `company.thebrowser.*`,
  `com.duckduckgo.macos.browser*`, `com.kagi.kagimacOS*` (Orion),
  `app.zen-browser.zen*` (Zen), `org.floorp.*` (Floorp),
  `net.imput.chromium*`, `org.chromium.Chromium*`
- Password managers — `1Password*`, `com.agilebits.*`, `Bitwarden*`,
  `org.keepassxc.keepassxc*` (KeePassXC)
- `node` — protects `~/Library/Caches/node/corepack`, a `CRITICAL_HOME_DIRS`
  entry; deleting it would break every corepack-pinned yarn/pnpm.

| Field | Value |
|---|---|
| Sudo required | No |
| Confirmations | Optional `[y/N]` (default Yes) for Saved Application State |
| Dry-run | Prints `[dry-run] would prune most non-Apple, non-browser entries` |
| Reports written | None |
| CLI flags | [`--dry-run`](cli-reference.md#--dry-run) |
| Safety rules | Apple, browser, and password-manager caches are **always preserved** |
| Skip conditions | Gracefully handles missing directories |

---

## Section 6 — System caches

> Sweeps `/Library/Caches`, removing all non-Apple entries. Requires sudo.

**Paths touched:** `/Library/Caches/*` (non-Apple only)

| Field | Value |
|---|---|
| Sudo required | **Yes** (mandatory — section is skipped without sudo) |
| Confirmations | None (the sudo gate is the confirmation) |
| Dry-run | Prints `[dry-run] would sweep non-Apple entries` |
| Reports written | None |
| CLI flags | [`--dry-run`](cli-reference.md#--dry-run), [`--no-sudo`](cli-reference.md#--no-sudo) |
| Safety rules | Only non-Apple entries are removed; Apple caches preserved |
| Skip conditions | Skipped entirely if sudo unavailable or `--no-sudo` is set |

---

## Section 7 — Logs

> Prunes user and system log files, with **different age thresholds per
> location**.

**Paths touched:**

| Path | Age threshold | Sudo? |
|---|---|---|
| `~/Library/Logs/*` | files > 7 days | No |
| `/Library/Logs/*` | files > 30 days | **Yes** |
| `/private/var/log/*` matching `*.log`, `*.log.*`, `*.out`, `*.err`, `*.asl`, `*.gz`, `*.bz2` | files > 14 days | **Yes** |

| Field | Value |
|---|---|
| Sudo required | Yes for the system portions; no for user logs |
| Confirmations | None |
| Dry-run | Prints `[dry-run] would prune …` per directory |
| Reports written | None |
| CLI flags | [`--dry-run`](cli-reference.md#--dry-run), [`--no-sudo`](cli-reference.md#--no-sudo) |
| Safety rules | Different ages per location reflect their typical churn |
| Skip conditions | Skips system directories if sudo unavailable |

---

## Section 8 — Temp files

> Removes user-owned temp files older than 1 day from `$TMPDIR`, `/tmp`,
> and `~/tmp`.

**Paths touched:**

- `$TMPDIR/*` — user-owned, > 1 day
- `/tmp/*` — user-owned, > 1 day
- `~/tmp/*` — entire directory cleared (if it exists)

| Field | Value |
|---|---|
| Sudo required | No |
| Confirmations | None |
| Dry-run | Prints `[dry-run] would prune …` per directory |
| Reports written | None |
| CLI flags | [`--dry-run`](cli-reference.md#--dry-run) |
| Safety rules | Only files **owned by current user** are removed (safe against shared `/tmp`) |
| Skip conditions | Gracefully handles missing directories |

---

## Section 9 — Update caches

> Clears macOS software-update caches.

**Paths touched:**

- `~/Library/Updates`
- `/Library/Updates` (requires sudo)

| Field | Value |
|---|---|
| Sudo required | Yes for the system path; no for the user path |
| Confirmations | None |
| Dry-run | Prints `[dry-run] would clear …` per directory |
| Reports written | None |
| CLI flags | [`--dry-run`](cli-reference.md#--dry-run), [`--no-sudo`](cli-reference.md#--no-sudo) |
| Safety rules | None |
| Skip conditions | Skips system directory if sudo unavailable |

---

## Section 10 — Empty Trash

> Counts and (with explicit confirmation) empties `~/.Trash`, then the
> per-volume trash on any mounted **external** volume.

**Paths touched:**

- `~/.Trash/*` — the home Trash
- `/Volumes/*/.Trashes/<uid>/*` — the per-user trash on each mounted external
  volume. The boot volume is skipped (same device id as `/`), read-only mounts
  are skipped, and **each volume's trash gets its own confirmation** and size
  count.

| Field | Value |
|---|---|
| Sudo required | No |
| Confirmations | **Required** — `[y/N]` (default No) per trash, with item count and total size shown |
| Dry-run | Counts and reports, does not delete |
| Reports written | None |
| CLI flags | [`--dry-run`](cli-reference.md#--dry-run) |
| Safety rules | Mandatory high-risk confirmation; never auto-run by `--all` |
| Skip conditions | Reports "already empty" and returns if there's nothing in Trash |

> **This is irreversible.** Make sure you really mean it. Apps moved to
> Trash by section 21 are also recovered from this same Trash — emptying
> means giving up the recover-an-app option for any app you uninstalled
> in the same session.

---

## Section 11 — Time Machine local snapshots

> Lists, then deletes (with confirmation) APFS local Time Machine
> snapshots that the system creates automatically.

**Action:** `sudo tmutil deletelocalsnapshots /` for each snapshot listed
by `tmutil listlocalsnapshots /`.

| Field | Value |
|---|---|
| Sudo required | **Yes** (mandatory) |
| Confirmations | **Required** — `[y/N]` (default No) |
| Dry-run | Prints `[dry-run] sudo tmutil deletelocalsnapshots /` |
| Reports written | None |
| CLI flags | [`--dry-run`](cli-reference.md#--dry-run), [`--no-sudo`](cli-reference.md#--no-sudo) |
| Safety rules | High-risk confirmation required |
| Skip conditions | Skipped if `tmutil` unavailable; skipped if no snapshots present |

**Note:** APFS may not free the snapshot's space until it actually needs
it. If `df -h /` doesn't change immediately, that's expected — the space
is reclaimed lazily.

---

## Section 12 — Orphaned app data

> Scans `~/Library` for **app-related data whose parent app is no longer
> installed**, then offers to delete each candidate one by one.

**Detection algorithm:**

1. Builds a registry of installed apps from `/Applications`,
   `/System/Applications`, `/System/Applications/Utilities`,
   `~/Applications` — extracts bundle IDs from `Info.plist`.
2. Scans these locations for orphan candidates:
   - `~/Library/Application Support/*`
   - `~/Library/Containers/*`
   - `~/Library/Group Containers/*`
   - `~/Library/Saved Application State/*`
   - `~/Library/Preferences/*.plist`
   - `~/Library/LaunchAgents/*.plist`
3. **Filters by two conditions** (the 4.3.3 rule):
   - **(a)** The entry is not matched by any installed app name or bundle
     ID (case-insensitive token matching).
   - **(b)** The entry is **untouched (atime AND mtime) for ≥ `--idle-days`**.
4. Apple bundle IDs are never flagged.
5. Writes candidates to `orphans-YYYY-MM-DD.txt`, sorted by size descending.
6. **Interactive review:** offers each candidate with `[y/N/q]` (delete /
   skip / quit). In batch mode (`--all`/`--only`), writes the report and
   exits — pass `--yes` to enable bulk deletion.

| Field | Value |
|---|---|
| Sudo required | No |
| Confirmations | Optional `[y/N]` to start review; per-item `[y/N/q]` if reviewing |
| Dry-run | Prints `[dry-run] would delete …` for each selected item |
| Reports written | `~/.mac-cleanup/reports/orphans-YYYY-MM-DD.txt` |
| CLI flags | [`--idle-days N`](cli-reference.md#--idle-days-n), [`--dry-run`](cli-reference.md#--dry-run) |
| Safety rules | Two-condition rule (heuristic + idle threshold); Apple bundles never flagged; report-only in batch mode unless `--yes` |
| Skip conditions | Skips if no app directories found; skips items touched within idle threshold |

---

## Section 13 — System maintenance (`periodic`)

> Runs the macOS daily/weekly/monthly maintenance scripts.

**Action:** `sudo periodic daily weekly monthly`

| Field | Value |
|---|---|
| Sudo required | **Yes** (mandatory) |
| Confirmations | None |
| Dry-run | Prints `[dry-run] sudo periodic daily weekly monthly` |
| Reports written | None |
| CLI flags | [`--dry-run`](cli-reference.md#--dry-run), [`--no-sudo`](cli-reference.md#--no-sudo) |
| Safety rules | None — these are stock macOS maintenance scripts |
| Skip conditions | Skipped if sudo unavailable |

---

## Section 14 — Deep cache `/private/var/folders`

> ⚠ **Requires reboot afterwards.** The deepest, riskiest cleanup in the
> tool. Performs a **full wipe of everything under `/private/var/folders`
> to depth 3** — the `T` (temp), `C` (Darwin-user cache), and `0`
> (per-boot-session) subtrees alike — not just temp files.

**Action:**

```bash
sudo find /private/var/folders -mindepth 1 -maxdepth 3 ! -type l -print0 \
  | xargs -0 sudo rm -rf
```

This deletes **all** entries under `/private/var/folders` down to depth 3,
excluding only symlinks (`! -type l`, so a link is never followed). It does
**not** age-filter and is **not** limited to the `*/T/*` temp subtree —
clearing the entire accumulated per-user state is the whole point of this
nuclear, menu-only option, which is exactly why it demands a literal `yes`,
`sudo`, and a reboot.

| Field | Value |
|---|---|
| Sudo required | **Yes** (mandatory) |
| Confirmations | **Critical** — must type literal `yes`. Anything else aborts |
| Dry-run | Prints the full `find … \| xargs sudo rm -rf` command instead of executing |
| Reports written | None |
| CLI flags | [`--dry-run`](cli-reference.md#--dry-run), [`--no-sudo`](cli-reference.md#--no-sudo) |
| Safety rules | Highest confirmation bar in the tool; never part of `--all`; menu-only / `--i-understand-deep` for batch; reboot required afterwards |
| Skip conditions | Skipped if sudo unavailable; aborts on anything other than literal `yes` |

> **Why a reboot is required:** Many running apps maintain mmap'd files
> under `/private/var/folders` (e.g. `*/T/*` temp and `*/C/*` caches).
> Wiping the whole tree while apps are running causes incoherent state —
> apps will crash, freeze, or fail to launch. **Reboot immediately after
> this section runs.**

---

## Section 15 — Installer leftovers report

> **Read-only advisory scan.** Reports macOS installer remnants that
> sometimes survive a major upgrade.

**Paths checked (not deleted, just reported):**

- `/Applications/Install macOS*.app`
- `~/Applications/Install macOS*.app`
- `/Previous Systems.localized`, `/Previous System`
- `~/Previous Systems.localized`, `~/Previous System`
- `~/Relocated Items`
- `~/macOS Install Data`
- `/macOS Install Data`

| Field | Value |
|---|---|
| Sudo required | No |
| Confirmations | None |
| Dry-run | Identical output (it's already advisory) |
| Reports written | None (console output only) |
| CLI flags | None |
| Safety rules | None — purely informational |
| Skip conditions | Gracefully handles missing paths |

**What to do with the output:** Review each path manually — some are
huge (`Install macOS*.app` is ~14 GB), some are recoverable user data
(`Relocated Items`). Delete only after you've verified you don't need
the contents.

---

## Section 16 — iOS / iPadOS device backups

> Sweeps old iOS/iPadOS software-update downloads, then lists every
> iOS/iPadOS backup under `~/Library/Application Support/MobileSync/Backup`
> and offers per-item review.

**Software-update downloads (`.ipsw`) — swept first, before the backups check:**

- `~/Library/iTunes/iPhone Software Updates`
- `~/Library/iTunes/iPad Software Updates`

These are multi-GB and fully re-downloadable from Apple. They are pruned
age-gated via `clean_dir_unused` using `--cache-age-days`, and are handled
even when no device backup exists.

**For each backup, displays:**

- Device name (from `Info.plist`)
- Last backup date (from `Info.plist`)
- Backup age in days
- Total size
- **Highlighted in yellow** if age ≥ `--idle-days` (safe-to-delete candidate)

**Review:** `[y/N/q]` per backup. Uses `safe_rm_rf` (or Finder move-to-Trash
if that fails).

| Field | Value |
|---|---|
| Sudo required | No |
| Confirmations | Optional `[y/N]` to start review; per-item `[y/N/q]` if reviewing |
| Dry-run | Reports without deleting |
| Reports written | None |
| CLI flags | [`--idle-days N`](cli-reference.md#--idle-days-n) (highlight threshold), [`--cache-age-days N`](cli-reference.md#--cache-age-days-n) (`.ipsw` prune), [`--dry-run`](cli-reference.md#--dry-run) |
| Safety rules | `--idle-days` only **highlights** idle backups — there is **no** automatic idle delete gate here; this is interactive-only and will delete any backup you confirm, recent or not. Recent backups (< idle threshold) are shown as `(recent)` and kept by default; report-only in batch mode unless `--yes` |
| Skip conditions | Skips the backups list if the directory is missing or empty; `.ipsw` sweep skipped if those dirs are absent |

> **Reminder:** iOS backups can be 50+ GB each. They restore the entire
> device. Once deleted, you cannot restore — only re-back-up after
> connecting the device.

---

## Section 17 — Xcode archives

> Lists every `.xcarchive` under `~/Library/Developer/Xcode/Archives` and
> offers per-item review.

**For each archive, displays:**

- Archive name
- Date archived
- Age in days
- Total size
- **Highlighted in yellow** with `[idle ≥ Nd]` if age ≥ `--idle-days`
- Recent archives marked `(recent — likely keep)`

After deletions, empty year/month subdirectories are collapsed via
`find -empty -delete`.

| Field | Value |
|---|---|
| Sudo required | No |
| Confirmations | Optional `[y/N]` to start review; per-item `[y/N/q]` if reviewing |
| Dry-run | Reports without deleting |
| Reports written | None |
| CLI flags | [`--idle-days N`](cli-reference.md#--idle-days-n) (highlight threshold), [`--dry-run`](cli-reference.md#--dry-run) |
| Safety rules | `--idle-days` only **highlights** idle archives — there is **no** automatic idle delete gate here; this is interactive-only and will delete any archive you confirm, recent or not. Archives marked `(recent — likely keep)` survive by default; report-only in batch mode unless `--yes`; **archives are required for App Store re-signing** of historical builds |
| Skip conditions | Skips if archive directory missing or empty |

---

## Section 18 — Large files report

> **Read-only scan.** Reports the top 25 files ≥ 500 MB anywhere under
> `$HOME` (max depth 7).

**Excluded paths:**

- `*/Library/CloudStorage/*`
- `*/Library/Mobile Documents/*`
- `*/Library/Photos/*`
- `*.photoslibrary/*`
- `*/Movies/*`, `*/Music/*`
- `*/Virtual Machines/*`
- `*/.Trash/*`
- `*/Parallels/*`, `*/VMware/*`

| Field | Value |
|---|---|
| Sudo required | No |
| Confirmations | None |
| Dry-run | Identical output |
| Reports written | `~/.mac-cleanup/reports/large-files-YYYY-MM-DD.txt` |
| CLI flags | None (advisory) |
| Safety rules | None |
| Skip conditions | Scan can take ~1 minute on large home directories |

**Pair with:** [Section 24](#section-24--large-stale-files) — Section 18
shows you the largest files; section 24 only flags those that haven't
been touched recently.

---

## Section 19 — Browser caches

> Wipes HTTP/code caches for a broad set of Chromium- and Firefox-family
> browsers, **iterating every profile** (not just `Default`). Shows a Safari
> advisory (clear via Safari → Develop → Empty Caches).

**Chromium-family browsers covered** (each handled by `clean_chromium_caches`,
which clears the `~/Library/Caches/<bundle>` HTTP cache **plus every profile**
— `Default`, `Profile 1…`, Guest/System Profile — touching only these cache
subdirs: `Cache`, `Code Cache`, `GPUCache`, `DawnGraphiteCache`,
`DawnWebGPUCache`, `Service Worker/CacheStorage`, `Service Worker/ScriptCache`;
profile data, history, logins and extensions are left intact):

- **Chrome** (`com.google.Chrome`) and **Chrome Canary** (`com.google.Chrome.canary`)
- **Brave** (`BraveSoftware`)
- **Microsoft Edge** (`com.microsoft.edgemac`)
- **Vivaldi** (`com.vivaldi.Vivaldi`)
- **Chromium** (`org.chromium.Chromium`)
- **Opera** (`com.operasoftware.Opera`) and **Opera GX** (`com.operasoftware.OperaGX`)
- **DuckDuckGo** (`com.duckduckgo.macos.browser`)
- **Arc** (`com.thebrowser.Browser`)
- Plus the non-standard `~/Library/Caches/com.google.Chrome.helper` and
  `~/Library/Caches/Company/Arc` cache dirs.

**Firefox-family browsers covered** (top-level `~/Library/Caches/<id>` entry
plus per-profile `cache2` under each profiles root):

- **Firefox** (`org.mozilla.firefox`, `Firefox`)
- **Firefox Developer Edition** (`org.mozilla.firefoxdeveloperedition`)
- **Firefox Nightly** (`org.mozilla.nightly`)
- **LibreWolf** (`org.mozilla.librewolf`)
- **Floorp** (`org.floorp.Floorp`)
- **Zen** (`app.zen-browser.zen`)
- Per-profile `cache2` under `Firefox/Profiles`, `zen/Profiles`,
  `Floorp/Profiles`, `LibreWolf/Profiles`.

- **Safari:** advisory only (`Safari → Develop → Empty Caches` or `Settings → Privacy`)

| Field | Value |
|---|---|
| Sudo required | No |
| Confirmations | **Required** — `[y/N]` (default No), warns next page loads will be slower |
| Dry-run | Reports the wipe instead of doing it |
| Reports written | None |
| CLI flags | [`--dry-run`](cli-reference.md#--dry-run) |
| Safety rules | Performance impact warned (next page loads slower until re-cached) |
| Skip conditions | Safari requires manual clearing via UI |

---

## Section 20 — DNS / mDNS reset

> Flushes DNS cache, restarts mDNS responder, and renews DHCP on `en0`.

**Actions (all sudo):**

- `sudo dscacheutil -flushcache`
- `sudo killall -HUP mDNSResponder`
- `sudo ipconfig set en0 DHCP` (if `en0` exists)

| Field | Value |
|---|---|
| Sudo required | **Yes** (mandatory) |
| Confirmations | None |
| Dry-run | Prints the commands instead of executing |
| Reports written | None |
| CLI flags | [`--dry-run`](cli-reference.md#--dry-run), [`--no-sudo`](cli-reference.md#--no-sudo) |
| Safety rules | None |
| Skip conditions | DHCP renew gracefully skipped if `en0` unavailable |

**When to use:** After changing DNS providers, after a VPN install, when
internal hostnames stop resolving, or before testing changes to local
DNS records.

---

## Section 21 — Apps unused N+ days

> Scans installed apps, computes a last-used age via 5 signal sources,
> and offers **review** or **bulk uninstall** of idle apps. The most
> careful section in the tool.

**Last-used signal priority:**

1. Spotlight `kMDItemLastUsedDate` (best signal)
2. Saved Application State mtime
3. Container (`Containers/`) mtime
4. Preferences plist mtime
5. Spotlight `kMDItemUseCount` (skip if `>0` but no date — probably used,
   unknown when)

**Apps with no usable signal are skipped** (under-flag to avoid false
positives). Apple bundles are never flagged.

**For each idle app, displays:**

- App name and bundle ID
- Last-used date and days idle
- App bundle size
- **Companion-data size** — sum of:
  - `~/Library/Application Support/{bundle_id}`, `~/Library/Application Support/{app_name}`
  - `~/Library/Containers/{bundle_id}`
  - `~/Library/Caches/{bundle_id}`, `~/Library/Caches/{app_name}`
  - `~/Library/Logs/{app_name}`
  - `~/Library/Preferences/{bundle_id}.plist`
  - `~/Library/Saved Application State/{bundle_id}.savedState`
  - `~/Library/LaunchAgents/{bundle_id}.plist`
  - `~/Library/HTTPStorages/{bundle_id}`, `~/Library/HTTPStorages/{bundle_id}.binarycookies`
  - `~/Library/WebKit/{bundle_id}`
  - `~/Library/Group Containers/*{bundle_id}*`

> The bundle-ID-confined paths above always belong to this app and are
> removed with it. The **name-based** paths (`Application Support/{app_name}`,
> `Caches/{app_name}`, `Logs/{app_name}`) are generic enough that a
> different, still-installed app could share the folder name, so since 4.5.0
> they are only included when the folder itself is idle for
> `≥ --threshold` days (readable timestamp required); recent or
> unknown-age name folders are kept.

**Action options:**

- `[R]eview` — review one by one with companion-data inspection
- `[B]ulk` — multi-select via `1,3,5-7` syntax (see [interactive multi-select](#interactive-multi-select-syntax))
- `[N]o` — skip
- With `--yes`: auto-selects all

**Uninstall:** Apps are **moved to Trash** (via Finder AppleScript
`osascript_trash`) when possible — recoverable until you empty the Trash.
Falls back to `rm -rf` if AppleScript fails.

| Field | Value |
|---|---|
| Sudo required | No |
| Confirmations | Action menu `[R/B/N]`; bulk has a final confirmation |
| Dry-run | Prints `[dry-run] would move X to Trash and rm N data path(s)` |
| Reports written | `~/.mac-cleanup/reports/unused-apps-YYYY-MM-DD.txt` |
| CLI flags | [`--threshold N`](cli-reference.md#--threshold-n), [`--dry-run`](cli-reference.md#--dry-run) |
| Safety rules | Apple bundles never flagged; under-flag when no signal; apps moved to Trash (recoverable); report-only in batch mode unless `--yes` |
| Skip conditions | Spotlight may be re-indexing (results may be incomplete) |

---

## Section 22 — Purgeable space trigger

> Allocates 1 GB temporarily, sleeps 1 second, then deletes — a
> well-known macOS trick to nudge the OS into reclaiming "purgeable" space.

**Actions:**

- `mkfile -n 1g ~/.mac-cleanup/.purgeable-bait` (or your `--logs-dir`)
- `sleep 1`
- `rm` the bait file

| Field | Value |
|---|---|
| Sudo required | No |
| Confirmations | None |
| Dry-run | Prints `[dry-run] would mkfile -n 1g + rm` |
| Reports written | None |
| CLI flags | [`--dry-run`](cli-reference.md#--dry-run) |
| Safety rules | None |
| Skip conditions | Skipped if `mkfile` unavailable; skipped silently if insufficient free space |

**What "purgeable" means:** macOS counts certain caches and snapshots as
"purgeable" — disk space that's reclaimable on demand. Some processes
hold those reservations until disk pressure forces a reclaim. This
section creates that pressure briefly.

---

## Section 23 — Stale build artefacts

> The single biggest reclaimer for active developers. Finds and deletes
> regenerable build directories (`node_modules`, `vendor`, `dist`,
> `.next`, `target`, `Pods`, etc.) **only when** they are old and unused.

**Patterns matched:**

```
node_modules vendor dist build out
.next .nuxt .turbo .vite .parcel-cache .svelte-kit .astro
target Pods coverage .nyc_output
```

**Scan roots (auto-detected, in order — only existing ones used):**

```
~/Projects ~/projects ~/Code ~/code ~/Developer ~/dev
~/repos ~/work ~/Work ~/Documents ~/Desktop ~/Downloads
```

You can override with `--scan-roots "P1:P2:…"` (colon-separated).

**Critical safety: `CRITICAL_HOME_DIRS` allowlist** — section 23 will
**never enter** these toolchain/IDE/secrets directories regardless of
how their basename matches `STALE_BUILD_PATTERNS`:

```
.nvm .fnm .n .tnvm .volta .asdf
.npm .npm-packages .yarn .pnpm-store .pnpm
.bun .deno .rbenv .pyenv .rustup .rye .ruby
.cargo .gradle .m2 .sbt .ivy2
.pub-cache .cocoapods
.cache .config .docker .android .dartServer
.vscode .vscode-server .cursor .cursor-server
.idea .nvim .vim .emacs.d
.claude .codex .agents .ollama
.ssh .gnupg .aws .azure .gcloud .kube .terraform.d
.password-store .1password .keepass
.oh-my-zsh .git
```

This list is the **safety contract** that prevents the 4.3.0 bug where
section 23 could nuke `node_modules` deep inside `~/.bun` or
`~/.pnpm-store`. See [Recovery Guide](recovery-guide.md).

**Age filter:** Both atime AND mtime ≥ `--stale-build-days` (falls back
to `--idle-days`). A `node_modules` your IDE just read for autocomplete
keeps recent atime and survives.

**Workflow:**

1. Prompt for age threshold (or use flag)
2. Validate scan roots (refuses to scan all of `$HOME`)
3. Find candidates matching patterns AND age filter, excluding
   `CRITICAL_HOME_DIRS` and `~/Library`
4. Write candidates to `stale-build-YYYY-MM-DD.txt` (size, age, path)
5. Multi-select via `1,3,5-7` syntax
6. Final confirmation before deletion (regenerable, **not** moved to
   Trash — `rm -rf`)

| Field | Value |
|---|---|
| Sudo required | No |
| Confirmations | "Proceed with scan?" (default Yes); final "Confirm bulk delete?" |
| Dry-run | Prints `[dry-run] rm -rf …` for each selected item |
| Reports written | `~/.mac-cleanup/reports/stale-build-YYYY-MM-DD.txt` |
| CLI flags | [`--stale-build-days N`](cli-reference.md#--stale-build-days-n), [`--idle-days N`](cli-reference.md#--idle-days-n) (fallback), [`--scan-roots`](cli-reference.md#--scan-roots-p1p2), [`--dry-run`](cli-reference.md#--dry-run) |
| Safety rules | `CRITICAL_HOME_DIRS` allowlist (find-time + post-filter); refuses to scan all of `$HOME`; report-only in batch mode unless `--yes`; deletions are not moved to Trash (regenerable by definition) |
| Skip conditions | Errors out if no common dev folder is detected and no `--scan-roots` is supplied |

> **Why this section is so safety-hardened:** Section 23 is the original
> source of the 4.3.0 incident. The combination of pattern matching
> (`.cache`) and silent `$HOME` fallback meant a single command could
> sweep into `~/.bun/install/cache/.cache` or `~/.local/share/pnpm/store`
> and break every globally installed tool. The fix added the
> `CRITICAL_HOME_DIRS` allowlist, removed `.cache` from patterns, and
> made the script error rather than fall back to `$HOME`. Read
> [Recovery Guide](recovery-guide.md) for the full incident and recovery
> commands.

---

## Section 24 — Large stale files

> Finds files ≥ N GB anywhere under `$HOME` whose **both** atime AND
> mtime are ≥ M days old. Moves selected files to Trash (not `rm`).

**Defaults:** ≥ 1 GB, ≥ 100 days idle. Tune via flags.

**Excluded paths:**

- `*/Library/CloudStorage/*`, `*/Library/Mobile Documents/*`
- `*.photoslibrary/*`, `*/Library/Photos/*`
- `*/.Trash/*`
- `*/Virtual Machines/*`, `*/Parallels/*`, `*/VMware/*`

**Workflow:**

1. Prompt for size threshold (default `--large-file-size-gb`)
2. Prompt for age threshold (default `--large-file-days`)
3. Scan
4. Write candidates to `large-stale-YYYY-MM-DD.txt`
5. Multi-select via `1,3,5-7`
6. Final confirmation, then **move to Trash** (recoverable)

| Field | Value |
|---|---|
| Sudo required | No |
| Confirmations | "Proceed with scan?"; final "Confirm move-to-Trash?" |
| Dry-run | Reports without moving |
| Reports written | `~/.mac-cleanup/reports/large-stale-YYYY-MM-DD.txt` |
| CLI flags | [`--large-file-size-gb N`](cli-reference.md#--large-file-size-gb-n), [`--large-file-days N`](cli-reference.md#--large-file-days-n), [`--dry-run`](cli-reference.md#--dry-run) |
| Safety rules | atime+mtime gate avoids false-flagging recently-opened files; selected files are **moved to Trash** (recoverable) |
| Skip conditions | Scan can take several minutes on large home directories |

---

## Section 25 — LaunchAgents / LaunchDaemons audit

> Scans launch items in three locations, identifies those whose target
> binary no longer exists ("orphan launch items"), and offers per-item
> unload-and-delete review.

**Locations scanned:**

- `~/Library/LaunchAgents/*.plist`
- `/Library/LaunchAgents/*.plist` (sudo)
- `/Library/LaunchDaemons/*.plist` (sudo)

**Detection:** For each plist, extract `Label`, `Program`, or
`ProgramArguments[0]` via `plutil`. Fallback: grep raw plist bytes for
the first `/`-rooted path. If the target binary doesn't exist, the
launch item is orphaned.

**Action:** Per-item `[y/N/q]` review. If selected:

- `launchctl unload -w <plist>` (prevents re-execution)
- `rm` the plist (sudo for `/Library/`)

| Field | Value |
|---|---|
| Sudo required | Yes for system locations; no for user items |
| Confirmations | Optional `[y/N]` to start review; per-item `[y/N/q]` if reviewing |
| Dry-run | Prints `[dry-run] launchctl unload + rm …` |
| Reports written | `~/.mac-cleanup/reports/launch-audit-YYYY-MM-DD.txt` |
| CLI flags | [`--dry-run`](cli-reference.md#--dry-run), [`--no-sudo`](cli-reference.md#--no-sudo) (system items skipped if no sudo) |
| Safety rules | Unloads before deletion (prevents zombie launch); report-only in batch mode unless `--yes` |
| Skip conditions | Skips if no launch items found |

**Why orphan launch items matter:** They cause slow login (the system
tries to start binaries that no longer exist), retry storms in the
console log, and apparent "ghost" processes in Activity Monitor.

---

## Section 26 — Disk usage report

> **Read-only.** Computes `du -sh` for direct children of `$HOME` and
> `~/Library`, sorts by size, prints the top 20 of each.

| Field | Value |
|---|---|
| Sudo required | No |
| Confirmations | None |
| Dry-run | Identical output (informational) |
| Reports written | `~/.mac-cleanup/reports/disk-usage-YYYY-MM-DD.txt` |
| CLI flags | None |
| Safety rules | None — purely advisory |
| Skip conditions | Scan can take ~30 seconds on very large home directories |

**Use it as a fast triage:** Before running anything destructive, this
report tells you where your space went. Combine with section 0 (system
health) for a complete pre-cleanup baseline.

---

## Section 27 — macOS UI maintenance: QuickLook + font caches

> Resets regenerable macOS UI caches that commonly cause garbled fonts or
> stale QuickLook previews. **Non-destructive** — everything here rebuilds
> automatically on demand. **Menu / `--only` only — never part of `--all`.**

**Actions:**

- **QuickLook thumbnail cache** — `qlmanage -r cache` (no sudo). Regenerates
  the next time you preview a file.
- **User font cache** — `atsutil databases -removeUser` (no sudo). Clearing
  fixes duplicate/garbled fonts in the current user scope.
- **System font cache (optional)** — only if you confirm `[y/N]`: with sudo,
  `sudo atsutil databases -remove`, followed by a note that a logout or
  restart finalises the rebuild.

| Field | Value |
|---|---|
| Sudo required | Only for the optional system font-cache clear (the QuickLook and user font-cache resets need no sudo) |
| Confirmations | Optional `[y/N]` to also clear the **system** font cache (default No) |
| Dry-run | Prints each command (`qlmanage -r cache`, `atsutil databases -removeUser`, and `sudo atsutil databases -remove`) instead of executing |
| Reports written | None |
| CLI flags | [`--dry-run`](cli-reference.md#--dry-run), [`--no-sudo`](cli-reference.md#--no-sudo) (affects only the optional system clear) |
| Safety rules | Non-destructive — all caches regenerate on demand; **never run by `--all`** (menu / `--only` only); the system-wide clear is always opt-in behind its own confirmation |
| Skip conditions | QuickLook step skipped if `qlmanage` is unavailable; font steps skipped if `atsutil` is unavailable |

> **Note:** This section is **not** in the safe batch and is not one of the
> deep-destructive sections either — it is simply menu- or `--only`-driven.
> Run it with `mac-cleanup --only 27`.

---

## Interactive multi-select syntax

When a section asks **"Select items (1..N)"** you can type:

| Input | Meaning |
|---|---|
| `all` (or `a`) | Every item |
| `none` (or empty) | Nothing |
| `1,3,5-7,12` | Items 1, 3, 5, 6, 7, 12 |
| `7-3` | Reverse range — auto-swaps to 3..7 |

Out-of-range or junk tokens are silently ignored. Used by sections 21
(bulk uninstall), 23 (stale builds), and 24 (large stale files).

---

## See also

- [CLI Reference](cli-reference.md) — every flag, with examples
- [Profiles](profiles.md) — preset bundles of section numbers
- [Safety Model](safety-model.md) — the two-condition rule, sudo handling, dry-run guarantees
- [Reports & Logs](reports-and-logs.md) — what each report file contains
- [Recovery Guide](recovery-guide.md) — restoring tools after a 4.3.0 run

---

_Sections reference for **mac-cleanup** v4.5.0 by **[Ahsan Mahmood](author.md)**._
