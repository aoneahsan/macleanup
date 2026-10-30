<div align="center">

<img src="https://raw.githubusercontent.com/aoneahsan/macleanup/main/assets/logo/macleanup-mark.svg" alt="macleanup logo" width="120" />

<h1>macleanup</h1>

<p><strong>Safe-by-default macOS cleanup CLI — 28 sections, a real dry-run, zero install via npx.</strong></p>

[![npm version](https://img.shields.io/npm/v/macleanup.svg)](https://www.npmjs.com/package/macleanup)
[![downloads](https://img.shields.io/npm/dm/macleanup.svg)](https://www.npmjs.com/package/macleanup)
[![license](https://img.shields.io/npm/l/macleanup.svg)](https://github.com/aoneahsan/macleanup/blob/main/LICENSE.md)
[![node](https://img.shields.io/node/v/macleanup.svg)](https://nodejs.org)
[![platform](https://img.shields.io/badge/platform-macOS%2011%2B-black?logo=apple&logoColor=white)](https://www.apple.com/macos/)

[Docs](https://macleanup-docs.aoneahsan.com) · [npm](https://www.npmjs.com/package/macleanup) · [GitHub](https://github.com/aoneahsan/macleanup) · [Changelog](https://github.com/aoneahsan/macleanup/blob/main/CHANGELOG.md) · [Support](https://github.com/aoneahsan/macleanup/issues)

</div>

> [!IMPORTANT]
> **This tool deletes files, and some of what it deletes cannot be recovered.** Most sections remove caches
> that rebuild themselves, some move items to the Trash, and a few delete permanently — including emptying
> the Trash itself, removing Time Machine local snapshots, iOS device backups, and Xcode archives.
> Read [what it removes, and whether you can get it back](#what-it-removes-and-whether-you-can-get-it-back)
> before your first run, and use `--dry-run` first. Back up before any cleanup tool.

macleanup is a single bash script that reclaims disk space on macOS across 28 targeted areas — developer
caches, browser caches, system logs, stale build artefacts, unused apps, and more. It is built for people who
want to see what a section would remove before running it: destructive sections confirm by default,
`--dry-run` does not delete files, and the whole tool is two readable files you can inspect first.
It is a terminal tool for macOS only, with no telemetry. `--check-update` contacts npm only when requested.

| | |
|---|---|
| **Version** | `5.0.0` |
| **License** | MIT |
| **Node** | `>=14` (only needed for the `npx` / `npm` install paths) |
| **Platforms** | macOS 11 Big Sur or later · Apple Silicon + Intel |
| **Install size** | ~73 kB packed · ~227 kB unpacked (local 5.0.0 package preview) |
| **Types** | None — this is a CLI, not a library |
| **Status** | Stable · actively maintained |

<a id="table-of-contents"></a>
## 🧭 Table of Contents&nbsp;[#](#table-of-contents)

- [💡 Why macleanup](#why-macleanup)
- [✨ Features](#features)
- [📋 Requirements](#requirements)
- [📦 Installation](#installation)
- [🚀 Quick Start](#quick-start)
- [🛠️ Usage](#usage)
- [⚙️ Configuration](#configuration)
- [💻 Command Line](#command-line)
- [🧪 Examples](#examples)
- [🎛️ Advanced Features](#advanced-features)
- [🚑 Recovery & Troubleshooting](#recovery-troubleshooting)
- [🚧 Limitations](#limitations)
- [❓ FAQ](#faq)
- [📚 Documentation](#documentation)
- [🔄 Changelog](#changelog)
- [🤝 Contributing](#contributing)
- [🗂️ Repository](#repository)
- [💬 Support](#support)
- [📄 License](#license)
- [👤 Author](#author)
- [🔗 Links](#links)
- [🏷️ Keywords](#keywords)

<a id="why-macleanup"></a>
## 💡 Why macleanup&nbsp;[#](#why-macleanup)

macleanup shows the sections and candidate paths before a cleanup. Destructive
sections ask for confirmation by default, and `--dry-run` previews deletion
without deleting files. The preview can still write logs and reports to
`~/.macleanup/`.

| What you can inspect | Where to find it |
|---|---|
| Selected sections and their effects | [`--list`](https://macleanup-docs.aoneahsan.com/reference/cli) and the [sections reference](https://macleanup-docs.aoneahsan.com/reference/sections) |
| Candidate paths before deletion | Run [`--dry-run`](https://macleanup-docs.aoneahsan.com/before-you-run/dry-run) and read the resulting reports |
| What happened during a run | Logs and reports under `~/.macleanup/` |
| The implementation | `macleanup.sh` and `bin/macleanup.js` in this repository |

<a id="what-it-removes-and-whether-you-can-get-it-back"></a>
### What it removes, and whether you can get it back

Sections fall into three tiers. **Knowing which tier you are in is the whole safety model** — a per-section
breakdown is in [Usage](#usage).

| Tier | What happens | Recoverable? |
|---|---|---|
| **Rebuilds** | Caches, logs, temp files and build artefacts are removed from disk. Some caches and build output can be regenerated. | Deleted logs and temp files may hold unique information; restoring those needs a backup. |
| **Moved to Trash** | Uninstalled apps and their companion data (section 21), orphaned app data (12), and large stale files (24) go to the Trash via Finder. | Yes, until you empty the Trash. |
| **Permanently deleted** | Emptying the Trash (10), Time Machine local snapshots (11), iOS/iPadOS device backups (16), Xcode archives (17), LaunchAgent/Daemon plists (25), and pruned Docker **volumes** (4). | **No.** These are gone. |

Two behaviours are easy to miss, and both are real:

> [!WARNING]
> **Emptying the Trash requires a separate opt-in in batch mode.** The `minimal` profile is sections
> `5,7,8,9`; it leaves the Trash alone. Section 10 is available from the interactive menu, or with
> `--only 10 --yes --i-understand-deep` for an intentional unattended run.

> [!WARNING]
> **Finder Automation access is required for moves to the Trash.** If macOS denies it, or Finder is
> unavailable in a headless session, sections 12 and 21 leave the affected app or data in place and warn.

**Not the right tool when** — you want a GUI-first, set-and-forget cleaner; you are on Linux or Windows
(macOS only, enforced); you need a programmatic Node API (there is none — see [Limitations](#limitations));
or you want a guaranteed amount of space back. How much any section frees depends entirely on your machine,
and macleanup does not estimate it in advance.

<a id="features"></a>
## ✨ Features&nbsp;[#](#features)

- **28 targeted sections** — developer caches, browser caches, system caches and logs, temp files, Docker,
  Time Machine snapshots, iOS backups, Xcode archives, stale build artefacts, unused apps, launch items.
- **A dry-run that deletes nothing** — destructive helpers preview their actions; logs and reports may still be written.
- **Per-section confirmation** — destructive work always prompts unless you explicitly pass `--yes`.
- **A deep-section gate** — six high-risk sections refuse to run unattended without a second,
  separate opt-in flag.
- **Two-condition delete rule** — non-cache deletes require both "not in use by any tool" and "untouched for
  N days" (by `atime` *and* `mtime`), so a dependency you use monthly survives.
- **Profiles** — five named bundles (`dev`, `minimal`, `cache-only`, `deep`, `audit`) for common workflows.
- **Report sections** — system health, installer leftovers, large files and
  disk usage write reports. Orphan data and launch-item sections also offer
  confirmed removal, so preview those before acting.
- **Reports and logs on disk** — dated `.txt` reports and per-day logs under `~/.macleanup/`, outside the
  npx cache, so they survive every invocation.
- **Machine-readable output** — `--json` prints a one-line run summary; `--json-events` streams one event per line (plan, every item, per-section result, summary) for scripts and the desktop app.
- **Keep or archive before removal** — `--exclude-path PATH` keeps a path out of every section; `--archive-path PATH` writes it to a private archive in `~/.macleanup/archives/` first.
- **No telemetry** — the script makes no network calls by default. An optional update check contacts npm; npm receives normal request metadata.

<a id="requirements"></a>
## 📋 Requirements&nbsp;[#](#requirements)

| Requirement | Version | Why |
|---|---|---|
| macOS | 11 Big Sur or later | Apple Silicon and Intel. Enforced as Darwin-only; the tool exits on any other platform. |
| bash | `3.2+` | The version Apple ships. Checked at startup and the script exits if it is older. |
| Node.js | `>=14` | Only for the `npx` and `npm install -g` paths. The git-checkout path needs no Node at all. |
| `sudo` | — | Required by some sections only. Without it those sections are skipped, never silently bypassed. |
| Automation permission | — | Needed for the move-to-Trash behaviour. See the warning in [Why macleanup](#why-macleanup). |

<a id="installation"></a>
## 📦 Installation&nbsp;[#](#installation)

```bash
# Zero install — fetched into the npm cache, run, then reclaimed
npx macleanup

# Or install globally
npm install -g macleanup

# Or clone and run directly — no Node required
git clone https://github.com/aoneahsan/macleanup.git
cd macleanup && chmod +x macleanup.sh && ./macleanup.sh
```

The global install adds one command, `macleanup`. Nothing is written outside
`~/.macleanup/` (logs and reports) until you confirm a section.

<a id="quick-start"></a>
## 🚀 Quick Start&nbsp;[#](#quick-start)

Preview first. This writes nothing at all:

```bash
npx macleanup --dry-run --all
```

Then run the interactive menu and pick sections yourself:

```bash
npx macleanup
```

<a id="usage"></a>
## 🛠️ Usage&nbsp;[#](#usage)

### The 28 sections

`Tier` maps to [what it removes, and whether you can get it back](#what-it-removes-and-whether-you-can-get-it-back):
**Report** deletes nothing · **Rebuilds** comes back on its own · **Trash** is recoverable until you empty it ·
**Permanent** is not recoverable.

| # | Section | Tier | Sudo | Notes |
|---|---|---|:-:|---|
| 0 | System health & process monitor | Report | — | Read-only diagnostic |
| 1 | Xcode caches, DerivedData, simulators | Rebuilds | — | |
| 2 | Android / Gradle caches | Rebuilds | — | |
| 3 | Package-manager caches (npm, yarn, pnpm, brew, pip, pod, cargo, go, ruby, flutter) | Rebuilds | — | |
| 4 | Docker prune | Rebuilds / **Permanent** | — | Images re-pull; **pruned volumes do not come back** |
| 5 | User caches (`~/Library/Caches`, Saved State) | Rebuilds | — | Browsers preserved |
| 6 | System caches (`/Library/Caches`) | Rebuilds | sudo | Deep-gated |
| 7 | Logs (user + system) | Rebuilds | sudo | Old files only |
| 8 | Temp files (`$TMPDIR`, `/tmp`) | Rebuilds | — | Top-level user-owned files at least 2 days old; leaves `~/tmp` alone |
| 9 | Update caches | Rebuilds | sudo | |
| 10 | Empty Trash | **Permanent** | — | Deep-gated in batch mode; excluded from `minimal` |
| 11 | Time Machine local snapshots | **Permanent** | sudo | Deep-gated |
| 12 | Orphaned app-data scan | Trash | — | Leaves data in place if Finder cannot move it |
| 13 | System maintenance (`periodic`) | Rebuilds | sudo | Runs Apple's own scripts |
| 14 | Deep cache `/private/var/folders` | Rebuilds | sudo | Deep-gated · **needs a reboot** · typed `yes` |
| 15 | Installer leftovers report | Report | — | Advisory only |
| 16 | iOS / iPadOS device backups | **Permanent** | — | Per-device review |
| 17 | Xcode archives | **Permanent** | — | Per-archive review |
| 18 | Large files report | Report | — | ≥500 MB in `$HOME` |
| 19 | Browser caches | Rebuilds | — | Chromium and Firefox families, all profiles |
| 20 | DNS / mDNS reset | Rebuilds | sudo | Flushes only; deletes nothing |
| 21 | Unused apps — review or bulk uninstall | Trash | — | Deep-gated · leaves app and data in place if Finder move fails |
| 22 | Purgeable space trigger | Report | — | Creates and removes one temp file |
| 23 | Stale build artefacts (`node_modules`, `vendor`, `dist`, …) | Rebuilds | — | Deleted directly, **not** to Trash; reinstall to restore |
| 24 | Large stale files ≥N GB unused N+ days | Trash | — | Deep-gated · Trash only, no direct-delete fallback |
| 25 | LaunchAgents / LaunchDaemons audit | **Permanent** | sudo\* | Unloads then removes the `.plist` |
| 26 | Disk-usage report | Report | — | `$HOME` and `~/Library` |
| 27 | macOS UI maintenance — QuickLook + font caches | Rebuilds | sudo† | Menu or `--only` only |

\* Sudo only when removing items under `/Library/`. † Sudo only for the optional system-wide font-cache clear.

### Running a subset

```bash
macleanup --list                       # print every section, then exit
macleanup --only "5,7,8,9"             # run exactly these
macleanup --profile dev --dry-run      # preview a named bundle
macleanup --all --yes                  # unattended safe batch
```

`--all` runs only the safe batch — sections `0 3 5 7 8 9 15 18 22 26`. Everything else is opt-in.

### Interactive multi-select

When a section asks **"Select items (1..N)"**:

| Input | Meaning |
|---|---|
| `all` or `a` | Every item |
| `none` or empty | Nothing |
| `1,3,5-7,12` | Items 1, 3, 5, 6, 7, 12 |
| `7-3` | Reverse range — auto-swapped to 3..7 |

Out-of-range and junk tokens are ignored.

<a id="configuration"></a>
## ⚙️ Configuration&nbsp;[#](#configuration)

Defaults can be set in `~/.macleanuprc` (or `$MACLEANUP_RC`) as simple `key=value` lines. CLI flags
always override the file.

| Setting | Default | Flag |
|---|---:|---|
| Days an app must be idle to be flagged | 100 | `--threshold N` |
| Idle delete gate (sections 12, 21, 23, 24); idle highlight (16, 17) | 100 | `--idle-days N` |
| Days a cache file must be unused (sections 1, 2, 3) | 100 | `--cache-age-days N` |
| Days a build directory must be untouched (section 23) | 100 | `--stale-build-days N` |
| Days a large file must be untouched (section 24) | 100 | `--large-file-days N` |
| Minimum size for the large-file scan (section 24) | 1 GB | `--large-file-size-gb N` |
| Scan roots for sections 23 and 24 | auto-detected | `--scan-roots "p1:p2"` |

Setting `--idle-days 0` or `--cache-age-days 0` disables that condition entirely.

Logs and reports live in `~/.macleanup/{logs,reports}/` — never inside the npx cache, so they survive every
invocation. Override with `--logs-dir` / `--reports-dir`, or `MACLEANUP_LOGS_DIR` / `MACLEANUP_REPORTS_DIR`.

<a id="command-line"></a>
## 💻 Command Line&nbsp;[#](#command-line)

```bash
npx macleanup [options]
macleanup [options]        # after a global install
```

The command line is the entire public interface — there is no programmatic API.

| Flag | What it does |
|---|---|
| `--list` | Print every section and exit |
| `--version` | Print the version |
| `--dry-run` | Delete nothing; show planned actions and write normal logs or reports |
| `--all` | Run the safe batch |
| `--only "5,7,8"` | Run exactly these sections |
| `--profile NAME` | `dev`, `minimal`, `cache-only`, `deep` or `audit` |
| `--exclude 14,17` | Subtract sections from `--all` or a profile |
| `--exclude-path PATH` | Never scan or touch this tree |
| `--yes` | Auto-confirm prompts. Does **not** unlock the deep sections |
| `--i-understand-deep` | With `--yes`, allow sections 6, 10, 11, 14, 21, 24 unattended and permit section 25 removal in batch mode |
| `--no-sudo` | Skip every section that needs sudo |
| `--threshold N` · `--idle-days N` · `--cache-age-days N` | Age thresholds — see [Configuration](#configuration) |
| `--stale-build-days N` · `--large-file-days N` · `--large-file-size-gb N` | Section 23 and 24 thresholds |
| `--scan-roots "p1:p2"` | Where sections 23 and 24 look |
| `--logs-dir` · `--reports-dir` · `--no-reports` · `--cleanup-logs-on-finish` | Log and report handling |
| `--prune-history N` | Prune logs and reports older than N days |
| `--json` | One-line JSON run summary |
| `--json-events` | NDJSON event stream ([schema](https://github.com/aoneahsan/macleanup/blob/main/docs/json-events.md)) |
| `--exclude-path PATH` · `--archive-path PATH` | Keep a path, or archive it before it is removed (repeatable) |
| `--quiet` · `--no-color` · `--notify` | Output controls |
| `--brew-autoremove` | Opt in to `brew autoremove` (off by default) |
| `--check-update` | Ask npm whether a newer version exists |
| `--stats` · `--contact` · `--feedback` · `--report-issue` | Run history and local-first support flags |
| `--uninstall-data` | Remove `~/.macleanup` (confirms first) |

Full flag reference: [CLI reference](https://macleanup-docs.aoneahsan.com/reference/cli).

<a id="examples"></a>
## 🧪 Examples&nbsp;[#](#examples)

| Goal | Command |
|---|---|
| See what tonight's cleanup would free | `macleanup --dry-run --all` |
| Reclaim developer-tool space | `macleanup --profile dev --dry-run` |
| Find every `node_modules` untouched 90+ days | `macleanup --only 23 --stale-build-days 90 --dry-run` |
| Find dormant 2 GB+ files older than 6 months | `macleanup --only 24 --large-file-size-gb 2 --large-file-days 180 --dry-run` |
| Audit orphaned login items | `macleanup --only 25` |
| Read-only health check | `macleanup --profile audit --dry-run` |
| Unattended cron sweep | `macleanup --all --yes --quiet` |

More recipes: [Recipes](https://macleanup-docs.aoneahsan.com/recipes).

<a id="advanced-features"></a>
## 🎛️ Advanced Features&nbsp;[#](#advanced-features)

- **Profiles** — `dev` (1,2,3,4,23) · `minimal` (5,7,8,9) · `cache-only` (3,5,6,7,9,19) ·
  `deep` (0,1,2,3,4,5,6,7,8,9,17,19,23,26) · `audit` (0,12,18,21,25,26).
  [Details](https://macleanup-docs.aoneahsan.com/reference/profiles).
- **JSON output** — `--all --yes --json | jq .freed_kb` for scripting and dashboards.
- **Toolchain allowlist** — section 23 refuses to enter `~/.bun`, `~/.pnpm-store`, `~/.volta` and similar
  manager directories regardless of file age.
- **Config file** — `~/.macleanuprc` for persistent defaults.
- **Desktop app** — a small native macOS GUI (Tauri) wrapping this same script lives in
  [desktop/](https://github.com/aoneahsan/macleanup/tree/main/desktop). It reimplements no cleanup logic.

<a id="recovery-troubleshooting"></a>
## 🚑 Recovery & Troubleshooting&nbsp;[#](#recovery-troubleshooting)

| Symptom | Cause | Fix |
|---|---|---|
| Finder could not move an item to the Trash | macOS Automation permission not granted, or a headless/SSH session | The item remains in place; grant your terminal Automation access for Finder in System Settings → Privacy & Security |
| "No large stale files found" but Finder shows a big file | Section 24 needs **both** `atime` and `mtime` older than the threshold | Lower `--large-file-days`, or use section 18 instead |
| Section 23 exits asking for `--scan-roots` | It found none of the standard dev folders and will not silently scan `$HOME` | Pass `--scan-roots "$HOME/code:$HOME/repos"` |
| A deep section is skipped under `--yes` | `--yes` alone never unlocks sections 6, 10, 11, 14, 21, 24 | Add `--i-understand-deep`, or run it from the interactive menu |
| Free space did not change after section 14 | `/private/var/folders` needs a reboot to take effect | Reboot |
| A global tool broke after a **v4.3.0** run | A fixed bug let section 23 enter toolchain manager directories | Upgrade to 4.3.1+ and follow the [recovery guide](https://macleanup-docs.aoneahsan.com/recovery) |

More symptoms: [Troubleshooting](https://macleanup-docs.aoneahsan.com/troubleshooting).

<a id="limitations"></a>
## 🚧 Limitations&nbsp;[#](#limitations)

- **macOS only.** Darwin is enforced; the tool exits immediately anywhere else.
- **No programmatic API.** The CLI is the whole interface. Requiring the package from Node is not a supported
  use — the entry point launches the tool rather than exporting anything.
- **No undo.** macleanup has no restore command. Trash can restore items moved
  there; directly deleted items require your own backup.
- **It cannot tell you in advance how much space you will get back.** `--dry-run` estimates the run it is
  about to perform; nothing predicts a number before that.
- **Permission-dependent safety.** Without Automation access, the move-to-Trash guarantee does not hold.
- **Heuristics, not certainty.** The orphaned-app-data matcher and the unused-app detector are heuristics.
  Review what they list; that is why both are interactive.
- **`sudo` sections are genuinely privileged.** They run as root against system paths. Read the prompt.
- **Not audited by a third party.** It is MIT-licensed and two files long — read it before you run it.

<a id="faq"></a>
## ❓ FAQ&nbsp;[#](#faq)

**Will this break my Mac?**
Not if you read each prompt. The riskiest section is 14 (`/private/var/folders`), which needs a reboot
afterwards, requires a typed `yes`, and is excluded from `--all`.

**Does it collect any telemetry?**
No. The script makes no network calls by default, and the Node launcher only
spawns bash. Opt-in `--check-update` asks the npm registry whether a newer
version exists; npm receives normal request metadata, such as your IP address.

**What does `npx macleanup` actually run?**
It downloads the published package into npm's cache and runs `bin/macleanup.js`, which spawns the bundled
`macleanup.sh` through bash. Your logs and reports go to `~/.macleanup/`, never the cache, so they survive.

**Can I read the source before running it?**
Yes, and you should. The tool is two files: `macleanup.sh` (about 3,600 lines of bash) and
`bin/macleanup.js` (about 100 lines of Node).

**Why one bash file instead of a Homebrew formula?**
A single file means no curl-pipe-bash, no tap to trust, and no signing surface — you can read every line
before it runs.

**Can I add my own section?**
Yes — MIT lets you fork and modify freely. For a mainline feature, open an issue describing the use case.

<a id="documentation"></a>
## 📚 Documentation&nbsp;[#](#documentation)

Which document answers which question:

| Document | Read it when |
|---|---|
| [Getting started](https://macleanup-docs.aoneahsan.com/getting-started/first-run) | first run — the menu explained |
| [Installation](https://macleanup-docs.aoneahsan.com/getting-started/installation) | choosing between the three install paths |
| [CLI reference](https://macleanup-docs.aoneahsan.com/reference/cli) | you need the exact flag |
| [Sections 0–27](https://macleanup-docs.aoneahsan.com/reference/sections) | you want to know precisely what one section touches |
| [Profiles](https://macleanup-docs.aoneahsan.com/reference/profiles) | picking a named bundle |
| [Safety model](https://macleanup-docs.aoneahsan.com/before-you-run/safety-model) | you want the guarantees spelled out |
| [Reports & logs](https://macleanup-docs.aoneahsan.com/reference/reports-and-logs) | reading what a run wrote |
| [Examples cookbook](https://macleanup-docs.aoneahsan.com/recipes) | you have a goal, not a flag |
| [Recovery guide](https://macleanup-docs.aoneahsan.com/recovery) | a v4.3.0 run broke a toolchain |
| [Troubleshooting](https://macleanup-docs.aoneahsan.com/troubleshooting) | something behaved unexpectedly |
| [FAQ](https://macleanup-docs.aoneahsan.com/faq) | the questions people ask first |

<a id="changelog"></a>
## 🔄 Changelog&nbsp;[#](#changelog)

Latest release: **`5.0.0`** — one name everywhere. The command is `macleanup`, data lives in `~/.macleanup/`, the config file is `~/.macleanuprc` and environment variables use `MACLEANUP_*`. Upgrading from 4.x moves nothing by hand: the first 5.x run copies your earlier logs and reports and leaves the originals in place. The changelog has the full rename table.

<a id="contributing"></a>
## 🤝 Contributing&nbsp;[#](#contributing)

Fork and open a pull request — see
[CONTRIBUTING.md](https://github.com/aoneahsan/macleanup/blob/main/CONTRIBUTING.md) for setup, standards and
how to request collaborator access. `main` is protected; external contributions go through review.

Security issues go privately to [aoneahsan@gmail.com](mailto:aoneahsan@gmail.com), not a public issue — see
[SECURITY.md](https://github.com/aoneahsan/macleanup/blob/main/SECURITY.md).

<a id="repository"></a>
## 🗂️ Repository&nbsp;[#](#repository)

```text
macleanup.sh   the tool — all cleanup logic lives here (published)
bin/             Node launcher that spawns the script for npx (published)
docs/            the manual
desktop/         optional native macOS GUI (Tauri), separate package
assets/logo/     SVG logo masters
```

Only `macleanup.sh`, `bin/`, and the four root Markdown files ship in the npm tarball. At runtime every
invocation reads and writes `~/.macleanup/{logs,reports}/`, never the repository.

<a id="support"></a>
## 💬 Support&nbsp;[#](#support)

Questions and bugs: [open an issue](https://github.com/aoneahsan/macleanup/issues). The CLI can prefill one
for you with `--report-issue`; you review it before anything is sent.

If macleanup saves you time, you can support its maintenance at
[aoneahsan.com/payment](https://aoneahsan.com/payment?project-id=macleanup&project-identifier=macleanup).

<a id="license"></a>
## 📄 License&nbsp;[#](#license)

MIT © Ahsan Mahmood — see
[LICENSE.md](https://github.com/aoneahsan/macleanup/blob/main/LICENSE.md). Provided as-is, without warranty;
the author is not liable for data loss arising from its use.

<a id="author"></a>
## 👤 Author&nbsp;[#](#author)

**Ahsan Mahmood** — [aoneahsan.com](https://aoneahsan.com) · [GitHub](https://github.com/aoneahsan) ·
[LinkedIn](https://linkedin.com/in/aoneahsan) · [aoneahsan@gmail.com](mailto:aoneahsan@gmail.com)

<a id="links"></a>
## 🔗 Links&nbsp;[#](#links)

| | |
|---|---|
| Documentation | https://macleanup-docs.aoneahsan.com |
| npm | https://www.npmjs.com/package/macleanup |
| Repository | https://github.com/aoneahsan/macleanup |
| Issues | https://github.com/aoneahsan/macleanup/issues |
| Changelog | https://github.com/aoneahsan/macleanup/blob/main/CHANGELOG.md |
| Desktop app | https://github.com/aoneahsan/macleanup/tree/main/desktop |
| Support the project | https://aoneahsan.com/payment?project-id=macleanup&project-identifier=macleanup |

<a id="keywords"></a>
## 🏷️ Keywords&nbsp;[#](#keywords)

*macos · cleanup · maintenance · disk-space · cache · cli · developer-tools · node-modules · xcode · homebrew · dry-run · sysadmin*
