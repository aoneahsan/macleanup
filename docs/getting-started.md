# Getting Started with mac-cleanup

> Five minutes to your first cleanup. No commitment, no install, no risk.

This page walks you through running `mac-cleanup` for the very first time.
By the end you'll have:

- previewed every cleanup it would perform on your machine,
- understood the interactive menu,
- and reclaimed your first few gigabytes (if you choose to).

If you already know `npx`/`npm` and just want flags, jump straight to the
[CLI Reference](cli-reference.md).

---

## Requirements

You need:

| Requirement | Why |
|---|---|
| **macOS 11 Big Sur or later** (Apple Silicon or Intel) | The script targets Darwin and refuses to run elsewhere |
| **bash 3.2+** (ships with macOS by default) | The script self-checks at startup |
| **Terminal access** (Terminal.app, iTerm2, Warp, Ghostty, …) | It's a CLI tool |
| **Optional: Node.js 14+** | Only needed if you want to invoke via `npx` or `npm install -g` |

You **do not need**:

- Homebrew
- A package manager
- Admin permissions for the read-only sections (sudo is requested only when
  needed — see [Safety Model](safety-model.md#sudo-handling))
- An internet connection (the script makes **zero network calls** by default;
  the optional `--check-update` is the only exception)

---

## Step 1 — Run it for the first time (zero install)

The single command worth memorising:

```bash
npx macleanup
```

Here's what happens, in order:

1. `npx` fetches the [`macleanup`](https://www.npmjs.com/package/macleanup)
   package from the npm registry into npm's cache.
2. The tiny Node launcher (`bin/mac-cleanup.js`, ~80 lines) checks you're on
   macOS, locates the bundled `mac-cleanup.sh`, and `exec`s bash with your
   arguments forwarded.
3. The bash script confirms `bash >= 3.2`, then prints the interactive menu.
4. When you exit, npm's cache may be reclaimed — but **your logs and reports
   are written to `~/.mac-cleanup/`**, which survives every `npx` run.

> **Why `npx`?** Single-command, no install, no PATH changes, no need to
> trust a Homebrew tap. You can read the script source online at
> [github.com/aoneahsan/macleanup](https://github.com/aoneahsan/macleanup)
> before you ever run it.

---

## Step 2 — Preview before you delete (recommended first move)

Before you run a single destructive operation, **preview** the safe batch:

```bash
npx macleanup --dry-run --all
```

`--dry-run` routes every destructive call through helpers that **no-op** —
nothing is deleted. You'll see exactly which files would be touched,
section by section. This is the safest way to understand what the tool will
do on **your** machine before you commit.

When you're done previewing, run a single section live:

```bash
npx macleanup --only 5
```

That runs section 5 only (User caches in `~/Library/Caches`) — see [the
sections page](sections.md#section-5--user-caches) for what it actually does.

---

## Step 3 — First-run walkthrough

When you launch `mac-cleanup` without flags, you'll see something like this:

```
mac-cleanup v4.4.0
=====================================================

Choose a section to run (or 'a' for the safe batch, 'q' to quit):

   [0] System health & process monitor
   [1] Xcode caches, DerivedData, simulators
   [2] Android / Gradle caches
   [3] Package manager caches (npm, yarn, pnpm, brew, …)
   [4] Docker prune (containers/images/volumes)
   [5] User caches (~/Library/Caches, Saved State)
   [6] System caches (/Library/Caches) — sudo
   [7] Logs (user + system)
   ...
   [26] Disk usage report (~/* and ~/Library/*)

> _
```

A few rules of thumb for first-time users:

- **Start with `0`.** Section 0 is **read-only** — it tells you about your
  Mac (CPU, RAM, free disk, top processes, battery health). Useful baseline.
- **Try `26` next.** Also read-only. Tells you which folders under `~` and
  `~/Library` are eating disk space, so you know which sections to prioritise.
- **Then try a safe one — section `5` (User caches).** This sweeps
  `~/Library/Caches` while preserving Apple, browser, and password-manager
  entries.
- **Save the deep ones for later.** Sections 14 (`/private/var/folders`),
  21 (uninstall idle apps), and the like are gated behind explicit
  confirmations and are the right tool when you need them — just not at
  minute one.

For each section the script prints what it found, asks for confirmation
where relevant (default is **No** for destructive prompts), and reports how
much space was freed. When the section finishes, you're returned to the
menu — pick another, or type `q` to quit.

---

## Step 4 — Read the on-screen prompts

`mac-cleanup` is **explicit** about every confirmation it asks for. There
are three levels of prompt, escalating by risk:

| Prompt | Default | Used by |
|---|---|---|
| `Continue? [y/N]` | No | Most destructive operations |
| `Per-item: [y/N/q]` | No | Reviewing orphans, idle apps, archives, backups one at a time |
| `Type literal "yes" to continue` | Aborts on anything else | The deepest operation: section 14 (`/private/var/folders`) |

The third level exists because section 14 requires a reboot afterwards or
multiple apps will misbehave. You will only ever encounter it if you
explicitly choose section 14 from the menu.

See [Safety Model — Confirmation Levels](safety-model.md#confirmation-levels)
for the full ladder.

---

## Step 5 — Find your reports

Whenever a section produces a list (orphan candidates, idle apps, large
files, stale builds, etc.), it writes a dated `.txt` report you can read
later in any editor.

```bash
ls -la ~/.mac-cleanup/reports/
```

Output looks like:

```
disk-usage-2026-05-10.txt
large-files-2026-05-10.txt
orphans-2026-05-10.txt
stale-build-2026-05-10.txt
unused-apps-2026-05-10.txt
```

Every file starts with a credits banner (tool name, version, author, repo,
npm URL, run timestamp, host) so each artefact is self-attributing — paste
one in a Slack channel and your colleague knows what generated it. See
[Reports & Logs](reports-and-logs.md) for the full layout.

---

## Step 6 — Schedule it (optional)

Once you trust the tool, the unattended invocation is one line:

```bash
npx macleanup --all --yes --quiet --notify
```

Wire that into `cron`, `launchd`, or a weekly reminder. See [Examples
Cookbook — Unattended cron job](examples-cookbook.md#unattended-cron-job).

---

## What to read next

- **[Installation](installation.md)** — for `npm install -g` or a direct
  git clone. Both have advantages over `npx`.
- **[CLI Reference](cli-reference.md)** — every flag, with examples.
- **[Sections (0–26)](sections.md)** — what each section actually does, what
  paths it touches, and which flags tune it.
- **[Safety Model](safety-model.md)** — the rules the script holds itself
  to. Read this before you run section 14 or section 21.
- **[Examples Cookbook](examples-cookbook.md)** — copy-paste recipes for
  common goals.

---

## Get help

Three flags help you reach the author or report issues, all local-first
(nothing is auto-sent — you review every prefilled message before clicking
Submit):

```bash
mac-cleanup --contact         # show the author contact card
mac-cleanup --feedback        # open mail client with prefilled message
mac-cleanup --report-issue    # open a pre-filled GitHub issue
mac-cleanup --stats           # show your run history at ~/.mac-cleanup
```

For more, see the [Author & Credits](author.md) page and the
[FAQ](faq.md).

---

_Built and maintained by **[Ahsan Mahmood](author.md)**._
