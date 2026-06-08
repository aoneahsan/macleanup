# Profiles

> Five named bundles of sections for common workflows. Pick one with
> `--profile NAME`, optionally subtract sections with `--exclude`.

Profiles are nothing more than **named lists of section numbers**. They
exist so you don't need to memorise which sections go together for the
weekly sweep vs the monthly deep clean. You can reproduce any profile by
hand with `--only`, but the named form is faster to type and easier to
remember.

| Profile | Section list | When to use |
|---|---|---|
| [`dev`](#profile-dev)        | `1, 2, 3, 4, 23` | Reclaim developer-tool caches and stale `node_modules` |
| [`minimal`](#profile-minimal)    | `5, 7, 8, 9, 10` | Quick weekly sweep, mostly safe |
| [`cache-only`](#profile-cache-only) | `3, 5, 6, 7, 9, 19` | Every cache layer; nothing else |
| [`deep`](#profile-deep)       | `0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 17, 19, 23, 26` | Big monthly cleanup |
| [`audit`](#profile-audit)      | `0, 12, 18, 21, 25, 26` | Read-only diagnostics — safe |

> **Rule of thumb:** Always `--dry-run` a profile the first time you use
> it. Combine with `--exclude` to subtract sections you're not ready for.

---

## Profile `dev`

Sections **1, 2, 3, 4, 23** — Xcode + Android/Gradle + package managers
+ Docker + stale build artefacts.

The everyday developer profile. Cleans the things that grow the fastest
on a coding machine without touching system state, system caches, or
sudo paths.

```bash
mac-cleanup --profile dev --dry-run                   # preview
mac-cleanup --profile dev --yes                       # execute
mac-cleanup --profile dev --cache-age-days 60 --yes   # tighter cache window
```

**What it actually does:**

| Section | What | Reclaims |
|---|---|---|
| [1](sections.md#section-1--xcode-caches-deriveddata-simulators) | Xcode caches, DerivedData, simulators | Often 10–60 GB |
| [2](sections.md#section-2--android--gradle-caches) | Android / Gradle caches | 1–10 GB |
| [3](sections.md#section-3--package-manager-caches) | npm, yarn, pnpm, brew, pip, pod, cargo, go, gem | 2–20 GB |
| [4](sections.md#section-4--docker-prune) | Docker containers/images/volumes | 0–60 GB |
| [23](sections.md#section-23--stale-build-artefacts) | Stale `node_modules`, `vendor`, `dist`, `.next`, `target`, `Pods`, etc. | 1–30 GB |

**Pair with:**

- `--cache-age-days 60` — tighter window if you clean monthly
- `--stale-build-days 30` — more aggressive stale-build sweep
- `--scan-roots "$HOME/repos:$HOME/work"` — restrict section 23 scope

**Safety notes:**

- No sudo required.
- Section 4 (Docker) confirms before pruning — even with `--yes` you'll
  need it explicit if the daemon isn't running. The default prune
  (`docker system prune -a -f`) **preserves named volumes**; volume
  deletion is a separate literal-`yes` prompt that is skipped in batch
  mode, so `--only 4 --yes` never deletes volume data.
- Section 23 is heavily safety-hardened (`CRITICAL_HOME_DIRS` allowlist,
  refuses to scan all of `$HOME`). Read [Section 23 reference](sections.md#section-23--stale-build-artefacts).

---

## Profile `minimal`

Sections **5, 7, 8, 9, 10** — User caches + logs + temp + update caches
+ Trash.

The quick weekly housekeeping profile. Touches only user-space, only
short-lived data. Safe to run every Monday morning.

```bash
mac-cleanup --profile minimal --dry-run
mac-cleanup --profile minimal --yes
```

**What it actually does:**

| Section | What |
|---|---|
| [5](sections.md#section-5--user-caches) | `~/Library/Caches` (preserves Apple, browsers, password managers) |
| [7](sections.md#section-7--logs) | User log files > 7 days |
| [8](sections.md#section-8--temp-files) | Temp files > 1 day in `$TMPDIR`, `/tmp`, `~/tmp` |
| [9](sections.md#section-9--update-caches) | `~/Library/Updates` |
| [10](sections.md#section-10--empty-trash) | Empty Trash (asks first) |

**Safety notes:**

- No sudo required for any of these (system log/system update portions
  of sections 7 and 9 silently skip without sudo).
- Section 10 (Trash) requires explicit `[y/N]` confirmation even with
  `--yes`. Pass `--all --yes` if you want it auto-emptied.

---

## Profile `cache-only`

Sections **3, 5, 6, 7, 9, 19** — every cache layer.

When a single tool is misbehaving and you suspect a corrupted cache
somewhere on the machine.

```bash
mac-cleanup --profile cache-only --dry-run
mac-cleanup --profile cache-only --yes
```

**What it actually does:**

| Section | What | Sudo? |
|---|---|---|
| [3](sections.md#section-3--package-manager-caches) | Package manager caches | — |
| [5](sections.md#section-5--user-caches) | User caches | — |
| [6](sections.md#section-6--system-caches) | System caches | sudo |
| [7](sections.md#section-7--logs) | Logs (user + system) | sudo for system |
| [9](sections.md#section-9--update-caches) | Update caches | sudo for system |
| [19](sections.md#section-19--browser-caches) | Browser caches (Chrome, Firefox, Brave, Arc, Edge) | — |

**When to use:**

- "My code editor / Spotlight / Xcode is acting weird" — clear caches
  before deeper debugging.
- Before re-installing a dev tool — so its cache rebuilds from scratch.
- After a macOS point-release update that left stale caches behind.

**Safety notes:**

- Browser caches mean **next page loads will be slower** until they
  rebuild. Section 19 warns explicitly.

---

## Profile `deep`

Sections **0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 17, 19, 23, 26** — the
"everything except the truly dangerous" sweep.

The big monthly clean. Includes every cache layer, every regenerable
build artefact, and Xcode archives. Excludes section 14
(`/private/var/folders` + reboot) and the per-item review sections (12,
16, 21, 25) which are more meaningful to run interactively.

```bash
mac-cleanup --profile deep --dry-run
mac-cleanup --profile deep --yes
mac-cleanup --profile deep --exclude 17 --yes  # skip Xcode archives review
```

**What it actually does:**

| # | Section |
|---|---|
| 0 | System health & process monitor (baseline) |
| 1 | Xcode caches |
| 2 | Android / Gradle caches |
| 3 | Package manager caches |
| 4 | Docker prune |
| 5 | User caches |
| 6 | System caches (sudo) |
| 7 | Logs (sudo for system) |
| 8 | Temp files |
| 9 | Update caches |
| 17 | Xcode archives (per-item review) |
| 19 | Browser caches |
| 23 | Stale build artefacts |
| 26 | Disk usage report (final) |

**Why this list:** Section 0 at the start gives you a baseline. Section
26 at the end shows you the result. Everything in between is actionable
cache and build cleanup. Per-item review sections (12 orphans, 16 iOS
backups, 21 idle apps, 25 launch agents) are excluded because they
benefit from your eyes — run them separately.

**Safety notes:**

- Will request sudo for sections 6, 7, 9.
- Section 17 (Xcode archives) is per-item interactive — even with
  `--yes`, it prompts per archive. Use `--exclude 17` to skip.
- Plan ~5–15 minutes for completion depending on cache sizes.

---

## Profile `audit`

Sections **0, 12, 18, 21, 25, 26** — read-only diagnostics + report-only
sections.

Pure-information mode. Nothing is deleted unless you also pass `--yes`
to the per-item review sections.

```bash
mac-cleanup --profile audit                    # interactive review of orphans/apps/launch items
mac-cleanup --profile audit --dry-run          # report-only, no review
```

**What it actually does:**

| # | Section | Mode |
|---|---|---|
| 0 | System health & process monitor | Read-only |
| 12 | Orphaned app data scan | Per-item review (or report-only in batch) |
| 18 | Large files report | Read-only |
| 21 | Apps unused N+ days | Per-item review (or report-only in batch) |
| 25 | LaunchAgents / LaunchDaemons audit | Per-item review (or report-only in batch) |
| 26 | Disk usage report | Read-only |

**When to use:**

- Inheriting a Mac from a previous owner / employee.
- "Where is all my disk space?"
- After a major upgrade — find what's stale.
- Before backing up — identify what's worth backing up vs cleaning first.

**Output:** Six report files dropped in `~/.mac-cleanup/reports/`. Read
them at your leisure. See [Reports & Logs](reports-and-logs.md).

---

## Combining profiles with other flags

Profiles compose with every other flag:

```bash
# Preview the dev preset with a tighter cache window
mac-cleanup --profile dev --cache-age-days 60 --dry-run

# Run the deep preset, but skip the Xcode archive review and reboot one
mac-cleanup --profile deep --exclude "14,17" --yes

# Audit, but with a notification when scanning finishes
mac-cleanup --profile audit --notify

# Cron-friendly: minimal weekly, fully unattended, quiet, with notification
mac-cleanup --profile minimal --yes --quiet --notify

# Restrict the dev preset to a specific code folder
mac-cleanup --profile dev --scan-roots "$HOME/work" --yes
```

---

## Building your own "profile" without one

Profiles are convenience. If you find yourself running the same custom
combination repeatedly, just shell-alias it:

```bash
# in ~/.zshrc / ~/.bash_profile
alias mac-clean-week='mac-cleanup --only "5,7,8,9,10" --yes --quiet --notify'
alias mac-clean-dev='mac-cleanup --only "1,2,3,4,23" --cache-age-days 60 --yes'
alias mac-clean-audit='mac-cleanup --only "0,12,18,21,25,26"'
```

Or wrap it in a one-line shell function:

```bash
mac-clean-monthly() {
  mac-cleanup --profile deep --exclude 14 --yes --notify
}
```

---

## See also

- [CLI Reference — `--profile`](cli-reference.md#--profile-name)
- [Sections (0–27)](sections.md) — what each section does
- [Examples Cookbook](examples-cookbook.md) — recipe-style commands

---

_Profiles guide for **mac-cleanup** v4.5.0 by **[Ahsan Mahmood](author.md)**._
