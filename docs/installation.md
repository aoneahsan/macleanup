# Installation

> Three ways to install **mac-cleanup**. Pick the one that fits your workflow.

`mac-cleanup` is published as the npm package
[`macleanup`](https://www.npmjs.com/package/macleanup) and as the GitHub
repository [`aoneahsan/macleanup`](https://github.com/aoneahsan/macleanup).
You can run it three ways: **zero-install via `npx`**, **global via
`npm`**, or **directly from a git clone** (no Node required).

| Method | Best for | Needs Node? | Persists between runs? |
|---|---|:-:|:-:|
| `npx macleanup` | One-off cleanups, trying it out | yes (>=14) | reports + logs only |
| `npm install -g macleanup` | Regular use, scripts, cron | yes (>=14) | yes |
| `git clone …` + `./mac-cleanup.sh` | Reading the source, no Node available | no | yes |

All three invocations accept identical flags — see
[CLI Reference](cli-reference.md). Pick whichever invocation fits your
workflow; this page covers each one in detail.

---

## Method 1 — Zero-install via `npx` (easiest)

```bash
npx macleanup
```

That's it. `npx` is bundled with `npm`, which ships with every Node
installation. The first run downloads the package into npm's cache (~few
hundred KB), the script runs, and the cache may be reclaimed afterwards.

```bash
# Preview the safe-batch cleanup without touching anything
npx macleanup --dry-run --all

# Run one specific section
npx macleanup --only 23 --stale-build-days 90 --dry-run

# Show every section, then exit
npx macleanup --list
```

### What `npx` actually does, step by step

1. `npx` resolves `macleanup` to the latest published version on the npm
   registry.
2. If the package isn't already in npm's cache, it downloads it.
3. It runs `bin/mac-cleanup.js` (a tiny Node launcher, ~80 lines) with
   any flags you passed.
4. The launcher checks you're on macOS, locates the bundled
   `mac-cleanup.sh` (~3,000 lines of bash), and `exec`s `bash` with your
   argv forwarded.
5. The bash script self-checks `bash >= 3.2` and runs.

**Your reports and logs are never inside the npx cache.** They live at
`~/.mac-cleanup/{logs,reports}/` and survive every `npx` invocation, every
npm cache cleanup, every macOS restart. See [Reports & Logs](reports-and-logs.md).

### Pinning a specific version with `npx`

```bash
npx macleanup@4.4.0          # pin a version
npx macleanup@latest         # always pull latest
```

Useful when you want to lock a CI/cron job to a known version.

### When `npx` is the wrong choice

- You're running `mac-cleanup` **multiple times a day** — the cache lookup
  and platform check add a small startup cost. Use the global install instead.
- You're on a machine with **no Node installed** and don't want to install
  Node. Use the [git clone](#method-3--direct-git-checkout-no-node-required)
  method.
- You're scripting it into **launchd / cron** — pin a version with
  `npx macleanup@4.4.0` or use the global install for stability.

---

## Method 2 — Global install via `npm`

```bash
npm install -g macleanup
```

After install, two binaries are available in your PATH:

```bash
mac-cleanup            # canonical name
macleanup              # short alias
mac-cleanup --version  # macleanup 4.4.0
```

Both commands are identical entry points to the same script.

### Updating later

```bash
npm install -g macleanup@latest
# or check first:
mac-cleanup --check-update
```

`--check-update` queries the public npm registry for the latest published
version (4-second connect timeout, never blocks the run). It sends **no
user data** — see [CLI Reference — `--check-update`](cli-reference.md#--check-update).

### Uninstalling

```bash
npm uninstall -g macleanup
```

This removes the binaries and the cached package. Your data at
`~/.mac-cleanup/` is **preserved** — delete it manually if you want to
remove logs and reports too:

```bash
rm -rf ~/.mac-cleanup/
```

### Note for users with package-manager preferences

If you prefer `pnpm` or `yarn` for global installs, both work:

```bash
pnpm add -g macleanup
yarn global add macleanup
```

The package has zero dependencies — installation is essentially copying
the bundled `mac-cleanup.sh` and `bin/mac-cleanup.js` into your global
node_modules.

---

## Method 3 — Direct git checkout (no Node required)

If you don't have Node, or you want to read the source before running it,
clone the repo and execute the script directly:

```bash
git clone https://github.com/aoneahsan/macleanup.git
cd macleanup
chmod +x mac-cleanup.sh
./mac-cleanup.sh
```

That's the entire installation. The `mac-cleanup.sh` file is **fully
self-contained** — no source dependencies, no other files needed at
runtime, no `npm install` step.

### Putting it on PATH

If you want to invoke `mac-cleanup` from anywhere, drop a symlink:

```bash
ln -s "$PWD/mac-cleanup.sh" ~/bin/mac-cleanup
# add ~/bin to PATH if it isn't already
```

Or use Cmd+`I` on the file in Finder, copy the full path, and add it to
your shell profile.

### Updating

```bash
cd macleanup
git pull
```

That's all. No build step, no dependencies to update.

### When direct checkout is the right choice

- **You want to read every line before running.** Open
  `mac-cleanup.sh` (~3,000 lines of plain bash) in any editor.
- **You want zero Node dependency.** A future Node breakage doesn't affect
  you — bash is a macOS system component.
- **You want to fork it for personal use.** The source-available license
  permits private use, including modifications you don't redistribute. See
  [LICENSE.md](../LICENSE.md).

---

## Verifying your install

Whichever method you used, the same three commands confirm everything is
wired correctly:

```bash
mac-cleanup --version          # macleanup 4.4.0
mac-cleanup --list             # prints all 27 sections
mac-cleanup --dry-run --all    # preview without touching disk
```

If `--version` says something other than `4.4.0`, your install is on a
different version — check [CHANGELOG.md](../CHANGELOG.md) for the
differences, or run `npm install -g macleanup@latest` to upgrade.

---

## Where things end up on disk

| Path | What lives there | When created |
|---|---|---|
| `~/.mac-cleanup/logs/mac-cleanup-YYYY-MM-DD.log` | One log per day, every action recorded | First run on any given day |
| `~/.mac-cleanup/reports/*.txt` | Per-section dated reports (orphans, large files, stale builds…) | When relevant sections run |
| `~/.mac-cleanup/.welcomed` | Marker — disables the one-time welcome screen | First run on any machine |

Everything is in one tidy place under `~/.mac-cleanup/`. To wipe it:

```bash
rm -rf ~/.mac-cleanup/
```

You can also override either path:

```bash
mac-cleanup --logs-dir /tmp/mc-logs --reports-dir /tmp/mc-reports
# or via env vars:
export MAC_CLEANUP_LOGS_DIR=/tmp/mc-logs
export MAC_CLEANUP_REPORTS_DIR=/tmp/mc-reports
```

See [Reports & Logs](reports-and-logs.md) for what each file contains.

---

## Troubleshooting installation

### `npx: command not found`

You don't have Node installed. Either:

1. **Install Node** via [nodejs.org](https://nodejs.org) — `npx` ships with it.
2. **Or use Method 3** (`git clone`) — no Node required.

### `permission denied: ./mac-cleanup.sh`

```bash
chmod +x mac-cleanup.sh
```

The git checkout sometimes loses the executable bit on Windows-era zips.
Setting `+x` once fixes it permanently for that file.

### `mac-cleanup: this tool only runs on macOS. Detected platform: linux`

The script and the Node launcher both check for Darwin. There's no Linux
port — `mac-cleanup` is intentionally macOS-only because it touches paths
specific to the macOS filesystem layout (`~/Library`, `/private/var/folders`,
APFS snapshots, `tmutil`, `xcrun`, `dscacheutil`, `mDNSResponder`,
`launchctl`, `osascript`, etc.).

### `mac-cleanup: bash 3.2+ required. Detected: 2.0.x`

You're invoking the script with an unusually old bash. macOS ships with
3.2 by default; if `bash --version` reports something older, your PATH may
be pointing at a stripped-down shell. Try `/bin/bash --version`.

### `command not found: mac-cleanup` after global install

```bash
npm config get prefix
# usually /usr/local or /opt/homebrew
echo $PATH | tr ':' '\n' | grep -i node
```

Make sure `$(npm config get prefix)/bin` is on your PATH. Add it to your
`~/.zshrc` or `~/.bash_profile`:

```bash
export PATH="$(npm config get prefix)/bin:$PATH"
```

### More install issues

See [Troubleshooting](troubleshooting.md) for symptom → cause → fix
mappings, or open an issue with `mac-cleanup --report-issue` (collects
environment info locally and opens a pre-filled GitHub issue — nothing is
auto-sent).

---

## What to read next

- **[Getting Started](getting-started.md)** — your first-run walkthrough.
- **[CLI Reference](cli-reference.md)** — every flag, with examples.
- **[Sections (0–26)](sections.md)** — what each section actually does.

---

_Maintained by **[Ahsan Mahmood](author.md)**._
