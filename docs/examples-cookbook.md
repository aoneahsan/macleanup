# Examples Cookbook

> Recipe-style command compounds for common goals. Copy, paste,
> tweak the threshold or scan root, ship.

Each recipe answers a specific question with a single command. They're
ordered roughly by how often you'll reach for them. Every command is
safe to test with `--dry-run` first.

---

## Quick reference

| Goal | Recipe |
|---|---|
| **Preview the safe batch** | [`--dry-run --all`](#preview-the-safe-batch) |
| **Unattended weekly clean** | [`--all --yes --quiet --notify`](#unattended-cron-job) |
| **Reclaim dev space** | [`--profile dev --yes`](#reclaim-developer-cache-space) |
| **Find every stale `node_modules`** | [`--only 23 --stale-build-days 90 --dry-run`](#find-every-stale-node_modules) |
| **Find dormant 2 GB+ files** | [`--only 24 --large-file-size-gb 2 --large-file-days 180 --dry-run`](#find-dormant-large-files) |
| **Audit login items** | [`--only 25`](#audit-launch-items) |
| **Pre-flight before re-installing Xcode** | [`--only "1,17"`](#pre-flight-before-re-installing-xcode) |
| **Diagnose disk usage** | [`--only "0,18,26"`](#diagnose-where-the-disk-went) |
| **Read-only audit, no deletes** | [`--profile audit --dry-run`](#read-only-audit) |
| **Cleaning up after a stranger** | [`--profile audit`](#cleaning-up-after-a-handed-down-mac) |

---

## Everyday recipes

### Preview the safe batch

The most-asked-for command. Tells you what would change, without
touching disk.

```bash
npx macleanup --dry-run --all
```

Read the output, then re-run without `--dry-run` (or with `--profile
minimal --yes` for the safe weekly subset).

---

### Unattended cron job

Fully unattended weekly housekeeping. Touches only short-lived caches,
logs, temp, and update caches. Safe to run on every machine you own.

```bash
npx macleanup --profile minimal --yes --quiet --notify
```

Wire to cron:

```cron
# every Monday at 3am — minimal weekly sweep
0 3 * * 1   /usr/local/bin/mac-cleanup --profile minimal --yes --quiet --notify
```

Or to launchd (more macOS-native — see `launchctl` and `~/Library/LaunchAgents`).

If you want a heavier monthly clean too:

```cron
# 1st of every month at 3am — deep sweep, notify, skip the reboot one
0 3 1 * *   /usr/local/bin/mac-cleanup --profile deep --exclude 14 --yes --quiet --notify
```

---

### Reclaim developer cache space

The developer-machine sweep. Cleans Xcode, Gradle, Android, package
managers, Docker, and stale `node_modules`. No sudo needed.

```bash
mac-cleanup --profile dev --yes
```

If you only want to reclaim disk **after** you finish a project, tighten
the cache window:

```bash
mac-cleanup --profile dev --cache-age-days 60 --stale-build-days 30 --yes
```

---

### Find every stale `node_modules`

Just the report, no deletions. Tells you which `node_modules` (and
`vendor`, `dist`, `.next`, `target`, `Pods`, etc.) are old and can be
reclaimed.

```bash
mac-cleanup --only 23 --stale-build-days 90 --dry-run
```

Then read the report:

```bash
cat ~/.mac-cleanup/reports/stale-build-$(date +%Y-%m-%d).txt
```

When you're ready, drop the `--dry-run`:

```bash
mac-cleanup --only 23 --stale-build-days 90
```

You'll be shown the candidates, asked to multi-select, and prompted to
confirm before any deletion.

---

### Find dormant large files

Files ≥ 2 GB whose **both** atime AND mtime are ≥ 180 days old.

```bash
mac-cleanup --only 24 --large-file-size-gb 2 --large-file-days 180 --dry-run
```

If you only want to **see** large files (without the "stale" filter),
use section 18 instead:

```bash
mac-cleanup --only 18         # top 25 files >500 MB anywhere under $HOME
```

The difference: section 18 shows you everything large; section 24 shows
you only the ones you've forgotten about.

---

### Audit launch items

Find LaunchAgents/LaunchDaemons whose target binary no longer exists —
common cause of slow login and zombie processes.

```bash
mac-cleanup --only 25
```

Read the report:

```bash
cat ~/.mac-cleanup/reports/launch-audit-$(date +%Y-%m-%d).txt
```

Then re-run interactively to unload + delete the orphans you choose.

---

### Pre-flight before re-installing Xcode

Wipe DerivedData and old archives so the fresh install starts clean.

```bash
mac-cleanup --only "1,17"
```

Section 1 prunes DerivedData, simulators, and CoreSimulator state.
Section 17 reviews `.xcarchive` directories per-item.

---

### Diagnose where the disk went

Read-only triage: system health, large files, disk-usage report.

```bash
mac-cleanup --only "0,18,26"
```

Three reports, no deletions. After reading them, decide which sections
to run.

---

### Read-only audit

Run all six diagnostic / report-only sections in dry-run.

```bash
mac-cleanup --profile audit --dry-run
```

Six reports drop in `~/.mac-cleanup/reports/`. Nothing is deleted, even
if a per-item review section is in the profile.

---

### Cleaning up after a handed-down Mac

You inherited a Mac. Step 1: see what's on it. Step 2: orphan scan.
Step 3: idle apps.

```bash
# 1. Baseline + disk usage + large files
mac-cleanup --only "0,18,26"

# 2. Orphans + launch-item audit (read reports, decide)
mac-cleanup --only "12,25"

# 3. Idle apps — review one by one with companion-data inspection
mac-cleanup --only 21 --threshold 60
```

Each step writes a report. Read them between steps. Don't `--all --yes` a
machine you just inherited — read first.

---

## Targeted single-section recipes

### Just clean Xcode

```bash
mac-cleanup --only 1 --cache-age-days 60 --dry-run
mac-cleanup --only 1 --cache-age-days 60
```

### Just clean Docker

```bash
mac-cleanup --only 4
```

(Docker prune always confirms; no flag bypasses it. The default prune is
`docker system prune -a -f` and **preserves named volumes** — your
stopped-project databases are safe. Volume deletion is a separate prompt
that requires typing `yes` and is skipped entirely in batch mode, so
`--only 4 --yes` never touches volumes.)

### Just clean package managers

```bash
mac-cleanup --only 3
mac-cleanup --only 3 --brew-autoremove        # opt-in to brew autoremove
```

### Just clean browser caches

```bash
mac-cleanup --only 19
```

### Just empty Trash

```bash
mac-cleanup --only 10
```

### Just delete iOS backups (interactive)

```bash
mac-cleanup --only 16
```

### Just review Xcode archives (interactive)

```bash
mac-cleanup --only 17
```

---

## Targeted multi-section combos

### "I'm out of disk and need to free 20 GB now"

```bash
# 1. See where the space went
mac-cleanup --only "26,18"

# 2. Hit the highest-yield sections
mac-cleanup --only "1,4,23" --dry-run    # Xcode + Docker + stale node_modules
mac-cleanup --only "1,4,23"              # ...for real

# 3. If still tight, browser caches + Trash
mac-cleanup --only "19,10"
```

### "I'm setting up the machine for a new project"

```bash
# Free dev caches but keep system + browsers untouched
mac-cleanup --profile dev --cache-age-days 30 --yes
```

### "I'm shipping a CI image"

```bash
# Strip every cache layer, no sudo, no reports
mac-cleanup --profile cache-only --no-sudo --no-reports --yes --quiet
```

---

## Multi-machine / fleet recipes

### Pin a specific version for reproducibility

```bash
npx macleanup@4.5.0 --all --yes --quiet
```

### Same script, multiple workstations

If you operate a fleet, distribute a single shell wrapper:

```bash
#!/usr/bin/env bash
# /usr/local/bin/weekly-mac-clean
set -euo pipefail
exec npx macleanup@4.5.0 \
  --profile minimal \
  --yes --quiet --notify \
  --logs-dir /var/log/mac-cleanup \
  --reports-dir /var/log/mac-cleanup
```

Use launchd to run it weekly. The pinned version means every machine
runs the same logic.

---

## Recipes that warn before they delete

Always pair these with `--dry-run` the first time on any machine.

### Bulk-uninstall idle apps with companion data

```bash
mac-cleanup --only 21 --threshold 180 --dry-run    # see what would go
mac-cleanup --only 21 --threshold 180              # interactive review/bulk
mac-cleanup --only 21 --threshold 180 --yes        # ⚠ auto-uninstall ALL idle apps
```

The third form will move every app idle ≥ 180 days to the Trash. Read
the report before you do this on a machine you care about.

### Heavy monthly sweep with sudo

```bash
mac-cleanup --profile deep --exclude 14 --yes --notify
```

`--exclude 14` skips the `/private/var/folders` wipe (which would
require a reboot afterwards). Everything else in `deep` runs.

### The full kitchen sink (interactive)

```bash
mac-cleanup
```

That's the interactive menu. You pick sections one at a time. Best for
exploration on a new install.

---

## Combining with other shell tools

### Pipe report into Slack via `curl`

```bash
mac-cleanup --only 18 --no-color
sed "s|$USER|me|g" ~/.mac-cleanup/reports/large-files-$(date +%Y-%m-%d).txt \
  | curl -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"\`\`\`$(cat -)\`\`\`\"}" \
    "$SLACK_WEBHOOK_URL"
```

### Email yourself the disk-usage report

```bash
mac-cleanup --only 26 --no-color
mail -s "Disk usage $(date +%Y-%m-%d)" you@example.com \
  < ~/.mac-cleanup/reports/disk-usage-$(date +%Y-%m-%d).txt
```

### Diff today's stale-build report against last week's

```bash
diff -u ~/.mac-cleanup/reports/stale-build-$(date -v-7d +%Y-%m-%d).txt \
        ~/.mac-cleanup/reports/stale-build-$(date +%Y-%m-%d).txt
```

---

## Anti-patterns — recipes to avoid

- **`mac-cleanup --all --yes` on a machine you've never run it on.**
  Use `--dry-run` first. Always.
- **`mac-cleanup --only 14`** without intending to reboot. Section 14
  requires reboot after it runs.
- **Cron `--all --yes` on a laptop running on battery power.** The
  cleanup itself is short, but the I/O can drain a few percent.
- **Running on a Mac you just imaged**, before any apps are installed.
  Section 21 will under-flag (no last-used signals exist), section 12
  will see no installed apps, and you'll get false positives in the
  reports. Run it after at least a week of normal use.

---

## See also

- [CLI Reference](cli-reference.md) — every flag in detail
- [Profiles](profiles.md) — the named bundles powering some recipes
- [Sections (0–27)](sections.md) — what each section does
- [Safety Model](safety-model.md) — the rules behind `--dry-run` and `--yes`

---

_Examples cookbook for **mac-cleanup** v4.5.0 by **[Ahsan Mahmood](author.md)**._
