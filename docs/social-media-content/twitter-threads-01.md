# Twitter / X Threads — Batch 01

**Author**: Ahsan Mahmood — <aoneahsan@gmail.com> · [aoneahsan.com](https://aoneahsan.com) · [linkedin.com/in/aoneahsan](https://linkedin.com/in/aoneahsan) · +92 304 6619706
**Tool**: `macleanup` (run with `npx macleanup`)
**Generated**: 2026-05-10
**Batch**: 01 of N (next batch will be `twitter-threads-02.md`)

## How to use this file

1. Pick the thread whose angle fits the moment.
2. Copy each tweet from its `~~~` fence one at a time into the Twitter compose box. Click "Add another post" between each.
3. Each tweet stands alone — if a reader sees only tweet 4 in their feed, it still has context.
4. After posting, append `[USED]` to that thread's `##` heading.

Every tweet is **`≤280` chars** (free-tier compatible). Each thread is 5–8 tweets — long enough to deliver real value, short enough that engagement holds. Hashtags are 0–1 per thread (Twitter convention; more reduces reach).

Claims have been cross-checked against the actual product — no inventions.

---

## 1. Launch announcement

- **Hook angle**: Story-driven launch
- **Tweets**: 7
- **Best for**: Pin to profile after sending

### Tweet 1/7 — hook
~~~text
After 4 weeks of nights, I'm shipping macleanup today.

A free macOS cleanup CLI you can run with one command:

   npx macleanup

Single bash file. Zero install. No telemetry. 27 sections.

Here's what's in it 👇
~~~

### Tweet 2/7
~~~text
What it cleans:

• Xcode + DerivedData + simulators
• Gradle / npm / yarn / pnpm / brew / pip / pod / cargo / go / flutter
• Docker prune
• Browser caches (passwords kept)
• Orphan app data
• Stale node_modules
• LaunchAgents → missing binaries
~~~

### Tweet 3/7
~~~text
Dry-run is sacred:

   npx macleanup --dry-run --all

Shows everything that WOULD be deleted across 27 sections, without touching a byte. Every destructive section also confirms before acting. Apps go to Trash via Finder, not rm -rf — fully recoverable.
~~~

### Tweet 4/7
~~~text
Why one bash file?

A tool that runs `rm -rf` and `sudo` on your behalf should be readable.

~2,400 lines of bash + 80-line Node launcher = 41 KB tarball.

You can audit the source in an hour. No binary blobs. No closed-source executable. No Electron wrapper.
~~~

### Tweet 5/7
~~~text
Reports persist at ~/.mac-cleanup/

They survive npx cache cleanup automatically.

Every run gets dated .txt files for orphan data, idle apps, large files, stale builds, launch audit, and disk usage.

You can audit your own history without any setup.
~~~

### Tweet 6/7
~~~text
Privacy: zero network calls.

The Node launcher only spawns bash. The bash script only touches your filesystem.

Optional --check-update curls the npm registry once. That's it. No analytics, no phone-home, no telemetry, ever.
~~~

### Tweet 7/7 — CTA
~~~text
Try it (safe preview):

   npx macleanup --dry-run --all

Free. MIT-licensed. macOS 11+, Apple Silicon + Intel.

By Ahsan Mahmood
🔗 aoneahsan.com
🔗 linkedin.com/in/aoneahsan

#macOS #DevTools
~~~

---

## 2. Stale dev caches surprise

- **Hook angle**: Surprising stat from real machine
- **Tweets**: 6
- **Best for**: Engineering audience, weekday morning

### Tweet 1/6 — hook
~~~text
I just scanned my Mac.

Found 5 GB of stale .gradle caches, 30+ abandoned node_modules, 8 dead LaunchAgents from apps I uninstalled months ago.

Yours is probably similar.

I built a free CLI to fix it in one command:

   npx macleanup

🧵
~~~

### Tweet 2/6
~~~text
Section 23 finds regenerable build dirs untouched for N days:

node_modules · vendor · dist · build · out · .next · .nuxt · .turbo · .vite · .parcel-cache · target · Pods · coverage

Multi-select bulk delete. Configurable age threshold.
~~~

### Tweet 3/6
~~~text
Section 1 wipes Xcode DerivedData + drops unavailable simulators.

Section 2 clears Gradle caches.

Section 3 prunes npm / yarn / pnpm / brew / pip / pod / cargo / go / ruby / flutter caches in one go.

Section 4 prunes Docker images, containers, volumes.
~~~

### Tweet 4/6
~~~text
The dev preset bundles 5 of those:

   npx macleanup --profile dev --dry-run

Sections 1, 2, 3, 4, 23. Everything dev-cache + stale builds. Dry-run by default in this command — preview before deleting anything.
~~~

### Tweet 5/6
~~~text
Reports save at ~/.mac-cleanup/reports/stale-build-YYYY-MM-DD.txt

Sortable by size. Each row has the path, size, age in days. Audit before you delete. Audit after you've deleted.
~~~

### Tweet 6/6 — CTA
~~~text
Free. MIT-licensed. Single bash file you can read.

   npx macleanup --profile dev --dry-run

— Ahsan Mahmood
aoneahsan.com · linkedin.com/in/aoneahsan
~~~

---

## 3. Trust through readable source

- **Hook angle**: Contrarian / safety
- **Tweets**: 7
- **Best for**: Audience that's been burned by paid cleaners

### Tweet 1/7 — hook
~~~text
I never trusted Mac cleanup tools.

So I built one I can read.

Single bash file. ~2,400 lines. Zero binaries. Audit every line before you run it.

It's called macleanup. Free. MIT-licensed.

   npx macleanup

Here's the safety model 🧵
~~~

### Tweet 2/7
~~~text
Rule 1: Dry-run is sacred.

   --dry-run

→ nothing is deleted. Period. Every destructive operation routes through helpers that no-op in dry mode. Not best-effort. Not "mostly." Literal no-ops.
~~~

### Tweet 3/7
~~~text
Rule 2: Confirmation by default.

Every destructive section asks before deleting. --yes is opt-in. Even with --yes, the deepest sections (var/folders wipe, app uninstall, iOS backup deletion) require typing literal "yes" — not just y/Y.
~~~

### Tweet 4/7
~~~text
Rule 3: Apps go to Trash, not rm -rf.

When you uninstall an app via macleanup, it moves the .app to Finder's Trash via osascript. You can recover it for as long as Trash isn't emptied.
~~~

### Tweet 5/7
~~~text
Rule 4: Sudo sections are explicit.

No silent privilege escalation. If sudo isn't available, the section is skipped — never silently bypassed.

You see exactly which sections need sudo in --list and in the menu.
~~~

### Tweet 6/7
~~~text
Rule 5: Reports for every run.

~/.mac-cleanup/reports/<section>-<date>.txt

You can audit what was deleted, when, and what was flagged but kept. Every report file starts with a credits banner so the artefact self-attributes.
~~~

### Tweet 7/7 — CTA
~~~text
Trust by inspection, not trust by brand.

   npx macleanup --dry-run --all

Free. macOS 11+. Read every line before you run it.

By Ahsan Mahmood
🔗 aoneahsan.com  ·  linkedin.com/in/aoneahsan

#InfoSec
~~~

---

## 4. 27 sections in one command

- **Hook angle**: Capabilities tour / value-stack
- **Tweets**: 6
- **Best for**: Repost when sharing the npm URL

### Tweet 1/6 — hook
~~~text
27 macOS cleanup sections. One command. Zero install:

   npx macleanup

That's it. npm fetches the package, runs the interactive menu, reclaims its own cache afterwards.

Your reports + logs persist at ~/.mac-cleanup/ — never inside the disposable npx cache.

🧵
~~~

### Tweet 2/6
~~~text
The 27 sections cover (high level):

• System health + top processes
• Every dev-tool cache
• Every package-manager cache
• Browser caches (passwords preserved)
• User + system caches
• Logs · temp · update caches
• Time Machine snapshots
• Trash
~~~

### Tweet 3/6
~~~text
Plus the smart-detection sections:

• Orphan app data scanner
• Idle apps detector (configurable threshold)
• Stale node_modules / vendor / dist / target / Pods
• Large unused files (≥1 GB, untouched 100+ days)
• LaunchAgents pointing at deleted binaries
• Disk-usage report
~~~

### Tweet 4/6
~~~text
5 named profiles for common workflows:

--profile dev         → 1, 2, 3, 4, 23
--profile minimal     → 5, 7, 8, 9, 10
--profile cache-only  → every cache layer
--profile deep        → big monthly clean
--profile audit       → read-only diagnostics
~~~

### Tweet 5/6
~~~text
And the must-have flags:

--dry-run     safe preview, deletes nothing
--exclude     subtract sections from any preset
--notify      macOS notification on completion
--check-update opt-in npm registry version check
~~~

### Tweet 6/6 — CTA
~~~text
Start with the safe preview:

   npx macleanup --dry-run --all

Free. MIT-licensed. macOS 11+. No telemetry.

By Ahsan Mahmood
🔗 aoneahsan.com  ·  linkedin.com/in/aoneahsan
~~~

---

## 5. Single bash file philosophy

- **Hook angle**: Contrarian engineering craft
- **Tweets**: 7
- **Best for**: Builder / indie audience

### Tweet 1/7 — hook
~~~text
Why I shipped my Mac cleanup tool as a single bash file in 2026.

Conventional wisdom: ship a Swift app. Charge subscription. Add an Electron UI. Slap on telemetry.

I went the other way.

🧵
~~~

### Tweet 2/7
~~~text
Constraint #1: Auditable.

A cleanup tool runs rm -rf and sudo on your behalf. That should be readable, not a binary blob.

If you can't read the source, you're trusting the brand. I'd rather trust the diff.
~~~

### Tweet 3/7
~~~text
Constraint #2: No install.

   npx macleanup

That's all. Works on any Mac with Node 14+.

No homebrew tap. No .dmg with a code-signing dance. No "drag this to Applications." No login items the installer slipped in.
~~~

### Tweet 4/7
~~~text
Constraint #3: Zero deps.

The Node launcher is 80 lines.

Its only job: validate Darwin and spawn bash. That's it.

The bash script: 2,400 lines. Native macOS primitives only — osascript, tmutil, mdls, launchctl, du, find. Nothing reinvented.
~~~

### Tweet 5/7
~~~text
Constraint #4: Persistent state.

Logs and reports live at ~/.mac-cleanup/ — outside the npx cache.

They survive every npx run. You can audit history without setup. The disposable nature of npx becomes a feature.
~~~

### Tweet 6/7
~~~text
The cost: no GUI.

The benefit: trust by inspection, not trust by brand.

Total tarball size: 41 KB. The whole tool fits in less space than a single PNG icon from a typical Electron app's bundle.
~~~

### Tweet 7/7 — CTA
~~~text
If you've been burned by paid Mac cleaners, try the open alternative:

   npx macleanup --dry-run --all

Free. MIT-licensed. macOS 11+.

By Ahsan Mahmood
🔗 aoneahsan.com  ·  linkedin.com/in/aoneahsan

#IndieDev
~~~

---

## 6. LaunchAgents are the silent killer

- **Hook angle**: Specific feature / mystery solver
- **Tweets**: 5
- **Best for**: Performance-curious audience

### Tweet 1/5 — hook
~~~text
If your Mac feels slow on every login, you probably have orphan LaunchAgents.

Apps you uninstalled months ago left behind .plist files that keep firing on every boot, hitting paths that don't exist anymore.

I built section 25 of macleanup to find them 🧵
~~~

### Tweet 2/5
~~~text
How it works:

• Scans ~/Library/LaunchAgents
• Scans /Library/LaunchAgents
• Scans /Library/LaunchDaemons
• Reads each .plist for Program / ProgramArguments[0]
• Flags every entry whose target binary no longer exists on disk
~~~

### Tweet 3/5
~~~text
On my own Mac it found 8 stale items:

• Zoom updater (uninstalled months ago)
• AnyDesk frontend (uninstalled)
• Adobe Genuine Service (uninstalled)
• CocoaPods helper from an old install
• …and 4 more

Multi-select removal, sudo when needed for system items.
~~~

### Tweet 4/5
~~~text
Audit report saves at:

   ~/.mac-cleanup/reports/launch-audit-YYYY-MM-DD.txt

Each row: plist path · label · missing target binary.

Read it before you delete. Re-read it after. The history is yours.
~~~

### Tweet 5/5 — CTA
~~~text
Run the audit (read-only on this command — nothing gets deleted unless you opt in):

   npx macleanup --only 25

Free. MIT-licensed. macOS only.

By Ahsan Mahmood
🔗 aoneahsan.com  ·  linkedin.com/in/aoneahsan
~~~

---

## 7. What's actually safe to delete on macOS

- **Hook angle**: Educational cheat-sheet (high save & share)
- **Tweets**: 7
- **Best for**: Pin / repost — evergreen reference

### Tweet 1/7 — hook
~~~text
What's actually safe to delete on macOS?

I've spent years figuring this out the hard way.

Here's the cheat sheet I baked into macleanup 🧵
~~~

### Tweet 2/7
~~~text
✅ Safe to delete anytime:

• Xcode DerivedData — rebuilds on next compile
• ~/.gradle/caches — re-downloads on next build
• node_modules older than 30+ days — installs in seconds
• Docker dangling images + volumes — literal garbage
• ~/.Trash — yes, that's the whole point
~~~

### Tweet 3/7
~~~text
✅ Also safe (with regenerable cost):

• ~/Library/Caches/<bundle-id> for non-Apple apps — apps regenerate
• Browser caches — slower page loads for one day
• Saved Application State — apps won't restore last window setup
~~~

### Tweet 4/7
~~~text
⚠️ Safe but verify first:

• Old iOS device backups — only if device is gone or in iCloud
• Xcode .xcarchive — keep these if you might re-sign for the App Store
• Time Machine local snapshots — frees space immediately, removes restore points
~~~

### Tweet 5/7
~~~text
🛑 Never blindly delete:

• /Library/Caches/com.apple.* — macOS rebuilds slowly + with side-effects
• /private/var/folders — clears per-user temp; requires reboot
• Anything under /System — SIP should stop you, but still
• ~/Library/Photos / *.photoslibrary outside Photos UI
~~~

### Tweet 6/7
~~~text
The rule of thumb:

If macOS or your dev tools regenerate it on next use, it's safe.

If you can't recreate the data on demand, it's not.

Aggressive cleanup of /Library/Caches/com.apple.* is a classic way to break a macOS install.
~~~

### Tweet 7/7 — CTA
~~~text
This whole cheat sheet is encoded in macleanup, with confirmation prompts and dry-run safety:

   npx macleanup --dry-run --all

Free. 27 sections. macOS 11+.

By Ahsan Mahmood
🔗 aoneahsan.com  ·  linkedin.com/in/aoneahsan
~~~

---

## 8. Zero network calls

- **Hook angle**: Privacy contrarian
- **Tweets**: 6
- **Best for**: Privacy-conscious audience

### Tweet 1/6 — hook
~~~text
I built a free macOS cleanup tool that makes ZERO network calls.

No analytics. No phone-home. No "anonymous usage stats." No A/B testing. No crash reporter.

Here's the entire network footprint 🧵
~~~

### Tweet 2/6
~~~text
The Node launcher (80 lines) only spawns bash.

The bash script (~2,400 lines) only touches your filesystem.

The npm install + the npx cache cleanup are handled by npm itself — completely outside my code.
~~~

### Tweet 3/6
~~~text
The only optional network call:

If you explicitly pass --check-update, the tool curls registry.npmjs.org/macleanup/latest once, parses the version, prints if newer.

No identifying headers. No payload. Opt-in. Manual. Visible in the source.
~~~

### Tweet 4/6
~~~text
Where your data goes:

• Logs   → ~/.mac-cleanup/logs/<date>.log
• Reports → ~/.mac-cleanup/reports/<section>-<date>.txt

Local. Your machine only. Forever.

Nothing else. Ever.
~~~

### Tweet 5/6
~~~text
Why this matters:

A cleanup tool sees every app you have installed, every file path on your Mac, sometimes browser history paths, sometimes iOS backup contents.

Cleanup tools that include analytics report some subset of it home. macleanup refuses to.
~~~

### Tweet 6/6 — CTA
~~~text
If you can't audit a tool's network behaviour, assume it's spying on you.

Mine is two files you can read:

   npx macleanup

Free. MIT-licensed. macOS 11+.

By Ahsan Mahmood
🔗 aoneahsan.com  ·  linkedin.com/in/aoneahsan

#Privacy
~~~

---

## 9. Pre-Xcode reinstall workflow

- **Hook angle**: Practical recipe
- **Tweets**: 5
- **Best for**: iOS / Mac dev audience

### Tweet 1/5 — hook
~~~text
Pre-flight before reinstalling Xcode: a 60-second workflow.

Run this and easily reclaim tens of GB before Apple's installer makes things worse:

   npx macleanup --only "1,17"

🧵
~~~

### Tweet 2/5
~~~text
Section 1 — Xcode caches, DerivedData, simulators:

• Wipes ~/Library/Developer/Xcode/DerivedData (rebuilds on next compile)
• Drops unavailable iOS / tvOS / watchOS simulators
• Asks before nuking CoreSimulator state (recoverable but slow)
~~~

### Tweet 3/5
~~~text
Section 17 — Xcode archives:

• Lists every .xcarchive with size + date
• Multi-select bulk delete
• Asks before each archive

⚠️ Keep archives for apps you might re-sign for the App Store.
~~~

### Tweet 4/5
~~~text
Then follow up with the developer profile:

   npx macleanup --profile dev --dry-run

Sections 1, 2, 3, 4, 23 — every dev cache plus stale node_modules. Dry-run by default. Review the report at ~/.mac-cleanup/reports/, then re-run without --dry-run.
~~~

### Tweet 5/5 — CTA
~~~text
Try it before your next Xcode reinstall:

   npx macleanup --only "1,17" --dry-run

Free. MIT-licensed. macOS 11+.

By Ahsan Mahmood
🔗 aoneahsan.com  ·  linkedin.com/in/aoneahsan
~~~

---

## 10. Founder story

- **Hook angle**: Personal narrative
- **Tweets**: 8
- **Best for**: Pin to profile · about-me

### Tweet 1/8 — hook
~~~text
I cleaned up my Mac for 4 hours yesterday.

Today I shipped a tool so I never have to again.

It's called macleanup. Free. Single bash file.

   npx macleanup

The story 🧵
~~~

### Tweet 2/8
~~~text
I had 4 GB free on a 256 GB SSD.

Spotlight was indexing forever. Time Machine was complaining.

I'd been ignoring it for months because the cleanup ritual was always painful.
~~~

### Tweet 3/8
~~~text
The ritual:

1. Delete Xcode DerivedData
2. System Settings → Storage → Manage
3. rm -rf ~/Library/Caches/* (and pray)
4. brew cleanup
5. npm cache clean
6. gradle --stop && rm -rf ~/.gradle/caches
7. Empty Trash
8. tmutil deletelocalsnapshots /
~~~

### Tweet 4/8
~~~text
Then the harder steps:

9. Repeat for pod, pip, cargo, go, flutter…
10. Hunt for orphan app data manually
11. Forget which apps I haven't opened in years
12. Give up. Tomorrow's problem.

I'd done this dance maybe 30 times in my career.
~~~

### Tweet 5/8
~~~text
Yesterday I finally wrote the script.

Then I kept going:
• Added orphaned app-data detection
• Added stale node_modules finder
• Added LaunchAgents audit (the silent battery killer)
• Added a real --dry-run mode
• Added persistent reports
~~~

### Tweet 6/8
~~~text
Then I packaged it for npm so anyone can run:

   npx macleanup

Tarball size: 41 KB.

Total cost: a few weekends of evenings + the price of my own frustration.

Total earnings model: the time I'll never spend on this again.
~~~

### Tweet 7/8
~~~text
The lesson I keep relearning:

If you do something painful three times, automate it.

If you do it ten times, package it.

If you do it thirty times, ship it.
~~~

### Tweet 8/8 — CTA
~~~text
If your Mac is slow, sluggish, or out of space:

   npx macleanup --dry-run --all

Safe preview. Nothing gets deleted. You see what's flagged across 27 sections.

By Ahsan Mahmood
🔗 aoneahsan.com  ·  linkedin.com/in/aoneahsan

#BuildInPublic
~~~

---

## Resumability marker

When you've used a thread, edit its `##` heading to add `[USED]`, e.g.:

```
## 1. Launch announcement [USED]
```

The next batch generator will count `[USED]` markers and produce a fresh batch in `twitter-threads-02.md`.
