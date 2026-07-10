# FAQ

> Plain-English answers to the questions people ask about `mac-cleanup`
> first. For step-by-step problem-solving see [Troubleshooting](troubleshooting.md).

---

## General

### Will this brick my Mac?

Not if you read each prompt and stay away from section 14
(`/private/var/folders`) unless you intend to reboot. Sections marked
**"sudo + REBOOT"** in the menu and `--list` output are explicit. Every
destructive operation confirms by default; `--dry-run` lets you preview
without touching disk.

### Is it safe for production / work machines?

Yes — with two caveats:

1. Always [`--dry-run` once](getting-started.md#step-2--preview-before-you-delete-recommended-first-move)
   the first time on any new machine.
2. Don't combine `--all --yes` with sections you haven't reviewed.
   `--all --yes` is appropriate for trusted profiles like `--profile
   minimal --yes`. It's not appropriate for "let me just run the whole
   thing on a freshly-cloned image."

See [Safety Model — What you remain responsible for](safety-model.md#what-you-remain-responsible-for).

### What does it cost?

Nothing. The tool is free and MIT-licensed — use it however you like. See
[LICENSE.md](../LICENSE.md). If it saves you time, [a GitHub star](https://github.com/aoneahsan/macleanup)
is the kindest thank-you.

### Does it collect any telemetry?

**None.** The script makes zero network calls by default. The Node
launcher (`bin/mac-cleanup.js`) only spawns bash — no analytics, no
phone-home, no remote requests. The optional `--check-update` is the
only outbound network call, and it sends no user data — a single
unauthenticated GET to `https://registry.npmjs.org/macleanup/latest`.
Logs and reports stay on your machine in `~/.mac-cleanup/`.

### Why does it ship as one file instead of `brew install`?

Single-file install means: no `curl | bash`, no signing-key surface, no
homebrew tap, you read every line before running. Drop it in `~/bin/`
and you're done. See [Installation — Method 3](installation.md#method-3--direct-git-checkout-no-node-required).

### Can I read the source before running it?

Yes — and you should. The whole tool is two files:
[`mac-cleanup.sh`](https://github.com/aoneahsan/macleanup/blob/main/mac-cleanup.sh)
(~3,000 lines of plain bash) and
[`bin/mac-cleanup.js`](https://github.com/aoneahsan/macleanup/blob/main/bin/mac-cleanup.js)
(~80 lines of plain Node). Open them in any editor.

### What happens when I run `npx macleanup`?

`npx` downloads the published package from the npm registry into npm's
cache, runs `bin/mac-cleanup.js` (which spawns the bundled
`mac-cleanup.sh` via `bash`), and lets npm reclaim the cache afterwards.
Your reports and logs are written to `~/.mac-cleanup/` and are **never
inside** the cache, so they survive every `npx` invocation.

### Is this OSI-approved open source?

Yes — it's **MIT licensed**. You can read, run, modify, redistribute, and
even sell it, as long as you keep the copyright and license notice. See
[LICENSE.md](../LICENSE.md).

---

## Usage

### What's the minimum command I should know?

```bash
npx macleanup --dry-run --all
```

Previews the safe batch on your machine without touching anything. Read
the output, then re-run without `--dry-run` (or with `--profile minimal
--yes` for the safe weekly subset).

### What's the difference between `--all` and `--profile deep`?

| | `--all` | `--profile deep` |
|---|---|---|
| Sections | The 10-section **safe batch** only: `0, 3, 5, 7, 8, 9, 15, 18, 22, 26` | 14 sections: `0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 17, 19, 23, 26` |
| Best for | Unattended cache/log/temp/report sweep | Scripted monthly cleanup |
| Confirmations | Per-section (unless `--yes`) | Per-section (unless `--yes`) |
| Deep sections (6, 11, 14, 21, 24) | **Never** — even with `--yes`; need `--i-understand-deep` | Section 6 only, and still needs `--i-understand-deep` |
| Section 13 (`periodic`) | Excluded (removed from `--all` in 4.5.0) | Excluded |

`--all` runs only the safe batch — caches, logs, temp, and read-only
reports — and never the deep sections. `--profile deep` is a wider,
pre-trimmed list for unattended use, but its deep sections (6) still require
`--i-understand-deep`.

### How do I run the same combination every week?

Either:

1. **Use a profile** if one matches: `mac-cleanup --profile minimal --yes`
2. **Shell-alias it:**
   ```bash
   alias mac-clean-week='mac-cleanup --only "5,7,8,9,10" --yes --quiet --notify'
   ```
3. **Cron / launchd** for fully automated. See
   [Examples Cookbook — Unattended cron job](examples-cookbook.md#unattended-cron-job).

### Can I add my own custom section?

Absolutely — the MIT license lets you fork, edit, and redistribute
freely (the script is ~3,000 lines of straightforward bash, all sections
are independent functions named `s00_health`, `s01_xcode`, etc.). For
mainline features, [open an
issue](https://github.com/aoneahsan/macleanup/issues/new) describing
the use case.

### What's the difference between sections 18 and 24?

| | Section 18 | Section 24 |
|---|---|---|
| What | Top 25 files ≥ 500 MB | Files ≥ N GB AND idle ≥ M days |
| Default size threshold | 500 MB | 1 GB |
| Default age threshold | none (just size) | 100 days |
| Mode | Read-only report | Bulk move-to-Trash with confirmation |
| Use case | "Where is my disk?" triage | "Reclaim what I've forgotten about" |

Run section 18 first to see what's large. Run section 24 if section 18
shows files you'd forgotten about.

---

## Behaviour & detection

### "It says 'no large stale files found' — but Finder shows me a 5 GB file!"

Section 24 requires **both** `atime` AND `mtime` to be older than the
threshold. If you opened the file recently (atime updated) it won't be
flagged. Lower the threshold (`--large-file-days 30`) or use section 18
instead — section 18 reports purely by size with no idle filter.

### Section 23 / `--profile dev` reports zero stale builds even though I have old `node_modules`

Two likely causes:

1. **Your IDE is keeping the directory's atime fresh.** Even reading
   files for autocomplete updates atime. Lower the threshold:
   `mac-cleanup --only 23 --stale-build-days 30 --dry-run`.
2. **The directory is in `CRITICAL_HOME_DIRS`.** Section 23 will never
   touch `~/.bun`, `~/.pnpm-store`, `~/.cargo`, etc. — see
   [Safety Model](safety-model.md#critical_home_dirs--the-section-23-allowlist).

### Section 21 missed an app I haven't used in years

Section 21 uses **5 signal sources** to determine "last used":

1. Spotlight `kMDItemLastUsedDate`
2. Saved Application State mtime
3. Container mtime
4. Preferences plist mtime
5. Spotlight `kMDItemUseCount`

If **none** are usable, the script **under-flags** (skips the app) to
avoid false positives. Common cause: Spotlight is re-indexing — give it
an hour and try again. See [Section 21 reference](sections.md#section-21--apps-unused-n-days).

### Why doesn't `--all` clean section 14 / 21 / 16 / 17 / 10?

Those are the deepest, most-irreversible operations:

- **Section 14** (`/private/var/folders`) requires a reboot afterwards.
  Auto-running it would surprise users.
- **Section 21** (uninstall apps) is per-item or bulk-with-multi-select
  by design; bulk auto-uninstalling every "idle" app on a machine is
  rarely what someone running `--all` wants.
- **Section 16/17** (iOS backups, Xcode archives) are large, slow to
  recreate, and worth a per-item review.
- **Section 10** (Empty Trash) is a one-way operation — even Apple's
  own UI requires explicit confirmation.

You can include them with `--only`, and pass `--yes` to bypass the
standard `[y/N]` prompt — but section 14's literal-`yes` gate is
unconditional.

---

## Permissions & sudo

### Why does it ask for `sudo`?

Some sections touch `/Library/Caches`, `/Library/Logs`,
`/private/var/log`, `/private/var/folders`, the macOS update cache, the
DNS resolver, the `periodic` maintenance scripts, or system
LaunchDaemons. All of those require root.

If you don't want sudo at all:

```bash
mac-cleanup --all --no-sudo
```

The sudo-requiring sections will be skipped, **never silently
bypassed** — you'll see a log line for each.

### It asked for sudo and I closed the prompt — what now?

Re-run the same command. Sudo credentials cache for ~5 minutes; if you
type your password successfully on one section, the next sudo section
in the same run won't prompt again.

---

## Output & files

### Where do my logs and reports live?

By default, in your home directory — never in the npx cache:

```
~/.mac-cleanup/logs/      # session logs (one per day)
~/.mac-cleanup/reports/   # per-section reports (one per day per type)
```

Override with `--logs-dir PATH` and `--reports-dir PATH`, or set
`MAC_CLEANUP_LOGS_DIR` / `MAC_CLEANUP_REPORTS_DIR` in the env. See
[Reports & Logs](reports-and-logs.md).

### Why does each report start with author info?

So each artefact is **self-attributing**. Paste a report into a Slack
channel or a GitHub issue and your colleague immediately knows which
tool generated it. Disable per-section reports with `--no-reports`
(logs still written).

### How do I clear my run history?

```bash
rm -rf ~/.mac-cleanup/
```

That wipes logs, reports, and the welcome marker. Next run will
re-create the directory and show the welcome.

For "rolling 30-day logs only," see [Reports & Logs — Cleaning up old
logs](reports-and-logs.md#cleaning-up-old-logs).

---

## Recovery / 4.3.0 incident

### A previous `4.3.0` run broke my `pnpm` / `yarn` / `bun` — what do I do?

Upgrade and run a one-line restore. The full guide is at
[Recovery Guide](recovery-guide.md), but in short:

```bash
# bun
curl -fsSL https://bun.sh/install | bash

# pnpm
corepack enable && corepack prepare pnpm@latest --activate

# yarn
corepack enable && corepack prepare yarn@stable --activate

# upgrade mac-cleanup itself
npx macleanup@latest --version    # confirm 4.5.0+
```

The 4.3.1+ releases protect you from this happening again.

### Is the 4.3.0 issue still possible in 4.5.0?

No. The fix is twofold and permanent:

1. **`CRITICAL_HOME_DIRS` allowlist** — section 23 refuses to enter
   ~50 named toolchain/IDE/secrets directories, regardless of basename
   match.
2. **No silent `$HOME` fallback** — section 23 errors out and asks for
   `--scan-roots` if no common dev folder exists.

See [Safety Model — `CRITICAL_HOME_DIRS`](safety-model.md#critical_home_dirs--the-section-23-allowlist).

---

## Project & licensing

### Can I include `mac-cleanup` in my own product / SaaS / public installer script?

Yes. mac-cleanup is **MIT licensed**, so you're free to use, modify,
redistribute, bundle, and even sell it — the only condition is that you
keep the copyright and license notice in your copies. See
[LICENSE.md](../LICENSE.md) for full terms.

### Can I contribute?

Yes — issues and pull requests are welcome, but acceptance is at the
author's sole discretion (it's a single-file project where consistency
matters more than feature breadth). See
[CONTRIBUTING.md](../CONTRIBUTING.md).

### How do I report a security issue?

Email <aoneahsan@gmail.com> rather than opening a public GitHub issue.
See [SECURITY.md](../SECURITY.md).

### How do I report a non-security bug?

```bash
mac-cleanup --report-issue
```

Opens a pre-filled GitHub issue with your environment info collected
**locally** (you review before clicking Submit; nothing is auto-sent).
The last 50 lines of your latest log are copied to clipboard so you can
paste them into the issue.

---

## Author

### Who built this?

**[Ahsan Mahmood](author.md)** — senior software engineer, macOS power
user, maker of small sharp tools.

- 🌐 [aoneahsan.com](https://aoneahsan.com)
- 💼 [linkedin.com/in/aoneahsan](https://linkedin.com/in/aoneahsan)
- 🐙 [github.com/aoneahsan](https://github.com/aoneahsan)
- 📧 [aoneahsan@gmail.com](mailto:aoneahsan@gmail.com)
- 📱 +92 304 6619706

If `mac-cleanup` saved you time, [a GitHub star](https://github.com/aoneahsan/macleanup)
and [a share with a fellow Mac developer](#) are the kindest thank-yous.

### How can I support the project?

- ⭐ Star the [GitHub repo](https://github.com/aoneahsan/macleanup).
- 🐦 Share it with a fellow Mac developer.
- 💼 Hire the author for consulting / contract work — see [aoneahsan.com](https://aoneahsan.com).
- 💬 Send feedback via `mac-cleanup --feedback`.

See [Author & Credits](author.md) for more.

---

## See also

- [Getting Started](getting-started.md) — first-run walkthrough
- [Troubleshooting](troubleshooting.md) — symptom → cause → fix
- [Recovery Guide](recovery-guide.md) — restoring tools after 4.3.0
- [Safety Model](safety-model.md) — the rules in detail

---

_FAQ for **mac-cleanup** v4.5.0 by **[Ahsan Mahmood](author.md)**._
