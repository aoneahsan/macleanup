# CLI Reference

> Every command-line flag accepted by **mac-cleanup**, what it does, and
> when to use it.

This page is the canonical reference. The flag list is identical
regardless of how you invoke the tool — `npx macleanup`, the global
`mac-cleanup` binary, or a direct `./mac-cleanup.sh` from a checkout all
parse the exact same arguments.

For background on individual sections those flags affect, see
[Sections (0–27)](sections.md). For curated workflows, see
[Examples Cookbook](examples-cookbook.md).

---

## Synopsis

```
mac-cleanup [options]
```

With no options, mac-cleanup prints a one-time welcome (first run on a
machine), then drops into the **interactive menu**. From there you choose
one section at a time, with confirmations for every destructive operation.

---

## At-a-glance flag table

| Flag | Type | Default | Purpose |
|---|---|---|---|
| [`--all`](#--all) | switch | off | Run every safe section in batch |
| [`--only "L"`](#--only-l) | string | — | Run only the listed sections |
| [`--exclude "L"`](#--exclude-l) | string | — | Skip the listed sections |
| [`--profile NAME`](#--profile-name) | string | — | Run a named bundle |
| [`--yes`, `-y`](#--yes--y) | switch | off | Auto-confirm prompts |
| [`--i-understand-deep`](#--i-understand-deep) | switch | off | Allow deep sections (6,11,14,21,24) unattended (with `--yes`) |
| [`--dry-run`](#--dry-run) | switch | off | Preview without deleting |
| [`--no-sudo`](#--no-sudo) | switch | off | Skip every sudo section |
| [`--quiet`](#--quiet) | switch | off | Suppress info chatter |
| [`--json`](#--json) | switch | off | One-line JSON run summary on stdout (implies `--quiet`) |
| [`--no-color`](#--no-color) | switch | auto | Disable ANSI colour |
| [`--notify`](#--notify) | switch | off | macOS notification on completion |
| [`--check-update`](#--check-update) | switch | off | Query npm for newer version |
| [`--brew-autoremove`](#--brew-autoremove) | switch | off | Allow `brew autoremove` in section 3 |
| [`--threshold N`](#--threshold-n) | int | 100 | Days idle for "unused apps" (sec 21) |
| [`--cache-age-days N`](#--cache-age-days-n) | int | 100 | Cache age threshold (sec 1, 2, 3) |
| [`--idle-days N`](#--idle-days-n) | int | 100 | Idle threshold — delete gate (sec 12, 23) + highlight (sec 16, 17) |
| [`--stale-build-days N`](#--stale-build-days-n) | int | 100 | Stale build artefact age (sec 23) |
| [`--large-file-days N`](#--large-file-days-n) | int | 100 | Large unused file age (sec 24) |
| [`--large-file-size-gb N`](#--large-file-size-gb-n) | int | 1 | Large file min size in GB (sec 24) |
| [`--scan-roots "P1:P2:…"`](#--scan-roots-p1p2) | string | auto | Roots for sec 23 / 24 |
| [`--exclude-path PATH`](#--exclude-path-path) | string (repeatable) | — | Never touch PATH/subtree in sec 23 / 24 |
| [`--logs-dir PATH`](#--logs-dir-path) | string | `~/.mac-cleanup/logs` | Persistent logs dir |
| [`--reports-dir PATH`](#--reports-dir-path) | string | `~/.mac-cleanup/reports` | Persistent reports dir |
| [`--no-reports`](#--no-reports) | switch | off | Skip writing per-section reports |
| [`--cleanup-logs-on-finish`](#--cleanup-logs-on-finish) | switch | off | Delete this run's log on exit |
| [`--list`](#--list) | switch | off | List sections and exit |
| [`--version`, `-V`](#--version--v) | switch | off | Print version and exit |
| [`--contact`](#--contact) | switch | off | Print author contact card |
| [`--feedback`](#--feedback) | switch | off | Open mail client with prefilled message |
| [`--report-issue`](#--report-issue), [`--report-bug`](#--report-issue) | switch | off | Open pre-filled GitHub issue |
| [`--stats`](#--stats) | switch | off | Show run history at `~/.mac-cleanup` |
| [`--prune-history [N]`](#--prune-history-n) | int | 90 | Delete logs+reports older than N days |
| [`--uninstall-data`](#--uninstall-data) | switch | off | Remove the entire `~/.mac-cleanup` data dir |
| [`-h`, `--help`](#-h---help) | switch | off | Show help and exit |

---

## Selection flags — what runs

### `--all`

```
--all
```

Run the **safe batch** without prompting per-section. Implies
`BATCH_MODE=1`, which silences the per-section "Continue?" question.

The safe batch (`SAFE_BATCH`) is exactly these sections — caches, logs,
temp, and read-only reports:

```
0  3  5  7  8  9  15  18  22  26
```

> **Section 13 (periodic maintenance) was removed from `--all` in 4.5.0.**
> It ran `sudo periodic` unattended, which is privileged system maintenance
> rather than a cache/log/temp/report cleanup. It is no longer in the safe
> batch — run it from the menu or with `--only 13`.

`--all` (**even `--all --yes`**) **never runs the deep sections**. The
deep-interactive set (section 6 system caches as root, 11 Time Machine
snapshots, 14 `/private/var/folders` wipe, 21 app uninstall, 24 large stale
files → Trash) is refused under `--all` unless you also pass
[`--i-understand-deep`](#--i-understand-deep). `--yes` alone is not enough.

```bash
mac-cleanup --all                 # safe batch, batch mode
mac-cleanup --all --yes           # full unattended SAFE cleanup (no deep sections)
mac-cleanup --all --dry-run       # preview the safe-batch
```

---

### `--only "L"`

```
--only "0,5,21,23"
```

Run **only** the listed sections. `L` is a comma-separated list of section
numbers (0–27). Whitespace is fine; out-of-range numbers are ignored.

```bash
mac-cleanup --only 5                       # one section
mac-cleanup --only "1,2,3,4"               # the dev-cache quartet
mac-cleanup --only 23 --stale-build-days 90 --dry-run
```

Implies `BATCH_MODE=1`. See [Sections (0–27)](sections.md) for what each
number does.

---

### `--exclude "L"`

```
--exclude "14,17"
```

Skip the listed sections. Applied **on top of** `--all`, `--only`, or
`--profile`. Useful when a profile is mostly what you want but two
sections aren't.

```bash
mac-cleanup --profile deep --exclude 14         # the deep preset, but skip the reboot one
mac-cleanup --all --exclude "10,11"             # skip Trash empty + Time Machine snapshots
```

---

### `--profile NAME`

```
--profile dev | minimal | cache-only | deep | audit
```

Run a **named bundle** of sections. Five built-in profiles cover the most
common workflows; combine with `--exclude` to subtract sections.

| Profile | Sections | When to use |
|---|---|---|
| `dev`        | `1,2,3,4,23`                          | Reclaim developer-tool caches + stale `node_modules` |
| `minimal`    | `5,7,8,9,10`                          | Quick weekly sweep, mostly safe |
| `cache-only` | `3,5,6,7,9,19`                        | Every cache layer; nothing else |
| `deep`       | `0,1,2,3,4,5,6,7,8,9,17,19,23,26`    | Big monthly cleanup |
| `audit`      | `0,12,18,21,25,26`                    | Read-only diagnostics — safe |

```bash
mac-cleanup --profile dev --dry-run               # preview the dev preset
mac-cleanup --profile deep --exclude 14,17 --yes  # heavy sweep, skip a few
```

See the dedicated [Profiles](profiles.md) page for the why behind each
preset.

---

## Confirmation & behaviour

### `--yes`, `-y`

```
--yes
-y
```

Auto-confirm `[y/N]` prompts. Combine with `--all` for **fully unattended**
runs. The literal-`yes` confirmation in section 14 (`/private/var/folders`)
is **not** affected — that prompt has its own independent gate.

`--yes` **alone never enables the deep-interactive sections** (6, 11, 14,
21, 24) under `--only` / `--profile` / `--all`. Running one of those in batch
also requires [`--i-understand-deep`](#--i-understand-deep). So
`--only 21 --yes` (without `--i-understand-deep`) is **refused** in batch
mode — the tool warns and skips the section. A `--dry-run` preview is always
allowed.

```bash
mac-cleanup --all --yes                # unattended safe batch (no deep sections)
mac-cleanup --only 21 --yes --dry-run  # preview only — section 21 won't delete here
mac-cleanup --only 21 --yes --i-understand-deep   # actually auto-uninstall idle apps
```

> **Caveat for `--only 21 --yes --i-understand-deep`** — combined, this will
> move every app idle ≥ 100 days (or your custom `--threshold`) to the Trash
> without prompting. Read the
> [Section 21 reference](sections.md#section-21--apps-unused-n-days)
> before doing this on a production laptop.

---

### `--i-understand-deep`

```
--i-understand-deep
```

Required — **in addition to `--yes`** — to let the deepest, irreversible
sections run unattended via `--only` / `--profile` / `--all`. The gated set is:

- Section 6 — system caches wiped as root
- Section 11 — Time Machine local snapshots deleted
- Section 14 — `/private/var/folders` deep wipe
- Section 21 — app uninstall + companion data
- Section 24 — large stale files → Trash

Without this flag, those sections are **refused** in batch mode (so a
one-character typo of a section number can't trigger them) — the tool prints
a warning and skips them. `--dry-run` previews are always allowed, since they
cannot touch disk. This **replaces** any earlier notion that `--yes` alone
runs deep sections: it does not, and `--all` (even `--all --yes`) never runs
them.

```bash
mac-cleanup --only 14 --yes --i-understand-deep            # unattended deep wipe
mac-cleanup --profile deep --yes --i-understand-deep       # full heavy sweep, unattended
```

---

### `--dry-run`

```
--dry-run
```

Show what **would** be cleaned without deleting anything. Every destructive
helper checks this flag and prints `[dry-run] …` instead of executing.

This is the **single most useful flag** in the toolkit. Use it the first
time you run any section, the first time you wire it into a script, and
the first time you point it at a new machine.

```bash
mac-cleanup --dry-run --all                  # preview the safe batch
mac-cleanup --only 23 --dry-run              # preview just the stale-build sweep
mac-cleanup --only 24 --large-file-size-gb 2 --large-file-days 180 --dry-run
```

Combine freely with any other flag — `--dry-run` always wins.

---

### `--no-sudo`

```
--no-sudo
```

Skip **every section that needs sudo**. Useful when you're on a machine
where you don't have admin rights, or when you want to verify that the
non-privileged sections do their job alone.

Sections that need sudo: 6, 7 (system logs portion), 9 (system updates
portion), 11, 13, 14, 20, 25 (system LaunchAgents portion), and 27 (only
the optional system font-cache clear).

```bash
mac-cleanup --all --no-sudo            # safe batch, user-space only
```

---

### `--quiet`

```
--quiet
```

Suppress `info` and `note` lines. Errors and warnings still appear. Best
combined with `--all --yes` for cron output.

```bash
mac-cleanup --all --yes --quiet --notify
```

---

### `--json`

```
--json
```

Emit a **one-line JSON run summary** on stdout. **All other output (the human
session summary, logs, warnings) is redirected to stderr**, so stdout carries
nothing but the single JSON object. Implies `--quiet`. Best paired with
`--only` / `--all` for scripting and CI.

The object has this shape:

```json
{
  "tool": "mac-cleanup",
  "version": "4.5.0",
  "dry_run": false,
  "freed_kb": 1048576,
  "disk_free_delta_kb": 1310720,
  "elapsed_s": 42,
  "sections_done": [3, 5, 7],
  "reports": ["/Users/you/.mac-cleanup/reports/orphans-2026-06-08.txt"],
  "log_file": "/Users/you/.mac-cleanup/logs/mac-cleanup-2026-06-08.log"
}
```

- `freed_kb` — total tracked KB freed this run.
- `disk_free_delta_kb` — change in free space on `/` (clamped to ≥ 0).
- `sections_done` — section numbers that completed.
- `reports` — paths of any report `.txt` files that exist after the run.

```bash
mac-cleanup --only 3,5 --yes --json
mac-cleanup --all --yes --json | jq .freed_kb
```

---

### `--no-color`

```
--no-color
```

Disable ANSI colour output. Auto-disabled on non-TTYs, so you usually only
need this when piping to `less -R` or copying terminal output into a doc.

---

### `--notify`

```
--notify
```

Show a macOS notification banner when the run finishes. Uses
`osascript`'s `display notification` with the `Glass` system sound.
Quietly no-ops if `osascript` isn't on PATH (e.g. headless environments).

```bash
mac-cleanup --all --yes --notify --quiet
# → terminal stays quiet; you get a notification when it's done
```

---

### `--check-update`

```
--check-update
```

Query the public npm registry for the latest published version of
`macleanup`. Prints one of these **tagged sentences** (not a bare
`OK` / `WARN`):

- **`[ OK ]`** — "you are on the latest published version (X.Y.Z)".
- **`[WARN]`** — "newer version available — installed X, latest Y", followed
  by a `note` with the upgrade hint `npx macleanup@latest`.
- **`[WARN]`-style note** — "Update check: registry returned no version
  field." if the registry response is missing a `version`.
- **(silent)** — on network failure. Connect timeout is 4 seconds, total
  timeout 6 seconds; the run is never blocked.

This is the **only** outbound network call the entire script can make,
and it's strictly opt-in. **Zero user data is sent** — it's a single
unauthenticated GET to `https://registry.npmjs.org/macleanup/latest`.

```bash
mac-cleanup --check-update             # one-line update advisory
```

---

### `--brew-autoremove`

```
--brew-autoremove
```

Run `brew autoremove` as part of section 3 (Package manager caches).

**Off by default since 4.3.1.** `brew autoremove` can uninstall formulae
that were originally installed as dependencies and are now considered
"unused" — in practice this can remove `node`, `python`, `openssl`, etc.,
silently breaking every globally-installed tool that depended on them.

If you really want it (well-curated brew setup, you understand the risk),
opt in:

```bash
mac-cleanup --only 3 --brew-autoremove --dry-run
```

If a previous 4.3.0 run with the old default broke your tools, see
[Recovery Guide](recovery-guide.md).

---

## Threshold flags — tuning what counts as "old"

These flags tune what each section considers "old enough to remove."
Defaults are deliberately conservative (100 days). Lower them if you
clean often; raise them if you only clean every six months.

### `--threshold N`

```
--threshold 60
```

Days an app must be idle (no last-used signal) to be flagged in section
21 (Apps unused N+ days). Default `100`.

The detection uses **5 signal sources** in priority order — Spotlight
`kMDItemLastUsedDate`, Saved Application State mtime, Container mtime,
Preferences plist mtime, Spotlight `kMDItemUseCount`. Apps with **no
usable signal** are skipped (under-flagged) to avoid false positives.

```bash
mac-cleanup --only 21 --threshold 60       # apps idle ≥ 60 days
mac-cleanup --only 21 --threshold 365      # apps idle a year or more
```

---

### `--cache-age-days N`

```
--cache-age-days 30
```

Age threshold (days) for cache pruning in sections 1, 2, 3. Files whose
**both** atime AND mtime are ≥ N days old are deleted; recently-touched
files survive. Default `100`.

This is what makes the "100-day rule" work — a Gradle distribution you
invoke once a month keeps recent atime, so it survives every pass even
if the file was downloaded 6 months ago.

```bash
mac-cleanup --only 3 --cache-age-days 30   # aggressive monthly clean
mac-cleanup --only 3 --cache-age-days 0    # full wipe (old <4.3.2 behaviour)
```

`0` disables the filter entirely — equivalent to "delete everything."

---

### `--idle-days N`

```
--idle-days 100
```

**Universal idle threshold for non-cache work.** It plays two distinct
roles:

- **Delete gate** in section 12 (Orphaned app data) and section 23 (Stale
  build artefacts) — `--stale-build-days` defaults to this value. Here it
  enforces the **two-condition rule** introduced in 4.3.3: an item is
  deleted only when **both** hold:
  1. It is **not in use** by any installed software/tool (the per-section
     detection determines this).
  2. It has been **untouched (atime AND mtime) for ≥ N days**.
- **Highlight threshold** in section 16 (iOS / iPadOS backups) and section
  17 (Xcode archives). There it does **not** gate deletion — it only flags
  items idle ≥ N days with an `[idle ≥Nd]` marker (recent ones show
  `(recent)`). Those sections are interactive-only and will delete any item
  you confirm, recent or not.

Default `100`. In the gated sections, pass `0` to disable condition (2) and
revert to the 4.3.2 behaviour where mtime alone gated deletion.

```bash
mac-cleanup --only 12 --idle-days 30       # orphan scan, only items idle ≥ 30d
mac-cleanup --only 23 --idle-days 0        # purely heuristic (no idle gate)
mac-cleanup --only 16 --idle-days 180      # backups idle ≥ 180d highlighted
```

See [Safety Model — The two-condition rule](safety-model.md#the-two-condition-rule)
for why this exists.

---

### `--stale-build-days N`

```
--stale-build-days 90
```

Days threshold for stale build artefacts in section 23 (`node_modules`,
`vendor`, `dist`, `.next`, `target`, `Pods`, etc.). Falls back to
`--idle-days` if unset. Default `100`.

```bash
mac-cleanup --only 23 --stale-build-days 30 --dry-run
```

---

### `--large-file-days N`

```
--large-file-days 180
```

Days threshold for unused large files in section 24 (Large stale files).
Default `100`. Files where **both** atime AND mtime are ≥ N days old are
candidates for moving to Trash.

```bash
mac-cleanup --only 24 --large-file-days 365 --large-file-size-gb 5
```

---

### `--large-file-size-gb N`

```
--large-file-size-gb 2
```

Minimum size in GB for the section 24 scan. Default `1`. Smaller numbers
surface more candidates but slow the scan.

```bash
mac-cleanup --only 24 --large-file-size-gb 5 --large-file-days 180 --dry-run
```

---

### `--scan-roots "P1:P2:…"`

```
--scan-roots "$HOME/Projects:$HOME/Code:$HOME/work"
```

Override the auto-detected scan roots for sections 23 and 24. Roots are
**colon-separated absolute paths**.

If unset, the script auto-detects common dev folders (in order):
`~/Projects`, `~/projects`, `~/Code`, `~/code`, `~/Developer`, `~/dev`,
`~/repos`, `~/work`, `~/Work`, `~/Documents`, `~/Desktop`, `~/Downloads`.

If none of those exist **and** no `--scan-roots` is supplied, section 23
errors out and asks you to provide one. **It will not silently fall back
to scanning all of `$HOME`** — that was the 4.3.0 bug.

```bash
mac-cleanup --only 23 --scan-roots "$HOME/repos:$HOME/code" --dry-run
```

See [Recovery Guide](recovery-guide.md) for why this safety rail exists.

---

### `--exclude-path PATH`

```
--exclude-path "$HOME/Code/keep-this"
```

Never touch `PATH` **or anything under it** in the scanning sections 23
(Stale build artefacts) and 24 (Large stale files). The flag is
**repeatable** — pass it multiple times to protect several trees. Each entry
is enforced as a literal-path plus subtree guard (`PATH` and `PATH/*`), in
addition to the always-on `CRITICAL_HOME_DIRS` protection.

```bash
mac-cleanup --only 23 \
  --exclude-path "$HOME/Code/active-project" \
  --exclude-path "$HOME/Code/client-work" --dry-run
```

---

## Output & persistence flags

### `--logs-dir PATH`

```
--logs-dir /tmp/mc-logs
```

Persistent logs directory. Default: `$HOME/.mac-cleanup/logs`.

The log file for the current day is `mac-cleanup-YYYY-MM-DD.log`. Each
file starts with a credits banner (tool, version, author, repo, npm URL,
timestamp, host) so it's self-attributing.

You can also set the env var `MAC_CLEANUP_LOGS_DIR` to the same effect:

```bash
export MAC_CLEANUP_LOGS_DIR=/var/log/mac-cleanup
```

---

### `--reports-dir PATH`

```
--reports-dir /tmp/mc-reports
```

Persistent reports directory. Default: `$HOME/.mac-cleanup/reports`.

Every section that produces a list (orphans, idle apps, large files,
stale builds, large stale files, launch audit, disk usage) writes its
findings to a dated `.txt` file here. See [Reports & Logs](reports-and-logs.md).

Env var: `MAC_CLEANUP_REPORTS_DIR`.

---

### `--no-reports`

```
--no-reports
```

Skip writing per-section `.txt` report files. The session log is still
written. Useful when you're chaining many `--only N` invocations and
don't want the reports folder to fill up.

---

### `--cleanup-logs-on-finish`

```
--cleanup-logs-on-finish
```

Delete this run's log file at exit. Default behaviour is to **keep all
logs forever** (one per day, ~50 KB each, virtually free).

Use this when you're spelunking and don't want the log noise:

```bash
mac-cleanup --only 18 --cleanup-logs-on-finish      # one-shot scan, no log
```

---

## Informational flags

### `--list`

```
--list
```

Print every section number and label, then exit. Useful for memory
refreshing without launching the menu.

```bash
mac-cleanup --list
# →
# mac-cleanup v4.5.0 — section catalogue
#    [ 0] System health & process monitor
#    [ 1] Xcode caches, DerivedData, simulators
#    ...
#    [26] Disk usage report (~/* and ~/Library/*)
#    [27] macOS UI maintenance: QuickLook + font caches
```

The catalogue runs 0–27 (28 sections). Section 27 (QuickLook + font caches)
is menu / `--only` only — it is not part of the `--all` safe batch.

---

### `--version`, `-V`

```
--version
-V
```

Print version and exit.

```bash
mac-cleanup --version          # mac-cleanup 4.5.0
```

---

### `--contact`

```
--contact
```

Print the author contact card and exit. Email, website, LinkedIn, GitHub,
project repo, npm URL.

---

### `--feedback`

```
--feedback
```

Open your default mail client with a prefilled message to the author.
Subject auto-fills with `Feedback: mac-cleanup vX.Y.Z`. Body includes
your macOS version. **Nothing is auto-sent** — you review and click Send
yourself.

Falls back to printing the email address if `open` is unavailable
(headless / sandbox).

---

### `--report-issue`

```
--report-issue
--report-bug   # alias
```

Open a **pre-filled GitHub issue** at
`github.com/aoneahsan/macleanup/issues/new`. The body includes:

- mac-cleanup version
- macOS version + chip (ARM/Intel)
- RAM
- bash version, Node version
- The most recent log file path

Environment info is collected **entirely locally**. Nothing is transmitted
until **you** click Submit on github.com. If `pbcopy` is available, the
last 50 lines of the latest log are copied to your clipboard so you can
paste them straight into the issue body.

---

### `--stats`

```
--stats
```

Show a read-only summary of your run history under `~/.mac-cleanup/`:

- data directory location
- number of logs and total size
- oldest and newest log
- number of reports and total size
- recent report list (most recent 8)
- pointers to `--feedback`, `--report-issue`, `--contact`

```bash
mac-cleanup --stats
```

---

### `--prune-history [N]`

```
--prune-history          # default N = 90
--prune-history 30
```

Delete **logs and reports older than N days** from `~/.mac-cleanup`
(both the `logs/` and `reports/` subdirs), where `N` defaults to `90`. Files
newer than N days are kept. Honours [`--dry-run`](#--dry-run) — with it, the
files that *would* be removed are listed but nothing is deleted. This is a
quick-exit command (it does not enter the menu or batch run).

```bash
mac-cleanup --prune-history 30 --dry-run   # preview what a 30-day prune removes
mac-cleanup --prune-history                # actually prune anything older than 90d
```

---

### `--uninstall-data`

```
--uninstall-data
```

Remove the **entire `~/.mac-cleanup` data directory** — logs, reports, and
the first-run marker — after a literal-`yes` confirmation. Honours
[`--dry-run`](#--dry-run) (prints what it would remove and exits). A
quick-exit command.

```bash
mac-cleanup --uninstall-data --dry-run     # see what would be removed
mac-cleanup --uninstall-data               # remove it (asks to confirm)
```

---

### `-h`, `--help`

```
-h
--help
```

Print the inline help (also embeds defaults from the runtime config) and
exit. The output is similar to this page but condensed for terminal use.

---

## Config file (`~/.mac-cleanuprc`)

Defaults can be set in a config file so you don't have to repeat flags. The
file is `~/.mac-cleanuprc` by default, or wherever `$MAC_CLEANUP_RC` points.
It is read **before** the command line, so **explicit CLI flags always
override it**.

Format: simple `key=value` lines, one per line. Lines starting with `#` and
blank lines are ignored. The file is parsed with `read` (never sourced or
`eval`'d), only a whitelist of keys is honoured, and malformed lines warn
and are skipped — a stray line can never brick the tool.

Recognised keys:

| Key | Type | Equivalent flag |
|---|---|---|
| `cache-age-days` | int | [`--cache-age-days`](#--cache-age-days-n) |
| `idle-days` | int | [`--idle-days`](#--idle-days-n) |
| `threshold` | int | [`--threshold`](#--threshold-n) |
| `stale-build-days` | int | [`--stale-build-days`](#--stale-build-days-n) |
| `large-file-days` | int | [`--large-file-days`](#--large-file-days-n) |
| `large-file-size-gb` | int | [`--large-file-size-gb`](#--large-file-size-gb-n) |
| `scan-roots` | string | [`--scan-roots`](#--scan-roots-p1p2) |
| `quiet` | `1`/`true` | [`--quiet`](#--quiet) |
| `notify` | `1`/`true` | [`--notify`](#--notify) |
| `brew-autoremove` | `1`/`true` | [`--brew-autoremove`](#--brew-autoremove) |

```ini
# ~/.mac-cleanuprc
cache-age-days = 60
idle-days = 120
large-file-size-gb = 2
notify = true
```

---

## Environment variables

Two env vars mirror the `--logs-dir` and `--reports-dir` flags. CLI flags
take precedence if both are set. (`MAC_CLEANUP_RC` additionally points the
config-file loader at a non-default config path.)

| Variable | Equivalent flag |
|---|---|
| `MAC_CLEANUP_LOGS_DIR` | `--logs-dir` |
| `MAC_CLEANUP_REPORTS_DIR` | `--reports-dir` |
| `MAC_CLEANUP_RC` | path to the config file (default `~/.mac-cleanuprc`) |

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Run completed (or info command — `--list`, `--version`, etc. — exited cleanly) |
| `1` | Platform check failed (not macOS, or bash too old) |
| `2` | CLI parsing error (bad flag, missing argument, unknown profile) |
| `127` | Node launcher couldn't spawn `bash` |
| (signal) | Re-raised the same signal it received (Ctrl+C, SIGTERM, etc.) |

The script propagates `SIGINT`, `SIGTERM`, `SIGHUP`, `SIGQUIT` from the
Node launcher to the bash child, so Ctrl+C inside `npx` cleanly kills
the underlying script.

---

## Combining flags — common compounds

| Goal | Compound flags |
|---|---|
| Preview the safe batch | `--dry-run --all` |
| Unattended cron / launchd | `--all --yes --quiet --notify` |
| Read-only audit | `--profile audit --dry-run` |
| Developer caches only | `--profile dev --cache-age-days 60 --yes` |
| Stale `node_modules` only | `--only 23 --stale-build-days 90 --dry-run` |
| Big files only | `--only 24 --large-file-size-gb 5 --large-file-days 180 --dry-run` |
| Skip everything that needs sudo | `--all --no-sudo` |
| Heavy sweep, skip the reboot one | `--profile deep --exclude 14 --yes` |

---

## See also

- [Sections (0–27)](sections.md) — what each section actually does
- [Profiles](profiles.md) — the five named bundles in detail
- [Safety Model](safety-model.md) — the two-condition rule, sudo handling, dry-run guarantees
- [Examples Cookbook](examples-cookbook.md) — recipe-style command compounds
- [Recovery Guide](recovery-guide.md) — restoring tools after a 4.3.0 run

---

_CLI reference for **mac-cleanup** v4.5.0 by **[Ahsan Mahmood](author.md)**._
