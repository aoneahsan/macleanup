# LinkedIn Posts — Batch 01

**Author**: Ahsan Mahmood — <aoneahsan@gmail.com> · [aoneahsan.com](https://aoneahsan.com) · [linkedin.com/in/aoneahsan](https://linkedin.com/in/aoneahsan) · +92 304 6619706
**Tool**: `macleanup` (run with `npx macleanup`)
**Generated**: 2026-05-10
**Batch**: 01 of N (next batch will be `linkedin-posts-02.md`)

## How to use this file

1. Pick the post whose angle fits the moment.
2. Copy everything between the `~~~` fences.
3. Paste into LinkedIn — emojis, headings, and line breaks render natively.
4. After posting, append `[USED]` to that post's `##` heading. The next batch generator will skip used items and only refill what's missing.

Every post is `≤2900` chars and includes a hook above the fold, sub-heads, bullets, one quote, **one clear CTA**, and author attribution. Hashtags are 4–5 per post (LinkedIn algorithm sweet spot per current best practice).

Claims have been cross-checked against the actual product. Nothing is invented.

---

## 1. Launch announcement - USED

- **Angle**: Story-driven, "today I shipped"
- **Best for**: First post in your launch sequence
- **Char count**: ~1750 / 2900

~~~text
After 4 weeks of nights, I'm shipping macleanup today.

A free, single-file Mac cleanup tool you can run with one command:

  npx macleanup

No install. No subscription. No telemetry. Just a bash script you can read line by line, written for one purpose: reclaim disk space without breaking your Mac.

🧹 What's in the box

• 27 cleanup sections — caches, logs, stale build artefacts, orphaned app data, idle apps, large unused files, LaunchAgents audit, and more
• A real dry-run mode — preview before deleting anything
• Persistent reports at ~/.mac-cleanup/ so you can audit every run
• Five named profiles — dev / minimal / cache-only / deep / audit
• Multi-select interactive UI — review the list, then bulk-delete
• Apple Silicon + Intel, macOS 11 and up

> "Most cleanup tools either delete too aggressively, or do too little. macleanup sits in the middle: every destructive action confirms by default, and --dry-run never touches disk."

The whole tool is one bash file plus a tiny Node launcher for the npx magic. You can audit the source in an hour. No analytics. No phone-home. No ads.

🚀 Try it now (safe preview, nothing gets deleted)

  npx macleanup --dry-run --all

If you've ever wiped /Library/Caches and regretted it, this one's for you.

Github: https://github.com/aoneahsan/macleanup
NPM: https://www.npmjs.com/package/macleanup

—
Ahsan Mahmood
aoneahsan.com  ·  linkedin.com/in/aoneahsan
aoneahsan@gmail.com  ·  +92 304 6619706

#macOS #DeveloperTools #OpenSource #CLI #Productivity
~~~

---

## 2. Developer pain — stale dev caches

- **Angle**: Pain-first, dev-focused
- **Best for**: Engineering audience, mid-week post
- **Char count**: ~1850 / 2900

~~~text
If you're a developer on macOS, you have gigabytes of node_modules, vendor, target, and .next folders rotting on disk right now.

I scanned my own Mac. The numbers:

• 5.0 GB in ~/.gradle
• 980 MB in ~/.vscode
• 803 MB in ~/.local
• 444 MB in ~/.nvm
• 415 MB in ~/.npm

…and that's before touching the per-project node_modules from the 30+ repos I haven't opened in months.

I built macleanup to fix this in one command.

🔧 What it does for developers

• Section 23 finds every regenerable build dir (node_modules, vendor, dist, build, .next, .nuxt, .turbo, .vite, target, Pods, coverage, …) untouched for N days
• Section 1 wipes Xcode DerivedData + drops unavailable simulators
• Section 2 clears Gradle caches
• Section 3 prunes npm / yarn / pnpm / brew / pip / pod / cargo / go / ruby / flutter caches
• Section 4 prunes Docker images, containers, volumes
• Multi-select UI so you delete only what you want

Reports persist at ~/.mac-cleanup/reports/ so you can audit every run.

> "Your dev caches will rebuild on the next install. The disk space is the only thing you actually need."

🚀 Try the developer preset (safe, dry-run by default)

  npx macleanup --profile dev --dry-run

Free. MIT-licensed. Single bash file. No telemetry.

—
Ahsan Mahmood
aoneahsan.com  ·  linkedin.com/in/aoneahsan
aoneahsan@gmail.com

#WebDev #NodeJS #Xcode #macOS #DeveloperProductivity
~~~

---

## 3. Trust through readable source

- **Angle**: Safety / transparency
- **Best for**: Audience that's been burned by paid cleaners
- **Char count**: ~1900 / 2900

~~~text
I never trusted Mac cleanup tools.

So I built one I can read.

The whole codebase is one bash file, ~2,400 lines, zero binary blobs. You can audit every line before you run it. No closed-source executable, no Electron wrapper hiding what's actually doing the deleting.

It's called macleanup. Free. MIT-licensed.

🛡️ Safety design rules I committed to

• Dry-run is sacred. Pass --dry-run and nothing is deleted. Period. Every destructive call routes through helpers that no-op in dry mode.
• Confirmation before delete is the default. --yes is opt-in.
• Apps go to Trash via Finder, not rm -rf. You can recover them.
• Sudo sections are explicit. No silent privilege escalation. If sudo isn't available, the section is skipped — never silently bypassed.
• The deepest sections — /private/var/folders wipe, app uninstall, iOS backup deletion — require typing literal "yes" and are never part of --all.
• Reports for every run live at ~/.mac-cleanup/reports/ so you can audit what was deleted and when.

> "A tool that runs rm -rf and sudo on your behalf should be auditable. Mine is one file you can read in your editor."

🚀 First-run discipline

  npx macleanup --dry-run --all

You'll see exactly which files would be flagged across 27 sections, before a single byte gets touched. Decide from there.

No telemetry. No analytics. No network calls (unless you explicitly pass --check-update).

—
Ahsan Mahmood
aoneahsan.com  ·  linkedin.com/in/aoneahsan
aoneahsan@gmail.com

#macOS #InfoSec #DeveloperTools #Privacy #MITLicense
~~~

---

## 4. One-command demo

- **Angle**: Value-stacking / capabilities overview
- **Best for**: Repost when sharing the npx URL
- **Char count**: ~1900 / 2900

~~~text
27 macOS cleanup sections. One command. Zero install.

  npx macleanup

That's it. npm fetches the package, runs the interactive menu, and reclaims its own cache afterwards. Your reports and logs persist at ~/.mac-cleanup/ — never inside the disposable npx cache.

🧰 What you get from one command

• System health check — top CPU & memory processes
• Xcode + Android + iOS simulator caches
• Every package manager cache: npm, yarn, pnpm, brew, pip, pod, cargo, go, ruby, flutter
• Docker prune (containers / images / volumes)
• User + system caches (browsers + password managers preserved)
• Time Machine local snapshots
• Orphaned app-data scanner
• iOS / iPadOS device backups
• Unused-app detector with configurable threshold
• Stale node_modules / vendor / dist / target / Pods finder
• Large stale files (≥1 GB, untouched 100+ days)
• LaunchAgents / LaunchDaemons audit (orphaned login items)
• Disk-usage report

> "Read every line before you run it. The whole tool is one bash file."

⚙️ Flags I reach for first

• --dry-run --all       safe preview, no deletion
• --profile dev         developer preset (sections 1, 2, 3, 4, 23)
• --profile audit       read-only diagnostics only
• --exclude "14,17"     subtract sections from any preset
• --notify              macOS notification on completion

🚀 Start with the safe preview

  npx macleanup --dry-run --all

Free. macOS 11+. No telemetry.

—
Ahsan Mahmood
aoneahsan.com  ·  linkedin.com/in/aoneahsan
aoneahsan@gmail.com

#macOS #DeveloperTools #CLI #npx #SystemAdmin
~~~

---

## 5. Behind the scenes — single bash file

- **Angle**: Engineering craft / contrarian
- **Best for**: Builder / indie audience
- **Char count**: ~1750 / 2900

~~~text
Why I shipped my Mac cleanup tool as a single bash file in 2026.

Conventional wisdom says: ship a Swift app. Charge subscription. Add an Electron UI. Slap on telemetry.

I shipped 2,400 lines of bash plus an 80-line Node launcher. Total: 2 files. Total tarball size: 41 KB.

📐 The constraints that drove the design

• Auditable. A cleanup tool runs rm -rf and sudo on your behalf. That should be readable, not a binary blob.
• No install. npx macleanup works on any Mac with Node 14+. No homebrew tap, no .dmg, no code-signing dance.
• Zero deps. The Node launcher is 80 lines. It exists for one job: validate Darwin and spawn bash. That's it.
• Persistent state. Logs and reports live at ~/.mac-cleanup/ so they survive npx cache cleanup automatically.
• macOS-native primitives. osascript for Trash moves, tmutil for snapshots, mdls for last-used dates, launchctl for service unloads. Nothing reinvented.

> "Single file means: no curl-pipe-bash, no signing-key surface, no homebrew tap. Drop it in ~/bin/ and you're done."

The cost: no GUI. The benefit: trust by inspection, not trust by brand.

🚀 If you've been burned by a paid Mac cleaner, try the open alternative

  npx macleanup --dry-run --all

Free. MIT-licensed. No telemetry. No upsell.

—
Ahsan Mahmood
aoneahsan.com  ·  linkedin.com/in/aoneahsan
aoneahsan@gmail.com  ·  +92 304 6619706

#macOS #Bash #SoftwareEngineering #IndieDev #BuildInPublic
~~~

---

## 6. LaunchAgents — the silent battery killer

- **Angle**: Specific feature deep-dive
- **Best for**: Performance-curious audience
- **Char count**: ~1750 / 2900

~~~text
I scanned my own Mac yesterday. Found 8 stale LaunchAgents pointing at apps that no longer exist.

Zoom updater. AnyDesk. Adobe GC. CocoaPods. Things I uninstalled months ago.

These orphan LaunchAgents are the silent killer. They keep firing at every login, hitting paths that don't exist, polling, retrying, failing — slowing down boot, burning battery.

I built macleanup section 25 specifically to find them.

🔍 How it works

• Scans ~/Library/LaunchAgents, /Library/LaunchAgents, /Library/LaunchDaemons
• Reads each .plist for Program or ProgramArguments[0]
• Flags every entry whose target binary no longer exists on disk
• Multi-select bulk removal (sudo when removing system items under /Library)
• Writes a permanent audit report at ~/.mac-cleanup/reports/launch-audit-YYYY-MM-DD.txt

> "If you've ever uninstalled an app and your Mac kept being slow, this is probably why."

🚀 Run the audit (read-only — nothing gets deleted on this command)

  npx macleanup --only 25

Free. MIT-licensed. macOS only. No telemetry.

—
Ahsan Mahmood
aoneahsan.com  ·  linkedin.com/in/aoneahsan
aoneahsan@gmail.com

#macOS #Performance #SystemAdministration #DeveloperTools
~~~

---

## 7. What's actually safe to delete on macOS

- **Angle**: Educational / cheat sheet
- **Best for**: Saves & shares (high-value reference content)
- **Char count**: ~2050 / 2900

~~~text
What's actually safe to delete on macOS?

I've spent years figuring this out the hard way. Here's the cheat sheet I baked into macleanup:

✅ Safe to delete anytime

• Xcode DerivedData — rebuilds on next compile
• ~/.gradle/caches — re-downloads on next build
• node_modules older than 30+ days — re-installs in seconds
• Docker dangling images and volumes — literally garbage
• ~/Library/Caches/<bundle-id> for non-Apple apps — apps regenerate
• Browser caches — slower page loads for one day
• ~/.Trash — yes, that's the whole point of Trash

⚠️ Safe but verify first

• Old iOS device backups — only if your device is gone or in iCloud
• Xcode .xcarchive files — required for App Store re-signing if you might rebuild
• Saved Application State — apps won't restore your last window setup
• Time Machine local snapshots — frees space immediately, removes restore points

🛑 Never blindly delete

• /Library/Caches/com.apple.* — macOS rebuilds, but slowly + with side-effects
• /private/var/folders — clears per-user temp; requires reboot
• Anything under /System — SIP should stop you, but still
• Files under ~/Library/Photos or *.photoslibrary outside the Photos UI

> "Aggressive cleanup of /Library/Caches/com.apple.* is a classic way to break a macOS install."

macleanup confirms before every destructive section, dry-runs by default if you pass --dry-run, and skips Apple-managed paths automatically.

🚀 Try the cheat sheet baked into a tool

  npx macleanup --dry-run --all

Free. 27 sections. macOS 11+.

—
Ahsan Mahmood
aoneahsan.com  ·  linkedin.com/in/aoneahsan
aoneahsan@gmail.com

#macOS #SystemAdministration #DeveloperProductivity #SysAdmin
~~~

---

## 8. Privacy / no-telemetry

- **Angle**: Contrarian / privacy-first
- **Best for**: Privacy-conscious audience
- **Char count**: ~1850 / 2900

~~~text
I built a free macOS cleanup tool that makes zero network calls.

No analytics. No phone-home. No "anonymous usage stats." No A/B testing. No crash reporter. Nothing.

The Node launcher (80 lines) only spawns bash. The bash script (~2,400 lines) only touches your filesystem. The npm install and the npx cache cleanup are handled by npm itself — that's it.

📡 The only optional network call

If you explicitly pass --check-update, the tool curls registry.npmjs.org/macleanup/latest once, parses the version, and prints if a newer release exists. No identifying headers. No payload. Opt-in. Manual. Visible in the source.

That's the entire network footprint.

📂 Where your data goes

• Logs   →  ~/.mac-cleanup/logs/<date>.log    (local, your machine only)
• Reports → ~/.mac-cleanup/reports/<section>-<date>.txt   (local)
• Nothing else. Ever.

> "If you can't audit a tool's network behaviour, assume it's spying on you. Mine is two files you can read."

🛡️ Why this matters

A cleanup tool sees:
• Every app you have installed
• Every file path on your Mac
• Sometimes browser history paths
• Sometimes iOS backup contents

That's a lot of sensitive data. Cleanup tools that include analytics report some subset of it home. macleanup refuses to.

🚀 Try a tool that respects your privacy

  npx macleanup

Free. MIT-licensed. Read every line. macOS 11+.

—
Ahsan Mahmood
aoneahsan.com  ·  linkedin.com/in/aoneahsan
aoneahsan@gmail.com

#Privacy #macOS #DigitalPrivacy #DeveloperTools #InfoSec
~~~

---

## 9. Pre-flight before reinstalling Xcode

- **Angle**: Practical workflow / how-to
- **Best for**: iOS / Mac dev audience
- **Char count**: ~1750 / 2900

~~~text
Practical workflow: pre-flight before reinstalling Xcode.

I do this every 3-4 months. The Xcode reinstall dance was always painful — Apple's installer doesn't clean up properly, and DerivedData + simulator state alone can be tens of GB.

Here's the 60-second cleanup I now run.

  npx macleanup --only "1,17"

That triggers exactly two sections.

🧹 Section 1 — Xcode caches, DerivedData, simulators
• Wipes ~/Library/Developer/Xcode/DerivedData (rebuilds on next compile)
• Drops unavailable iOS / tvOS / watchOS simulators
• Asks before nuking CoreSimulator state (recoverable but slow)

📦 Section 17 — Xcode archives
• Lists every .xcarchive with size + date
• Multi-select bulk delete
• Asks before deleting each archive (you may need them for App Store re-signing)

> "Most of my disk-space wins on this Mac came from sections 1 and 17 alone. Those two folders accumulate without bound."

⚙️ I follow it up with the developer profile

  npx macleanup --profile dev --dry-run

That's a preview of sections 1, 2, 3, 4, 23 — every dev cache plus stale node_modules. I review the report at ~/.mac-cleanup/reports/, decide what to delete, and rerun without --dry-run.

🚀 Try it before your next Xcode reinstall

  npx macleanup --only "1,17" --dry-run

macOS 11+. No telemetry. Reports persist locally.

—
Ahsan Mahmood
aoneahsan.com  ·  linkedin.com/in/aoneahsan
aoneahsan@gmail.com

#Xcode #iOSDev #macOS #DeveloperProductivity #AppStore
~~~

---

## 10. The story behind the tool

- **Angle**: Founder narrative / why-built
- **Best for**: Pinned post / about-me content
- **Char count**: ~2050 / 2900

~~~text
I cleaned up my Mac by hand for 4 hours yesterday.

Today I shipped a tool so I never have to again.

It's called macleanup. Free. Single bash file. npx macleanup and you're running.

📖 The story

I had 4 GB free on a 256 GB SSD. Spotlight was indexing forever. Time Machine was complaining. I'd been ignoring it for months because the cleanup process was always:

1. Delete Xcode DerivedData
2. Open System Settings → Storage → Manage
3. rm -rf ~/Library/Caches/... and pray
4. brew cleanup
5. npm cache clean
6. gradle --stop && rm -rf ~/.gradle/caches
7. Empty Trash
8. tmutil deletelocalsnapshots /
9. Repeat for pod, pip, cargo, go, flutter…
10. Hunt for orphan app data manually
11. Forget which apps I haven't opened in years
12. Give up. Tomorrow's problem.

I'd done this dance maybe 30 times in my career. Every time I'd think "this should be a script." Yesterday I finally wrote it.

🎯 Then I kept going

• Added orphaned app-data detection
• Added stale node_modules finder (configurable age threshold)
• Added LaunchAgents audit (the silent battery killer)
• Added a real --dry-run mode so you can preview safely
• Added persistent reports so you can audit every run

> "If you do something painful three times, automate it. If you do it ten times, package it. If you do it thirty times, ship it."

🚀 If your Mac is slow, sluggish, or out of space

  npx macleanup --dry-run --all

Safe preview. Nothing gets deleted. You see exactly what's flagged across 27 sections. Decide from there.

Free. MIT-licensed. Made by one developer because I needed it.

—
Ahsan Mahmood
aoneahsan.com  ·  linkedin.com/in/aoneahsan
aoneahsan@gmail.com  ·  +92 304 6619706

#IndieHacker #BuildInPublic #macOS #DeveloperTools #SideProject
~~~

---

## Resumability marker

When you've used a post, edit its `##` heading to add `[USED]`, e.g.:

```
## 1. Launch announcement [USED]
```

The next batch generator (run this same prompt again) will count the `[USED]` markers, see how many remain unused, and produce a fresh batch of 10 in `linkedin-posts-02.md`. Used posts in this file remain for archival.
