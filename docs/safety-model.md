# Safety Model

> The rules `mac-cleanup` holds itself to. Read this before you run
> section 14, before you wire it into cron with `--yes`, or before you
> point it at a fleet of machines.

`mac-cleanup` is **safe by default** — but it is also a tool that runs
`rm -rf` and `sudo`, and ultimately you are responsible for verifying its
outputs on your machine. This page documents the design rules so you can
trust them, audit them, and (where they can be loosened with flags)
loosen them deliberately.

---

## Design principles

The whole tool is built around five rules. Everything else is detail.

### 1. Destructive operations always confirm by default

Every operation that removes data prompts before running. The only way
to skip prompts is `--yes`, and even then the most dangerous prompts
have additional gates (literal `yes`, sudo, or "always interactive
regardless of `--yes`").

### 2. `--dry-run` never deletes anything

Every destructive call routes through one of these helpers:
`safe_rm_rf`, `safe_rm_f`, `clean_dir_contents`, `clean_dir_old`,
`clean_dir_unused`, `osascript_trash`, `sudo_run`. Each helper checks
`DRY_RUN` and returns immediately with a `[dry-run]` print instead of
executing. No exceptions.

### 3. Apps are moved to Trash, not `rm`-ed

Section 21 (uninstall idle apps) and section 24 (large stale files) move
selected items to **the macOS Trash via Finder AppleScript**
(`osascript_trash`), not `rm -rf`. You can recover until you empty the
Trash. Falls back to `rm -rf` only if AppleScript fails.

### 4. System caches need explicit `sudo`

If `sudo` isn't available — either because you don't have admin rights
or because you passed `--no-sudo` — the section is **skipped entirely**,
never silently bypassed. You'll see an explicit log line.

### 5. The deepest sections are never auto-run

These five operations are **never** part of `--all`, even with `--yes`:

- Section 14 — `/private/var/folders` wipe (requires literal `yes`)
- Section 21 — App uninstall (per-item or bulk, both interactive)
- Section 16 — iOS backup deletion (per-item interactive)
- Section 17 — Xcode archive deletion (per-item interactive)
- Section 10 — Empty Trash (one explicit confirmation)

You must explicitly **select them from the menu** or pass them via
`--only`/`--profile` plus `--yes`.

---

## The two-condition rule for non-cache deletes (4.3.3+)

**Anything that isn't pure regenerable cache** — orphan app data, idle
apps, stale `node_modules`, large unused files, iOS backups, Xcode
archives — will only be **deleted automatically** when **both**
conditions hold:

1. **Not used by any active software / tool.**
   - For orphan data (sec 12): no installed-app match
   - For LaunchAgents (sec 25): broken target binary
   - For idle apps (sec 21): no last-used signal in 100 days
2. **Not touched by you (atime AND mtime) for ≥ 100 days.**
   - Configurable via [`--idle-days N`](cli-reference.md#--idle-days-n)
   - A Gradle distribution you invoke once a month keeps recent atime,
     so it survives
   - A `node_modules` whose IDE reads files for autocomplete keeps recent
     atime, so it survives

`--idle-days 0` disables the second condition entirely (back to the
4.3.2 behaviour where mtime alone was enough). Use only if you really
want the heuristic to be the only gate.

> **Why two conditions?** Heuristics fail. The script can't always
> reliably know whether a `~/Library/Application Support/Foo` belongs to
> an installed app or an uninstalled one. Without the idle gate, a single
> false-positive could nuke your active project's `~/Library/Application
> Support/MyApp/UserData`. With the idle gate, even if the heuristic
> false-positives, anything you've used in the last 100 days survives.

### Cache age, by `atime` AND `mtime`

The cache-pruning sections (1, 2, 3) use the same atime+mtime rule, with
its own knob: [`--cache-age-days N`](cli-reference.md#--cache-age-days-n).

- Default 100. Files where **both** atime AND mtime are ≥ 100 days are
  pruned.
- A Gradle distribution downloaded 6 months ago but invoked last week
  keeps recent atime → survives.
- `--cache-age-days 0` disables the filter (full wipe — old `<4.3.2`
  behaviour).

---

## `CRITICAL_HOME_DIRS` — the section 23 allowlist

Section 23 (stale build artefacts) is the most destructive non-app
section. Its safety contract is the `CRITICAL_HOME_DIRS` allowlist:
toolchain managers, language runtimes, IDE state, secrets stores, and
OS-level caches that **must never be entered or deleted** regardless of
basename matches in `STALE_BUILD_PATTERNS`.

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

The protection is enforced **twice** as belt-and-braces:

1. **Find-time exclusion** — the `find` command building the candidate
   list excludes these paths via `! -path` predicates.
2. **Post-filter check** — `is_in_critical_home_dir()` is called on
   every candidate before deletion as a final gate.

Section 23 also **refuses to scan all of `$HOME`**. If none of the
common dev folders (`~/Projects`, `~/Code`, `~/Developer`, `~/dev`,
`~/repos`, `~/work`, `~/Documents`, `~/Desktop`, `~/Downloads`) exist
**and** no `--scan-roots` is supplied, it errors out and asks you to
pass `--scan-roots`. This prevents the 4.3.0 silent fallback that caused
the toolchain incident — see [Recovery Guide](recovery-guide.md).

---

## Confirmation levels

Three levels of prompt, escalating by risk:

| Level | Prompt | Default | Used by |
|---|---|---|---|
| **Standard** | `Continue? [y/N]` | No | Most destructive operations |
| **Per-item** | `[y/N/q]` per item (review, skip, quit) | No | Sections 12, 16, 17, 21, 25 |
| **Critical** | Type literal `yes` to continue | Aborts | Section 14 only |

The third level exists because section 14 (`/private/var/folders`)
requires a reboot afterwards or many running apps will misbehave. It's
the only section with that gate.

`--yes` flips the **Standard** level to default-Yes. It does **not**
bypass the **Critical** level. It does flip Per-item to auto-select-all
in sections 21, 23, 24 — be aware.

---

## Sudo handling

Sections needing sudo: 6, 7 (system portion), 9 (system portion), 11,
13, 14, 20, 25 (system items only).

The script handles sudo as follows:

1. **Cache check first.** `sudo -n true` runs silently. If credentials
   are cached (you ran sudo recently), no password prompt.
2. **Prompt only if needed.** If credentials are stale, you'll see the
   normal `Password:` prompt.
3. **`--no-sudo` skips the whole section.** No silent fallback to a
   non-sudo variant. The section is logged as skipped.
4. **Batch without `--yes` skips sudo too.** This is the safe default —
   if you're running `--all` on a machine where you're not present to
   type a password, sudo sections get skipped, not stuck.

Set `--no-sudo` explicitly when you know you're not admin, to avoid the
prompt cycle.

---

## Dry-run guarantees

Every destructive helper checks `DRY_RUN` before doing anything. The
helpers are:

| Helper | What it does | Dry-run behaviour |
|---|---|---|
| `safe_rm_rf "path"` | `rm -rf` with root-path refusal | Prints `[dry-run] rm -rf <path>` |
| `safe_rm_f "path"` | `rm -f` for a single file | Prints `[dry-run] rm -f <path>` |
| `clean_dir_contents "path"` | Wipes a dir's contents | Prints `[dry-run] would clear <path>` |
| `clean_dir_old "path" days [glob…]` | Deletes files older than N days | Prints `[dry-run] would prune…` |
| `clean_dir_unused "path" days` | atime+mtime gated prune | Prints `[dry-run] would prune…` |
| `sudo_run cmd …` | Wraps a sudo command | Prints `[dry-run] sudo cmd …` |
| `osascript_trash "path"` | Move to Trash via Finder | Prints `[dry-run] would Trash <path>` |

In addition, sections that produce reports (12, 21, 23, 24, 25) write
the **report file** even in dry-run — so you can study the candidate
list before committing.

---

## What the tool does not do

For symmetry — these are explicit non-features:

- **No telemetry, no phone-home.** The script makes zero network calls
  by default. The opt-in `--check-update` is the only network call, and
  it sends no user data.
- **No automatic crash submission.** If the script errors, it prints a
  hint pointing at `--report-issue`. You decide whether to share.
- **No silent destruction.** Every destructive operation logs what it
  did (or would do) and asks for confirmation unless explicitly told not
  to via flags.
- **No ad-hoc sweeps of `$HOME`.** Section 23 refuses; sections 12, 16,
  17, 21, 25 enumerate specific known paths.
- **No `chown`/`chmod`/permission changes.** Doesn't touch ownership.
- **No background mode / daemon.** It's a one-shot CLI. Wire to cron /
  launchd if you want recurring runs.

---

## What you remain responsible for

- **Have a backup before any cleanup tool.** A pinned Time Machine
  snapshot or `sudo tmutil snapshot` is a good last line of defence.
- **Read the dry-run before the live run** — at least the first time on
  any new machine.
- **Don't use `--all --yes` blindly.** It is appropriate for known,
  trusted profiles like `--profile minimal --yes --quiet --notify` in a
  cron job. It is not appropriate for "I just installed mac-cleanup."
- **Don't run section 14 without intending to reboot.**
- **Don't run section 21 with `--yes` on a production machine** without
  reviewing the report first.

---

## Recovery if something does go wrong

`mac-cleanup` had one known incident in its history: **v4.3.0 with the
silent `$HOME` fallback in section 23 could remove `node_modules`-shaped
folders inside toolchain manager directories** (`~/.bun`, `~/.pnpm-store`,
`~/.local/share/pnpm`, `~/.npm-packages`, `~/.volta`), breaking globally
installed tools.

This was fixed in 4.3.1 with the `CRITICAL_HOME_DIRS` allowlist and the
removal of the silent $HOME fallback. If you're running anything older
than 4.3.1 in section 23, **upgrade now**:

```bash
npx macleanup@latest --version
```

If you ran 4.3.0 against `--scan-roots $HOME` (or the silent fallback)
and a global tool stopped working, see [Recovery Guide](recovery-guide.md)
for one-line restore commands for `bun`, `pnpm`, `yarn`, `nvm`, `Volta`,
`asdf`, `Deno`, `rbenv`, `pyenv`, `rustup`, and global npm packages.

---

## See also

- [CLI Reference](cli-reference.md) — every flag including the safety knobs
- [Sections (0–26)](sections.md) — per-section safety notes
- [Recovery Guide](recovery-guide.md) — if a 4.3.0 run broke a global tool
- [SECURITY.md](../SECURITY.md) — vulnerability reporting

---

_Safety model for **mac-cleanup** v4.4.1 by **[Ahsan Mahmood](author.md)**._
