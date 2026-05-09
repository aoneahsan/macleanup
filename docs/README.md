# mac-cleanup — Documentation

> The complete reference for **mac-cleanup**, a comprehensive, safe-by-default
> macOS cleanup & maintenance tool — one bash file, twenty-seven targeted
> sections, zero install via `npx`.

Welcome. This documentation set explains every feature, flag, profile,
safety rule and section that ships with `mac-cleanup`. If the
[README](../README.md) is the elevator pitch, this folder is the manual.

- **Project:** [github.com/aoneahsan/macleanup](https://github.com/aoneahsan/macleanup)
- **npm:** [npmjs.com/package/macleanup](https://www.npmjs.com/package/macleanup)
- **Author:** [Ahsan Mahmood](author.md) · [aoneahsan.com](https://aoneahsan.com) · [LinkedIn](https://linkedin.com/in/aoneahsan) · [GitHub](https://github.com/aoneahsan)
- **Current version:** `4.4.1`
- **License:** Source-Available (see [LICENSE.md](../LICENSE.md))

---

## Who this tool is for

`mac-cleanup` is built for people who want to **understand exactly what gets
deleted from their Mac** before a single byte is removed. That includes:

- **macOS developers** drowning in stale `node_modules`, `vendor`, `.next`,
  `target`, `Pods`, Xcode `DerivedData`, Gradle wrappers, CocoaPods caches,
  Docker layers, `.gradle`, `.bun`, `.pnpm-store` clutter.
- **Power users** who reach for the Terminal before reaching for a paid app
  like CleanMyMac.
- **Sysadmins / SREs** who want a scriptable, auditable, dry-run-first
  cleanup pass for fleet machines or cron.
- **Anyone reclaiming disk space** after Xcode, simulators, virtual machines,
  iOS backups, browser caches, or runaway log files quietly ate 40 GB.

If you have ever typed `du -sh ~/Library/Caches/*` and felt sad, this tool
is for you.

---

## Documentation map

### Start here
| Page | What it covers |
|---|---|
| [Getting Started](getting-started.md) | The 60-second tour: install, run, understand the menu |
| [Installation](installation.md) | All three install paths (`npx`, global `npm`, git clone) with troubleshooting |
| [CLI Reference](cli-reference.md) | Every command-line flag, what it does, when to use it |

### Reference
| Page | What it covers |
|---|---|
| [Sections (0–26)](sections.md) | Deep dive on every one of the 27 cleanup sections |
| [Profiles](profiles.md) | The 5 named bundles (`dev`, `minimal`, `cache-only`, `deep`, `audit`) |
| [Safety Model](safety-model.md) | Two-condition rule, `CRITICAL_HOME_DIRS`, sudo handling, dry-run guarantees |
| [Reports & Logs](reports-and-logs.md) | What gets written to `~/.mac-cleanup/` and how to read it |

### Operating playbooks
| Page | What it covers |
|---|---|
| [Examples Cookbook](examples-cookbook.md) | Recipe-style commands for common goals |
| [Recovery Guide](recovery-guide.md) | If a `4.3.0` run broke a global toolchain — restore in minutes |
| [Troubleshooting](troubleshooting.md) | Symptoms → causes → fixes |
| [FAQ](faq.md) | Plain-English answers to the questions people ask first |

### Meta
| Page | What it covers |
|---|---|
| [Author & Credits](author.md) | About the author, how to support the project |

---

## What makes mac-cleanup different

| Capability | mac-cleanup | Typical "cleaner" apps | A blog `rm -rf ~/Library` post |
|---|---|---|---|
| Confirms before deleting | **always (per section)** | sometimes | never |
| Tells you what each path is | **yes** | rarely | no |
| Handles companion data when uninstalling apps | **yes (12 paths checked)** | partly | no |
| Skips Apple-managed caches automatically | **yes** | yes | no |
| Real `--dry-run` that never deletes a byte | **yes** | sometimes | no |
| Source you can read in any editor | **yes (~3000 lines, 2 files)** | no | n/a |
| Network calls / telemetry | **zero** | usually | n/a |
| Costs money | **no** | yes | no |
| Distribution channels | npx, npm, direct git checkout | App Store / paid installer | copy-paste |

---

## Quick start

If you want one command to read first, this is it:

```bash
npx macleanup --dry-run --all
```

That previews every safe section without touching disk. From there you can
graduate to the [interactive menu](getting-started.md#first-run-walkthrough)
or wire it into a [cron-friendly automation](examples-cookbook.md#unattended-cron-job).

---

## How to read this documentation

- **You only need a Terminal and an editor.** No build step, no static-site
  generator, no JavaScript framework.
- **Sections are independent.** You can jump to [Section 23 — Stale build
  artefacts](sections.md#section-23--stale-build-artefacts) without reading
  any of the other 26.
- **Every CLI flag is hyperlinked to its purpose** in the [CLI
  Reference](cli-reference.md).
- **Safety guarantees are spelled out**, not implied. The [Safety
  Model](safety-model.md) page explains the rules the script holds itself
  to — including the **two-condition rule for non-cache deletes** that was
  introduced in 4.3.3.

---

## Author

`mac-cleanup` is built and maintained by **[Ahsan Mahmood](author.md)** —
senior software engineer, macOS power user, maker of small sharp tools.

- 🌐 [aoneahsan.com](https://aoneahsan.com)
- 💼 [linkedin.com/in/aoneahsan](https://linkedin.com/in/aoneahsan)
- 🐙 [github.com/aoneahsan](https://github.com/aoneahsan)
- 📧 [aoneahsan@gmail.com](mailto:aoneahsan@gmail.com)
- 📱 +92 304 6619706

If `mac-cleanup` reclaims disk space for you, the kindest thank-you is a
⭐ on the [GitHub repo](https://github.com/aoneahsan/macleanup) and a share
with a fellow Mac developer. See the [Author & Credits](author.md) page
for more on how to support the project.

---

> _Documentation last reviewed against `mac-cleanup` v4.4.1._
