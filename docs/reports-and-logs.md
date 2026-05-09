# Reports & Logs

> Where everything `mac-cleanup` writes lives, what's in each file, and
> how to keep it tidy.

By default, every run leaves three things behind:

1. **A session log** — one per day, append-only, every action recorded.
2. **Per-section reports** — dated `.txt` files for sections that
   produce candidate lists.
3. **A welcome marker** — once, on first run.

All three live under `~/.mac-cleanup/` so they survive `npx` cache
cleanup, npm cache purges, and macOS restarts.

---

## Default file layout

```
~/.mac-cleanup/
├── .welcomed                                 # marker — disables welcome screen
├── logs/
│   └── mac-cleanup-YYYY-MM-DD.log           # one session log per day
└── reports/
    ├── orphans-YYYY-MM-DD.txt               # section 12 candidates
    ├── unused-apps-YYYY-MM-DD.txt           # section 21 candidates
    ├── large-files-YYYY-MM-DD.txt           # section 18 candidates
    ├── stale-build-YYYY-MM-DD.txt           # section 23 candidates
    ├── large-stale-YYYY-MM-DD.txt           # section 24 candidates
    ├── launch-audit-YYYY-MM-DD.txt          # section 25 candidates
    └── disk-usage-YYYY-MM-DD.txt            # section 26 output
```

The dating convention is `YYYY-MM-DD` (ISO 8601). Multiple runs on the
same day **append to** the log file but **overwrite** the report files
(reports are snapshots; the freshest one wins).

---

## Overriding paths

Two ways to point logs and reports somewhere else:

**Per-invocation, via flags:**

```bash
mac-cleanup --logs-dir /tmp/mc-logs --reports-dir /tmp/mc-reports
```

**Persistently, via env vars** (e.g. in `~/.zshrc`):

```bash
export MAC_CLEANUP_LOGS_DIR=/var/log/mac-cleanup
export MAC_CLEANUP_REPORTS_DIR=/var/log/mac-cleanup
```

Both can point to the same directory if you prefer. The directories are
created if they don't exist (best-effort `mkdir -p`).

---

## The session log — `logs/mac-cleanup-YYYY-MM-DD.log`

Format: each line begins with an ISO-8601 timestamp and a level tag.

```
[2026-05-10 12:34:56] [INFO] Starting mac-cleanup v4.4.1
[2026-05-10 12:34:57] [INFO] Section 1: Xcode caches…
[2026-05-10 12:34:58] [OK]   ~/Library/Developer/Xcode/DerivedData → 12.4 GB freed
[2026-05-10 12:35:01] [WARN] xcrun simctl delete unavailable failed
```

