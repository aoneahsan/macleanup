# Recovery Guide

> If a `4.3.0` run broke a globally installed tool, this page restores
> the most common ones in one command each. Then upgrade to **`4.4.1`**
> so it can't happen again.

---

## What happened in v4.3.0

`v4.3.0` had a bug where **section 23 (stale build artefacts)** could
enter toolchain manager directories like `~/.bun`, `~/.pnpm-store`,
`~/.local/share/pnpm`, `~/.npm-packages`, `~/.volta` and remove
`node_modules`-shaped folders inside them — breaking globally installed
tools like `pnpm`, `yarn`, `bun`, and many global npm packages.

There were two contributing factors:

1. **`.cache` was in `STALE_BUILD_PATTERNS`**, so any `.cache/` directory
   under a scan root was a candidate — including critical tool state.
2. **Silent `$HOME` fallback** — if no common dev folder existed and no
   `--scan-roots` was passed, section 23 quietly scanned all of `$HOME`,
   including `~/.bun`, `~/.pnpm-store`, etc.

In addition, `--all` runs of v4.3.0 invoked `brew autoremove`, which can
uninstall formulae originally installed as dependencies (e.g. `node`,
`python`, `openssl`) that the user actually needed.

---

## What changed in v4.3.1+

- **`CRITICAL_HOME_DIRS` allowlist** — section 23 will refuse to enter
  ~50 named toolchain/IDE/secrets/cache directories regardless of mtime
  or basename match. See [Safety Model — `CRITICAL_HOME_DIRS`](safety-model.md#critical_home_dirs--the-section-23-allowlist).
- **`.cache` removed from `STALE_BUILD_PATTERNS`** — per-tool cache
  cleaning is now strictly the job of section 3.
- **No silent `$HOME` fallback** — if no common dev folder is detected
  and no `--scan-roots` is supplied, section 23 errors out and asks you
  to pass one explicitly.
- **`brew autoremove` is opt-in** via `--brew-autoremove`. Off by
  default since 4.3.1.
- **The 4.3.3 two-condition rule** — non-cache deletes require BOTH
  heuristic (a) AND idle-threshold (b) to fire. See [Safety Model —
  The two-condition rule](safety-model.md#the-two-condition-rule-for-non-cache-deletes-433).

To upgrade:

```bash
npx macleanup@latest --version    # confirm 4.4.1 (or newer)
# or, for global installs:
npm install -g macleanup@latest
```

---

## Restoring tools that 4.3.0 may have broken

### bun

```bash
curl -fsSL https://bun.sh/install | bash
```

One-liner reinstall. Re-source your shell rc when it finishes.

### pnpm

```bash
corepack enable
corepack prepare pnpm@latest --activate
```

Corepack ships with Node 16+, no extra install needed. Then re-install
your global pnpm packages:

```bash
pnpm add -g typescript ts-node prettier eslint <other tools you had>
```

### yarn

```bash
corepack enable
corepack prepare yarn@stable --activate
```

Same path via Corepack.

### nvm + Node

If `~/.nvm` is intact, just re-source:

```bash
source "$HOME/.nvm/nvm.sh"
nvm use --lts        # or whichever version
```

If `~/.nvm` is gone, reinstall:

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
```

### Global npm packages

npm doesn't keep an authoritative list of "what was installed globally."
If you have a recent `npm-shrinkwrap`, re-install from it. Otherwise
list manually:

```bash
npm install -g typescript prettier serve <whatever you had>
```

### Volta

```bash
curl https://get.volta.sh | bash
```

### asdf

```bash
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0
```

Or via the official installer:

```bash
brew install asdf      # if you use Homebrew
```

### fnm

```bash
curl -fsSL https://fnm.vercel.app/install | bash
```

### Deno

```bash
curl -fsSL https://deno.land/install.sh | sh
```

### rbenv / pyenv / rustup

Re-run their installers — none of them keep state outside their own
directory:

```bash
# rbenv
brew install rbenv ruby-build

# pyenv
brew install pyenv

# rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

---

## Restoring brew formulae that `brew autoremove` removed

If a brew-installed formula was uninstalled by 4.3.0's auto `brew
autoremove` (this happened if you ran 4.3.0 in `--all` mode and one of
your tools' dependencies was treated as "no longer needed"), you can see
recently uninstalled formulae:

```bash
brew log
```

Re-install the ones you still want:

```bash
brew install node python openssl <whatever>
```

`brew autoremove` is **no longer in the default flow** as of 4.3.1 — it
must be explicitly opted into via `--brew-autoremove`. See [CLI Reference
— `--brew-autoremove`](cli-reference.md#--brew-autoremove).

---

## Going forward — preventing a repeat

Once you've upgraded to **4.4.1** (or any 4.3.1+), the safety changes
above are automatic. You can also adopt these habits:

### Always `--dry-run` first

```bash
mac-cleanup --only 23 --dry-run
mac-cleanup --profile dev --dry-run
```

Even with the safety changes, `--dry-run` is the easiest sanity check —
you see exactly what would be touched.

### Use `--scan-roots` explicitly

Even though section 23 now refuses to scan `$HOME` silently, being
explicit is clearer:

```bash
mac-cleanup --only 23 --scan-roots "$HOME/repos:$HOME/work:$HOME/code"
```

### Never combine `--all --yes` with sections you haven't reviewed

`--all --yes` is right for trusted profiles like `--profile minimal --yes`.
It's wrong for "let me just run the whole thing on a new machine."

### Check that you're on the latest version

```bash
mac-cleanup --check-update
```

Single-line opt-in advisory, no telemetry sent. See [CLI Reference —
`--check-update`](cli-reference.md#--check-update).

---

## If something else broke

If a tool isn't on the list above and you suspect 4.3.0 affected it:

1. Check `~/.mac-cleanup/logs/mac-cleanup-2026-*.log` for any line
   mentioning the tool's directory.
2. Check the section 23 stale-build report from that day:
   `~/.mac-cleanup/reports/stale-build-YYYY-MM-DD.txt`
3. The tool's own re-install instructions (curl one-liner, brew formula,
   etc.) should restore it cleanly. **None of these tools store
   irreplaceable user state in their `~/.tool-name/node_modules`** —
   re-installing rebuilds it.

If you find a path that should be in `CRITICAL_HOME_DIRS` but isn't,
open an issue:

```bash
mac-cleanup --report-issue
```

---

## Filing a bug for a different incident

If a current 4.3.1+ release deleted something you didn't expect, that's
a bug — please report it:

```bash
mac-cleanup --report-issue
```

The pre-filled GitHub issue includes your environment info (collected
locally — nothing is auto-sent). It also copies the last 50 lines of
your most recent log to clipboard so you can paste them in.

For private security disclosures, see [SECURITY.md](../SECURITY.md).

---

## See also

- [Safety Model](safety-model.md) — the rules in detail
- [Section 23 reference](sections.md#section-23--stale-build-artefacts) — the safety-hardened section that caused this
- [CHANGELOG.md](../CHANGELOG.md) — the full history of what changed and when

---

_Recovery guide for **mac-cleanup** v4.4.1 by **[Ahsan Mahmood](author.md)**._
