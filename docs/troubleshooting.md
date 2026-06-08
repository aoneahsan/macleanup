# Troubleshooting

> Symptom → cause → fix. Reach for this when something didn't work as
> expected. For "why does it work this way?" questions, see [FAQ](faq.md).

If a fix below doesn't solve your issue, run `mac-cleanup --report-issue`
— it opens a pre-filled GitHub issue with environment info collected
locally (nothing is auto-sent until you click Submit on github.com).

---

## Install & invocation

### `npx: command not found`

**Cause:** Node isn't installed.

**Fix (pick one):**

- Install Node from [nodejs.org](https://nodejs.org) (npx ships with it).
- Or use the [direct git checkout](installation.md#method-3--direct-git-checkout-no-node-required)
  method — no Node required.

---

### `permission denied: ./mac-cleanup.sh`

**Cause:** The executable bit was lost (most often via a Windows-era zip
extraction or a `cp` between volumes).

**Fix:**

```bash
chmod +x mac-cleanup.sh
./mac-cleanup.sh
```

---

### `mac-cleanup: this tool only runs on macOS. Detected platform: linux`

**Cause:** You're running it on Linux or in a non-Darwin environment
(e.g. WSL, Docker container).

**Fix:** None — there is no Linux port. The script touches paths
specific to the macOS filesystem layout (`~/Library`,
`/private/var/folders`, APFS snapshots, `tmutil`, `xcrun`,
`dscacheutil`, `mDNSResponder`, `launchctl`, `osascript`, etc.) that
have no Linux equivalent.

---

### `mac-cleanup: bash 3.2+ required. Detected: 2.0.x`

**Cause:** You're invoking the script with an unusually old bash
interpreter.

**Fix:**

```bash
/bin/bash --version            # confirm the system bash is >=3.2
/bin/bash mac-cleanup.sh       # run via system bash explicitly
```

If `/bin/bash` is missing, you may have a customised macOS install — try
restoring `/bin/bash` from a known-good source.

---

### `command not found: mac-cleanup` after `npm install -g`

**Cause:** Your shell's PATH doesn't include the npm global bin
directory.

**Fix:**

```bash
npm config get prefix          # e.g. /usr/local
echo $PATH | tr ':' '\n'       # check if the prefix's bin is in PATH
```

Add to `~/.zshrc` or `~/.bash_profile`:

```bash
export PATH="$(npm config get prefix)/bin:$PATH"
```

Re-source: `source ~/.zshrc`. Then `which mac-cleanup` should resolve.

---

### `mac-cleanup: bundled script not found at …mac-cleanup.sh`

**Cause:** The npm package is corrupted or partially extracted.

**Fix:**

```bash
npm uninstall -g macleanup
npm cache clean --force
npm install -g macleanup
```

Or, with `npx`:

```bash
npx --yes macleanup --version
```

---

## Behaviour

### "It says 'no large stale files found' — but I have a 5 GB file!"

**Cause:** Section 24 requires **both** `atime` AND `mtime` to be older
than the threshold. If you opened the file recently (atime updated), it
won't be flagged.

**Fix:** Lower the threshold or use section 18 instead:

```bash
mac-cleanup --only 24 --large-file-days 30 --dry-run    # smaller window
mac-cleanup --only 18                                   # purely by size
```

See [Section 24 reference](sections.md#section-24--large-stale-files).

---

### Section 23 reports zero stale builds even though my old `node_modules` is there

**Cause #1:** Your IDE / language server is keeping the directory's atime
fresh (autocomplete reads files).

**Fix:**

```bash
mac-cleanup --only 23 --stale-build-days 30 --dry-run
```

**Cause #2:** The directory is inside one of the `CRITICAL_HOME_DIRS`
(e.g. `~/.bun/install/cache/foo/node_modules`). Section 23 will never
enter those.

**Fix:** Per-tool cleanup is the job of section 3. For toolchain
caches, run:

```bash
mac-cleanup --only 3
```

See [Safety Model — `CRITICAL_HOME_DIRS`](safety-model.md#critical_home_dirs--the-section-23-allowlist).

**Cause #3:** Your scan roots don't cover the directory.

**Fix:**

```bash
mac-cleanup --only 23 --scan-roots "$HOME/repos:$HOME/work:$HOME/code" --dry-run
```

---

### Section 21 missed an app I haven't used in years

**Cause:** None of the 5 last-used signal sources have a usable date.
The script under-flags by design (skips the app to avoid a false
positive).

Common reasons:

- **Spotlight is re-indexing** (recent macOS update or a manual
  `mdutil -E /` reset). Wait an hour, retry.
- The app was never opened (only installed) — there's no "last used"
  data anywhere.
- The app stores its state outside the standard locations.

**Fix:** None automatic. Manually drag the app to Trash, or wait for
Spotlight to finish indexing. See [Section 21 reference](sections.md#section-21--apps-unused-n-days).

---

### Section 23 errored: "no scan roots found, pass `--scan-roots`"

**Cause:** Section 23 refuses to scan all of `$HOME` silently (this was
the 4.3.0 bug). It auto-detects common dev folders (`~/Projects`,
`~/Code`, `~/Developer`, `~/dev`, `~/repos`, `~/work`, `~/Documents`,
`~/Desktop`, `~/Downloads`) — if none exist, it asks you to be explicit.

**Fix:**

```bash
mac-cleanup --only 23 --scan-roots "$HOME/path/to/your/code"
```

---

### Docker section says "Docker daemon not running"

**Cause:** Docker Desktop isn't started.

**Fix:** Start Docker Desktop, wait for the whale icon to be steady,
then re-run section 4. Or skip:

```bash
mac-cleanup --all --exclude 4 --yes
```

---

### `xcrun simctl delete unavailable failed`

**Cause:** Xcode is open or running a build, holding a lock on the
simulator runtime.

**Fix:** Quit Xcode entirely, then re-run section 1.

---

### Trash didn't actually empty after section 10

**Cause:** A file in Trash is locked, in use by a running app, or owned
by another user.

**Fix:**

```bash
# show what's still there
ls -la ~/.Trash/

# inspect locked files
ls -laO ~/.Trash/         # 'uchg' flag = user immutable

# unlock and try again
chflags -R nouchg ~/.Trash/
mac-cleanup --only 10
```

---

### Time Machine snapshots deleted but free disk didn't change

**Cause:** This is normal — APFS reclaims snapshot space lazily, only
when the disk needs more space.

**Fix:** Either trigger purgeable space reclaim:

```bash
mac-cleanup --only 22
```

Or just wait — the next time disk pressure hits, the space appears.

---

### `osascript` keeps prompting for Automation permissions

**Cause:** macOS requires explicit user permission for one app to
control another (Finder, in this case, for the move-to-Trash and the
notification banner).

**Fix:**

1. Open **System Settings → Privacy & Security → Automation**.
2. Find the app that's running mac-cleanup (Terminal, iTerm, Warp, etc.).
3. Allow it to control **Finder** and **System Events**.

If you don't want to grant the permission:

```bash
mac-cleanup --all --yes               # skip the --notify flag
# section 21 will fall back to rm -rf instead of osascript_trash
```

---

## Logs & reports

### `~/.mac-cleanup/` doesn't exist

**Cause:** No section that writes a report or log has run yet (you may
have only used `--list`, `--version`, etc.).

**Fix:** Run any section. The directory is created on first write:

```bash
mac-cleanup --only 0      # health check creates the log
```

---

### Reports stopped being written

**Cause:** You may have passed `--no-reports`, or set
`MAC_CLEANUP_REPORTS_DIR` to a path you don't have write permission for.

**Fix:**

```bash
echo "$MAC_CLEANUP_REPORTS_DIR"        # check env var
mac-cleanup --reports-dir ~/.mac-cleanup/reports --only 23 --dry-run
ls -la ~/.mac-cleanup/reports/
```

---

### Logs are filling up disk

**Cause:** One log file per day, kept forever by default. ~50 KB each is
free in practice, but if you've run for years you may have hundreds.

**Fix:**

```bash
# manual cleanup of old logs
find ~/.mac-cleanup/logs -name '*.log' -mtime +90 -delete

# or per-run automatic cleanup
mac-cleanup --cleanup-logs-on-finish

# or wipe everything mac-cleanup left behind
rm -rf ~/.mac-cleanup/
```

---

## Performance

### "Section 18 / 24 takes forever"

**Cause:** Both scan all of `$HOME`, which can be slow on large home
directories.

**Fix:**

- **Section 18** is read-only — let it run; ~1 minute on most machines.
- **Section 24** can be tightened:

  ```bash
  mac-cleanup --only 24 --large-file-size-gb 5 --large-file-days 365 --dry-run
  ```

  Larger size + older age threshold = fewer candidates = faster scan.

---

### "Section 23 takes forever"

**Cause:** A scan root contains many small projects (many `node_modules`
to enumerate).

**Fix:** Restrict scan roots:

```bash
mac-cleanup --only 23 --scan-roots "$HOME/active-projects" --dry-run
```

---

## Update / version issues

### `--check-update` says "registry returned no version field"

**Cause:** Network failure (4-second connect timeout, 6-second total),
or the npm registry is briefly unreachable.

**Fix:** Retry. If persistent, check connectivity to
`https://registry.npmjs.org/`. If you're on a corporate proxy, you may
need to configure npm — but `--check-update` is opt-in and harmless to
skip.

---

### After upgrade, old commands behave differently

**Cause:** Behavioural changes between versions. The biggest:

- **4.3.1**: `brew autoremove` became opt-in (`--brew-autoremove`).
- **4.3.2**: cache age threshold (`--cache-age-days`, default 100)
  introduced for sections 1, 2, 3.
- **4.3.3**: universal `--idle-days` (default 100) for non-cache deletes
  in sections 12, 23.
- **4.4.0**: `--feedback`, `--report-issue`, `--stats`, `--contact`
  added. Crash-hint footer added.

**Fix:** Read [CHANGELOG.md](../CHANGELOG.md) for the full history. To
restore old behaviour:

```bash
mac-cleanup --only 23 --idle-days 0 --cache-age-days 0    # disable both gates
mac-cleanup --only 3 --brew-autoremove                    # restore old brew behaviour
```

---

## Still stuck?

```bash
mac-cleanup --report-issue
```

Opens a pre-filled GitHub issue with environment info collected locally.
Nothing is auto-sent. The last 50 lines of your latest log are copied
to clipboard so you can paste them into the issue body.

For private security issues, email <aoneahsan@gmail.com>. See
[SECURITY.md](../SECURITY.md).

---

## See also

- [FAQ](faq.md) — "why does it work this way?"
- [Recovery Guide](recovery-guide.md) — if a 4.3.0 run broke a global tool
- [CLI Reference](cli-reference.md) — every flag in detail
- [Safety Model](safety-model.md) — the rules behind `--dry-run`, `--yes`, sudo

---

_Troubleshooting guide for **mac-cleanup** v4.5.0 by **[Ahsan Mahmood](author.md)**._