Every file starts with a fixed credits banner — see [The branding
header](#the-branding-header) below. Multiple runs on the same day
append; the file grows until you delete it or pass `--cleanup-logs-on-finish`.

### Reading the log

```bash
tail -50 ~/.mac-cleanup/logs/mac-cleanup-$(date +%Y-%m-%d).log
less ~/.mac-cleanup/logs/mac-cleanup-2026-05-10.log
```

Or use the `--stats` command to find the latest log path:

```bash
mac-cleanup --stats
```

### Cleaning up old logs

By default logs persist forever (one per day, ~50 KB each — virtually
free). Three options to clean up:

| Approach | Command |
|---|---|
| Delete this run's log on exit | `mac-cleanup --cleanup-logs-on-finish` |
| Manual cleanup of old logs | `find ~/.mac-cleanup/logs -name '*.log' -mtime +90 -delete` |
| Wipe everything | `rm -rf ~/.mac-cleanup/logs/` |

If you need a "rolling 30-day window" effect, drop this in cron / `launchd`:

```bash
find ~/.mac-cleanup/logs -name 'mac-cleanup-*.log' -mtime +30 -delete
```

---

## The reports — `reports/*.txt`

Seven different report types, each named for the section that produces
it. Every file starts with the [branding header](#the-branding-header),
followed by a section-specific subtitle and the candidate list.

### `orphans-YYYY-MM-DD.txt` — Section 12

Orphaned app data candidates. Each entry shows size, path, and the
detection reason (orphan match + idle threshold).

```
[branding header]

Section 12 — Orphaned app data
Threshold: idle ≥ 100 days

  840M    ~/Library/Application Support/SomeUninstalledApp
  312M    ~/Library/Containers/io.example.GhostApp
  ...
```

Use this to **review at your leisure**. Re-run section 12 interactively
when you're ready to delete.

### `unused-apps-YYYY-MM-DD.txt` — Section 21

Apps idle ≥ `--threshold` days. Each entry shows days idle, app size,
companion-data size, last-used date, bundle ID, app path.

```
[branding header]

Section 21 — Apps unused N+ days
Threshold: 100 days

  365 days  1.2 GB app  340M data  2024-12-04  com.example.OldEditor   /Applications/OldEditor.app
  ...
```

### `large-files-YYYY-MM-DD.txt` — Section 18

Top 25 files ≥ 500 MB anywhere under `$HOME` (with exclusions). Sorted
by size descending. Read-only — section 18 never deletes anything.

```
[branding header]

Section 18 — Large files report (advisory only)

  4.8G   ~/Downloads/macOS-Sonoma.dmg
  2.1G   ~/Documents/dataset.parquet
  ...
```

### `stale-build-YYYY-MM-DD.txt` — Section 23

Stale build artefacts (`node_modules`, `vendor`, `dist`, `.next`,
`target`, `Pods`, etc.) under your scan roots, both atime AND mtime
≥ threshold.

```
[branding header]

Section 23 — Stale build artefacts
Threshold: 100 days idle

  1.3G   180d   ~/repos/old-project/node_modules
  840M   140d   ~/work/legacy/dist
  ...
```

### `large-stale-YYYY-MM-DD.txt` — Section 24

Files ≥ N GB whose both atime AND mtime are ≥ M days old.

```
[branding header]

Section 24 — Large stale files
Thresholds: ≥ 1 GB AND ≥ 100 days idle

  3.2G   200d   ~/Documents/old-VM.qcow2
  ...
```

### `launch-audit-YYYY-MM-DD.txt` — Section 25

LaunchAgents/LaunchDaemons whose target binary is missing.

```
[branding header]

Section 25 — LaunchAgents / LaunchDaemons audit

  ~/Library/LaunchAgents/com.example.helper.plist  →  /usr/local/bin/example-helper (MISSING)
  ...
```

### `disk-usage-YYYY-MM-DD.txt` — Section 26

`du -sh` for direct children of `$HOME` and `~/Library`, sorted, top 20.

```
[branding header]

Section 26 — Disk usage report

$HOME (top 20):
   1.2G  ~/Downloads
   8.4G  ~/Documents
  ...

~/Library (top 20):
   2.1G  ~/Library/Caches
  ...
```

---

## The branding header

Every report and every log file begins with a fixed credits banner. It
makes each artefact self-attributing — paste one in a Slack channel and
your colleague knows exactly what generated it.

```
═════════════════════════════════════════════════════════════════════
  mac-cleanup v4.4.1 — comprehensive macOS cleanup & maintenance
─────────────────────────────────────────────────────────────────────
  Author    : Ahsan Mahmood <aoneahsan@gmail.com>
  Website   : https://aoneahsan.com
  LinkedIn  : https://linkedin.com/in/aoneahsan
  GitHub    : https://github.com/aoneahsan
  Repo      : https://github.com/aoneahsan/macleanup
  npm       : https://www.npmjs.com/package/macleanup
  Run at    : 2026-05-10 12:34:56 PKT
  Host      : Ahsans-MacBook-Pro / macOS 14.5 (arm64)
═════════════════════════════════════════════════════════════════════
```

To **disable per-section reports** entirely (logs still written):

```bash
mac-cleanup --no-reports
```

---

## The welcome marker — `.welcomed`

The first time you run `mac-cleanup` on a machine, it shows a one-time
welcome screen explaining what the tool does, where reports go, and how
to get help.

After acknowledgement, an empty marker file is created at
`~/.mac-cleanup/.welcomed`. Subsequent runs skip the welcome.

To see the welcome again:

```bash
rm ~/.mac-cleanup/.welcomed
```

---

## Inspecting your run history — `--stats`

```bash
mac-cleanup --stats
```

Prints a tidy summary:

```
mac-cleanup — runtime stats
─────────────────────────────────────────────
Data directory: /Users/you/.mac-cleanup

   Logs        : 14 files, 720K total
                 oldest mac-cleanup-2026-04-26.log
                 newest mac-cleanup-2026-05-10.log
   Reports     : 6 files, 48K total

Recent reports:
   • 2026-05-10   disk-usage-2026-05-10.txt
   • 2026-05-10   stale-build-2026-05-10.txt
   • 2026-05-10   unused-apps-2026-05-10.txt
   ...

Get help
   mac-cleanup --feedback       email Ahsan
   mac-cleanup --report-issue   open a pre-filled bug report
   mac-cleanup --contact        full contact card
```

Useful as a quick sanity check before a deep run, or when you want to
remember what you cleaned and when.

---

## Privacy and what's NOT in your reports

- **No telemetry, no upload.** Reports stay on your machine.
- **No system identifiers** beyond what you can read in the branding
  header (hostname, macOS version, chip).
- **No file contents.** Reports list paths and sizes, never bytes from
  files.
- **No bundle metadata** beyond names, IDs, and last-used dates from
  Spotlight.

If you redact paths from a report before sharing (e.g. for a GitHub
issue), grep for your username:

```bash
sed "s|$USER|user|g" ~/.mac-cleanup/reports/orphans-2026-05-10.txt
```

---

## Wiping everything mac-cleanup left behind

```bash
rm -rf ~/.mac-cleanup/
```

This wipes logs, reports, and the welcome marker. Next run will re-create
the directory and show the welcome.

---

## See also

- [CLI Reference — logs/reports flags](cli-reference.md#--logs-dir-path)
- [Sections (0–26)](sections.md) — which sections write reports
- [Getting Started — Step 5](getting-started.md#step-5--find-your-reports)

---

_Reports & logs guide for **mac-cleanup** v4.4.1 by **[Ahsan Mahmood](author.md)**._
