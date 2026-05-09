<div align="center">

# 🧹 mac-cleanup

### Comprehensive, safe-by-default macOS cleanup & maintenance — in a single bash script.

[![macOS](https://img.shields.io/badge/macOS-11%2B-black?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![bash](https://img.shields.io/badge/bash-3.2%2B-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![npm](https://img.shields.io/npm/v/macleanup.svg?logo=npm&label=npm)](https://www.npmjs.com/package/macleanup)
[![version](https://img.shields.io/badge/version-4.4.1-blue.svg)](#changelog)
[![license](https://img.shields.io/badge/license-Source--Available-orange.svg)](LICENSE.md)
[![status](https://img.shields.io/badge/status-stable-brightgreen.svg)](#)

**One file. Zero dependencies. Twenty-seven targeted sections.
Every destructive action confirms before running.**

[Quick start](#-quick-start) ·
[Sections](#-the-twenty-seven-sections) ·
[Safety](#%EF%B8%8F-safety-model) ·
[FAQ](#-faq) ·
[Author](#-author)

</div>

---

## ✨ Why mac-cleanup

Most cleanup tools either delete too aggressively (and break things) or do too
little (and leave gigabytes of cruft). **mac-cleanup** sits in the middle:

| | Typical cleaner apps | `rm -rf ~/Library` posts | **mac-cleanup** |
|---|---|---|---|
| Confirms before deleting | sometimes | never | **always (per section)** |
| Tells you what each path is | rarely | no | **yes** |
| Handles companion data when uninstalling apps | partly | no | **yes (12 paths checked)** |
| Skips Apple-managed caches | yes | no | **yes** |
| Has a real `--dry-run` | sometimes | no | **yes** |
| Open / inspectable source | no | n/a | **yes** |
| Costs money | yes | no | **no** |

Run it interactively the first time, then use `--only` and `--dry-run` to
script your favourite combinations.

---

## 🚀 Quick start — three ways to run

### 1. Zero-install via `npx` (easiest)

```bash
npx macleanup
```

That's it. npm fetches the package into its cache, runs the interactive
menu, and the cache is reclaimed afterwards. **Your reports and logs are
never inside the cache** — they live at `~/.mac-cleanup/{logs,reports}/`
and survive every `npx` invocation.

```bash
# Preview the safe-batch cleanup without touching anything
npx macleanup --dry-run --all

# Run one specific section
npx macleanup --only 23 --stale-build-days 90 --dry-run

# Show every section, then exit
npx macleanup --list
```

### 2. Global install via `npm`

```bash
npm install -g macleanup
mac-cleanup            # the bin name is just `mac-cleanup`
mac-cleanup --version
```

### 3. Direct git checkout (no Node required)

```bash
git clone https://github.com/aoneahsan/macleanup.git
cd macleanup
chmod +x mac-cleanup.sh
./mac-cleanup.sh
```

> **Tip:** the first time you run a destructive section, pass `--dry-run`.
> You'll see exactly which files would go without touching them.

### Where do my reports + logs live?

By default, **always** in your home directory — never in the npx cache:

```
~/.mac-cleanup/
├── logs/
│   └── mac-cleanup-YYYY-MM-DD.log
└── reports/
    ├── orphans-YYYY-MM-DD.txt
    ├── unused-apps-YYYY-MM-DD.txt
    ├── large-files-YYYY-MM-DD.txt
    ├── stale-build-YYYY-MM-DD.txt
    ├── large-stale-YYYY-MM-DD.txt
    ├── launch-audit-YYYY-MM-DD.txt
    └── disk-usage-YYYY-MM-DD.txt
```

Override either path with `--logs-dir PATH` and `--reports-dir PATH`, or
set `MAC_CLEANUP_LOGS_DIR` / `MAC_CLEANUP_REPORTS_DIR` in the environment.

Every report file starts with a credits header (tool version, author,
repo URL, npm URL, run timestamp, host) so each artefact is
self-attributing.

| Default behaviour | How to change it |
|---|---|
| Logs persist forever in `~/.mac-cleanup/logs/` | Add `--cleanup-logs-on-finish` to delete this run's log on exit |
| Reports written for every relevant section | Add `--no-reports` to skip every `.txt` report (logs still kept) |
| Reports + logs go to `~/.mac-cleanup/` | Use `--logs-dir` / `--reports-dir` |

---

## 🧭 The twenty-seven sections

| # | Section | Sudo? | Notes |
|---|---|:-:|---|
| 0 | System health & process monitor | — | Read-only diagnostic |
| 1 | Xcode caches, DerivedData, simulators | — | |
| 2 | Android / Gradle caches | — | |
| 3 | Package manager caches (npm, yarn, pnpm, brew, pip, pod, cargo, go, ruby, flutter) | — | |
| 4 | Docker prune (containers/images/volumes) | — | Daemon must be running |
| 5 | User caches (`~/Library/Caches`, Saved State) | — | Browsers preserved |
| 6 | System caches (`/Library/Caches`) | sudo | |
| 7 | Logs (user + system) | sudo | Old files only |
| 8 | Temp files (`$TMPDIR`, `/tmp`, `~/tmp`) | — | User-owned only |
| 9 | Update caches | sudo | |
| 10 | Empty Trash | — | Asks first |
| 11 | Time Machine local snapshots | sudo | |
| 12 | Orphaned app-data scan | — | Interactive |
| 13 | System maintenance (`periodic`) | sudo | |
| 14 | Deep cache `/private/var/folders` ⚠ **needs reboot** | sudo | Strong confirm |
| 15 | Installer leftovers report | — | Advisory only |
| 16 | iOS / iPadOS device backups | — | Per-device review |
| 17 | Xcode archives | — | Per-archive review |
| 18 | Large files report | — | ≥500 MB in `$HOME` |
| 19 | Browser caches (Chrome, Firefox, Brave, Arc, Edge) | — | |
| 20 | DNS / mDNS reset | sudo | |
| 21 | Apps unused N+ days — **review or bulk uninstall** | — | Multi-select supported |
| 22 | Purgeable space trigger | — | |
| 23 | **Stale build artefacts** N+ days (`node_modules`, `vendor`, `dist`, …) | — | New in 4.1 |
| 24 | **Large stale files** ≥N GB unused N+ days | — | New in 4.1 |
| 25 | **LaunchAgents / LaunchDaemons audit** (orphaned login items) | sudo* | New in 4.1 |
| 26 | **Disk-usage report** (`$HOME` & `~/Library`) | — | New in 4.1 |

\* Sudo only when removing items under `/Library/`.

### Defaults you can override

| Variable | Default | Flag |
|---|---:|---|
| Days an app must be idle to be flagged | 100 | `--threshold N` |
| Universal idle threshold for non-cache deletes (sec 12, 23) | 100 | `--idle-days N` |
| Days a cache file must be unused (sec 1, 2, 3) | 100 | `--cache-age-days N` |
| Days a build dir must be untouched (sec 23) | 100 | `--stale-build-days N` |
| Days a large file must be untouched (sec 24) | 100 | `--large-file-days N` |
| Min size for the large-file scan (sec 24) | 1 GB | `--large-file-size-gb N` |
| Scan roots for sections 23/24 | auto-detected | `--scan-roots "p1:p2"` |

### The two-condition rule for non-cache deletes (4.3.3+)

Anything that isn't pure regenerable cache — orphan app data, idle apps,
stale `node_modules`, large unused files, iOS backups, Xcode archives —
will only be **deleted automatically** when **both** conditions hold:

1. **Not used by any active software / tool.** The existing detection
   (no installed-app match for orphan data, broken target binary for
   LaunchAgents, no last-used signal for idle apps).
2. **Not touched by you (atime AND mtime) for ≥ 100 days.** Configurable
   via `--idle-days N`. A Gradle distribution you invoke once a month
   keeps recent atime, so it survives. A node_modules whose IDE reads
   files for autocomplete keeps recent atime, so it survives.

`--idle-days 0` disables the second condition entirely (back to the
4.3.2 behaviour where mtime alone was enough).

> **Cache age, by `atime` AND `mtime`** — `--cache-age-days 100` keeps any file
> you've **opened OR modified** in the last 100 days, even if it was downloaded
> 6 months ago. A Gradle distribution you invoke once a month keeps recent
> atime and survives every pass. Pass `--cache-age-days 0` to disable the
> filter entirely (full wipe — old `<4.3.2` behaviour).

---

## 🎛️ Command-line cheat sheet

The same flags work with `npx`, the global `mac-cleanup` bin, or
`./mac-cleanup.sh` — pick whichever invocation fits your workflow.

```bash
mac-cleanup                                       # interactive menu
mac-cleanup --list                                # show every section
mac-cleanup --version                             # print version

mac-cleanup --dry-run --all                       # preview safe batch
mac-cleanup --all --yes                           # unattended safe batch
mac-cleanup --only "5,7,8,9"                      # explicit sections only
mac-cleanup --only 23 --dry-run                   # one section, dry-run

# Section-specific tuning
mac-cleanup --only 21 --threshold 60
mac-cleanup --only 23 --stale-build-days 30 \
            --scan-roots "$HOME/repos:$HOME/code"
mac-cleanup --only 24 --large-file-size-gb 2 --large-file-days 180

# Logs / reports
mac-cleanup --no-reports                          # don't write .txt reports
mac-cleanup --cleanup-logs-on-finish              # delete this run's log at exit
mac-cleanup --logs-dir /tmp/mc --reports-dir /tmp/mc-reports

# Output controls
mac-cleanup --no-color
mac-cleanup --quiet --all --yes
mac-cleanup --no-sudo                             # skip every sudo section

# Profiles + exclude (4.3.0)
mac-cleanup --profile dev --dry-run               # 1,2,3,4,23 → preview
mac-cleanup --profile deep --exclude 14,17 --yes  # heavy sweep, skip a few
mac-cleanup --all --notify --quiet                # OS notification on finish
mac-cleanup --check-update                        # ask npm if newer exists
```

### Profiles

Named bundles for common workflows — pick one with `--profile NAME`:

| Profile | Sections it runs | When to use |
|---|---|---|
| `dev`        | 1, 2, 3, 4, 23 | Reclaim developer-tool cache + stale `node_modules` |
| `minimal`    | 5, 7, 8, 9, 10 | Quick, mostly-safe weekly sweep |
| `cache-only` | 3, 5, 6, 7, 9, 19 | Every cache layer; nothing else |
| `deep`       | 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 17, 19, 23, 26 | Big monthly cleanup |
| `audit`      | 0, 12, 18, 21, 25, 26 | Read-only diagnostics — safe |

Combine with `--exclude` to subtract sections:
`--profile deep --exclude 14,17` runs the deep preset minus those two.

### Interactive multi-select syntax

When a section asks **"Select items (1..N)"** you can type:

| Input | Meaning |
|---|---|
| `all` (or `a`) | Every item |
| `none` (or empty) | Nothing |
| `1,3,5-7,12` | Items 1, 3, 5, 6, 7, 12 |
| `7-3` | Reverse range — auto-swaps to 3..7 |

Out-of-range or junk tokens are silently ignored.

---

## 🛡️ Safety model

mac-cleanup is **safe by default** — but it is also **a tool that runs `rm
-rf` and `sudo`**, and you are responsible for verifying its outputs on
your machine. The design rules:

1. **Destructive ops always prompt** unless you pass `--yes`.
2. **`--dry-run` never deletes anything** — every destructive call routes
   through helpers that no-op in dry mode.
3. **Apps are moved to Trash** (via Finder) where possible, not `rm`-ed.
   You can recover for as long as the Trash isn't emptied.
4. **System caches need explicit `sudo`.** If sudo isn't available the
   section is skipped, never silently bypassed.
5. **The deepest sections** — `/private/var/folders` wipe, app uninstall,
   iOS-backup deletion, Xcode-archive deletion, Trash empty — require a
   typed `yes` and are never part of `--all`.
6. **Logs are written to `logs/`** which is gitignored. Reports of
   orphaned data, unused apps, large files, and stale builds get their
   own dated `.txt` files there for later review.

Even so: **back up before you run any cleanup tool**. A pinned Time
Machine snapshot or `tmutil snapshot` is a good last line of defence.

---

## 🧪 Examples by goal

| Goal | One-liner |
|---|---|
| **"What can I safely free up tonight?"** | `./mac-cleanup.sh --dry-run --all` |
| **Reclaim dev space** | `./mac-cleanup.sh --only "1,2,3,4,23" --dry-run` |
| **Find every `node_modules` >90d old** | `./mac-cleanup.sh --only 23 --stale-build-days 90 --dry-run` |
| **Find dormant 2 GB+ files >6 mo old** | `./mac-cleanup.sh --only 24 --large-file-size-gb 2 --large-file-days 180 --dry-run` |
| **Audit which login items are orphaned** | `./mac-cleanup.sh --only 25` |
| **Pre-flight before reinstalling Xcode** | `./mac-cleanup.sh --only "1,17"` |
| **CI / cron unattended sweep** | `./mac-cleanup.sh --all --yes --quiet` |

---

## 🚑 Recovery — if 4.3.0 broke a global tool

`v4.3.0` had a bug where section 23 (stale build artefacts) could enter
toolchain manager directories like `~/.bun`, `~/.pnpm-store`,
`~/.local/share/pnpm`, `~/.npm-packages`, `~/.volta` and remove
`node_modules`-shaped folders inside them, breaking globally installed
tools. Fixed in 4.3.1 with the new `CRITICAL_HOME_DIRS` allowlist —
section 23 will now refuse to enter these paths regardless of mtime.

If you ran 4.3.0 against `--scan-roots $HOME` (or a 4.3.0 with the silent
$HOME fallback) and your global tools stopped working, here are the
commands to restore the most common ones:

```bash
# bun — single curl one-liner reinstalls it cleanly
curl -fsSL https://bun.sh/install | bash

# pnpm — corepack ships with Node 16+, no extra install needed
corepack enable
corepack prepare pnpm@latest --activate
# then re-install your global pnpm packages, e.g.
pnpm add -g typescript ts-node prettier eslint <other tools you had>

# yarn — same path via corepack
corepack prepare yarn@stable --activate

# nvm + Node — if ~/.nvm is intact, just re-source:
source "$HOME/.nvm/nvm.sh"
nvm use --lts        # or whichever version

# global npm packages — npm caches the list itself; if you have a recent
# npm-shrinkwrap, re-install from it. Otherwise list manually:
npm install -g typescript prettier serve <whatever you had>

# Volta / asdf / fnm / Deno / rbenv / pyenv / rustup — re-run their installers:
curl https://get.volta.sh | bash
curl https://raw.githubusercontent.com/asdf-vm/asdf/master/bin/install | sh
curl -fsSL https://fnm.vercel.app/install | bash
curl -fsSL https://deno.land/install.sh | sh
```

If a brew-installed formula was uninstalled by `brew autoremove` (this
happened if you ran 4.3.0 in `--all` mode and one of your tools'
dependencies was treated as "no longer needed"), `brew autoremove` is
no longer in the default flow as of 4.3.1 — but to restore what got
removed:

```bash
# show recently uninstalled formulae from brew's history
brew log
# re-install whichever of them you still want
brew install node python openssl <whatever>
```

> **Going forward:** `brew autoremove` is now opt-in via `--brew-autoremove`.
> Section 23 has a hard allowlist refusing to touch toolchain dirs and no
> longer falls back to scanning `$HOME` silently — if it can't find one of
> the standard dev folders (`~/Projects`, `~/Code`, `~/Developer`, `~/dev`,
> `~/repos`, `~/work`, `~/Documents`, `~/Desktop`, `~/Downloads`) it
> errors out and asks you to pass `--scan-roots`.

---

## ❓ FAQ

**Will this brick my Mac?**
Not if you read each prompt and stay away from section 14 (`/private/var/folders`)
unless you intend to reboot. Sections marked “sudo + REBOOT” are explicit.

**It says "no large stale files found" — but Finder shows me a 5 GB file!**
Section 24 requires both `atime` AND `mtime` to be older than the threshold.
If you opened the file recently (atime updated) it won't be flagged. Lower
the threshold (`--large-file-days 30`) or use section 18 instead.

**I want it to delete `~/Movies` after 30 days — can I add a section?**
The license forbids modifying & redistributing the script. For your own
private use you can fork and edit, just don't republish. For mainline
features, open an issue describing the use case.

**Why does it ship as one file instead of `brew install`?**
Single-file install means: no curl-pipe-bash, no signing-key surface, no
homebrew tap, you read every line before running. Drop it in `~/bin/` and
you're done.

**Is this OSI-approved open source?**
No — it's **source-available**. You can read, run, and learn from the
source; you cannot redistribute or modify it. See [LICENSE.md](LICENSE.md).

**Do you collect any telemetry?**
None. The script makes zero network calls. The Node launcher
(`bin/mac-cleanup.js`) only spawns bash — no analytics, no phone-home,
no remote requests. Logs and reports stay on your machine in
`~/.mac-cleanup/`.

**What does `npx` actually run?**
`npx macleanup` downloads the published package from the
npm registry into npm's cache, runs `bin/mac-cleanup.js` (which spawns
the bundled `mac-cleanup.sh` via `bash`), and lets npm reclaim the
cache afterwards. Your reports and logs are written to
`~/.mac-cleanup/` and are **never inside** the cache, so they survive.

**Can I read the source before running it?**
Yes — and you should. The whole tool is two files: `mac-cleanup.sh`
(2,400 lines of plain bash) and `bin/mac-cleanup.js` (≈80 lines of
plain Node). Open them in any editor.

---

## 📚 Repository layout

```
macleanup/
├── mac-cleanup.sh   ← the script (read it!)
├── bin/
│   └── mac-cleanup.js   ← tiny Node launcher used by `npx`
├── package.json     ← npm metadata (publishes as macleanup)
├── README.md
├── LICENSE.md
├── NOTICE
├── CHANGELOG.md
├── CONTRIBUTING.md
├── SECURITY.md
└── .gitignore

# At runtime, every invocation reads/writes here (NOT inside the repo):
~/.mac-cleanup/
├── logs/            ← per-day session logs (preserved by default)
└── reports/         ← per-section report .txt files (always preserved)
```

---

## 🔄 Changelog

See [CHANGELOG.md](CHANGELOG.md) for the full history. Highlights:

- **4.2.0** (2026-05) — `npx macleanup` zero-install support
  via a tiny Node launcher. Persistent logs + reports moved to
  `~/.mac-cleanup/{logs,reports}/`. Branded credits header now embedded
  in every log file and every report. New `--logs-dir`,
  `--reports-dir`, `--no-reports`, `--cleanup-logs-on-finish` flags.
  Sections 25 (launch-items) and 26 (du-report) now also write `.txt`
  reports.
- **4.1.0** (2026-05) — Sections 23 (stale build artefacts), 24 (large
  stale files), 25 (LaunchAgents audit), 26 (disk-usage report). New
  `--scan-roots`, `--list`, `--version`, `--no-color` flags. Multi-select
  in section 21. Hardened path quoting; bash-version + macOS preflight.
- **4.0.0** (2026-04) — Single-file rewrite of the modular split.

---

## 💬 Get help, give feedback, report bugs

Three flags, all local-first — nothing is auto-sent. You review every
prefilled message before clicking Submit / Send.

```bash
mac-cleanup --contact         # show the author contact card
mac-cleanup --feedback        # open mail client with prefilled message
mac-cleanup --report-issue    # open a pre-filled GitHub issue
                              # (env info gathered locally, last 50 log
                              #  lines copied to clipboard if available)
mac-cleanup --stats           # show your run history at ~/.mac-cleanup
```

There's also a one-time **welcome screen** the first time you run the
tool on a machine. Marker file at `~/.mac-cleanup/.welcomed`; delete it
to see the welcome again.

If something exits with an error, the script automatically prints a
hint pointing at `--report-issue` so you don't have to remember the
flag name. **No automatic crash submission** — you always choose what
to share.

---

## 🛡️ Security

If you find a security issue (path-traversal, accidental `rm -rf`,
data-leakage scenario), **please report it privately** to
<aoneahsan@gmail.com> rather than opening a public issue. See
[SECURITY.md](SECURITY.md) for details.

---

## 🤝 Contributing

This project is source-available, **not** open-source by OSI definition —
contributions are welcome via issues and pull requests, but acceptance
is at the author's sole discretion. See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## 📜 License

**Source-Available License v1.0** — see [LICENSE.md](LICENSE.md).

In one paragraph: you may **read** and **run** mac-cleanup on your own
machines for personal or internal-business use. You may **not** modify,
redistribute, or sell it. The author offers it AS-IS with no warranty
and is not liable for any data loss or damage. By using it you agree to
indemnify the author against any claim arising from your use.

---

## 👤 Author

<table>
  <tr>
    <td valign="top" width="140">
      <img src="https://github.com/aoneahsan.png" width="120" alt="Ahsan Mahmood" style="border-radius:50%"/>
    </td>
    <td valign="top">
      <b>Ahsan Mahmood</b><br/>
      Senior software engineer · macOS power user · maker of small sharp tools<br/><br/>
      📧 <a href="mailto:aoneahsan@gmail.com">aoneahsan@gmail.com</a><br/>
      🌐 <a href="https://aoneahsan.com">aoneahsan.com</a><br/>
      💼 <a href="https://linkedin.com/in/aoneahsan">linkedin.com/in/aoneahsan</a><br/>
      🐙 <a href="https://github.com/aoneahsan">github.com/aoneahsan</a><br/>
      📱 +92 304 6619706<br/>
    </td>
  </tr>
</table>

If mac-cleanup saved you time, the kindest thank-you is a ⭐ on the
[GitHub repo](https://github.com/aoneahsan/macleanup) and a share
with a fellow Mac developer.

---

<div align="center">

Made with ❤️ and a lot of care.

</div>
