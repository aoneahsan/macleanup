# Community Launch Posts — Show HN & Reddit

**Author**: Ahsan Mahmood — <aoneahsan@gmail.com> · [aoneahsan.com](https://aoneahsan.com) · [linkedin.com/in/aoneahsan](https://linkedin.com/in/aoneahsan)
**Tool**: `macleanup` (run with `npx macleanup`)
**Generated**: 2026-05-10

## How to use this file

These are launch-day community posts. Tone, length, and rules differ sharply from LinkedIn — read the platform notes before submitting.

| Platform | Notes |
|---|---|
| **Show HN** | Hacker News audience is allergic to marketing voice. Be factual, technical, brief. State what's new. Ask for feedback. Comments matter more than the post. |
| **r/macOS** | Allowed to be slightly more casual than HN. Disclose authorship up front (subreddit rules). One self-promo per author per ~7 days. Don't repost. |
| **r/MacApps** | Self-promotion allowed if you actively contribute to the community otherwise. Include the rule-required tag like `[OC]` or `[Tool]` per current sub rules. |
| **Lobste.rs** | Invite-only. If you have an account, post under `unix` and `macos` tags. |

After posting, append `[USED]` to that post's `##` heading.

---

## 1. Show HN — primary post

- **Title** (≤80 chars): `Show HN: Macleanup – a free macOS cleanup CLI in a single bash file (npx)`
- **URL field**: `https://www.npmjs.com/package/macleanup`
- **Text field**: leave blank if URL is set, OR paste the body below if you want a self-post.

### Show HN body (use only if doing a self-post)

~~~text
I built `macleanup` because I'd cleaned up my Mac by hand for the n-th time and finally accepted I'd never stop doing it. It's a single bash script (~2,400 lines) plus an 80-line Node launcher that exists only to make `npx macleanup` work without an install.

What it does:
- 27 sections covering Xcode/Android/iOS dev caches, every package-manager cache, Docker, browser caches, orphan app data, Time Machine snapshots, idle apps, stale node_modules / vendor / dist / target, large unused files, orphan LaunchAgents, du report.
- Real `--dry-run` (every destructive call routes through helpers that no-op).
- Persistent reports + logs at `~/.mac-cleanup/` (outside npx cache).
- Multi-select interactive UI for review-then-delete.
- Five named profiles: `dev`, `minimal`, `cache-only`, `deep`, `audit`.

What it doesn't do:
- No GUI. No Electron. No telemetry. No network calls (except an optional, manual `--check-update`).
- No modification or redistribution under the license — it's source-available, not open-source by OSI definition.

Tarball is 41 KB. Audit the source in an hour. The whole thing is two files plus the docs.

Two technical decisions I'd particularly value feedback on:
1. Pure-bash + Node-launcher-spawning-bash as a packaging shape. The npx ergonomics are great; the only real cost is a bash 3.2+ requirement (default macOS bash). Worth it?
2. Persistent state at `~/.mac-cleanup/{logs,reports}/` rather than `~/Library/Application Support/macleanup/`. I picked the dotfile location for discoverability via `cd ~/.mac-cleanup` — but Apple's HIG would prefer Application Support. What would you have done?

Repo and license: https://github.com/aoneahsan/macleanup
~~~

### Show HN top-comment-ready answers (paste these as comments preemptively if appropriate)

~~~text
Why source-available rather than MIT?

Two reasons. First, this is a tool that runs `rm -rf` and `sudo` on the user's machine — I want a clear paper trail of who is responsible if something goes wrong, and a license that doesn't pretend modifications are also "mine." Second, it's a defence against repackaging into paid Mac-cleaner products; my LICENSE makes that explicitly disallowed. The trade-off I accepted: it doesn't qualify as OSI open-source, and people who only run OSI licenses will pass on it. That's fine.
~~~

~~~text
Why bash 3.2 (the default macOS one) rather than requiring bash 4+?

Because requiring `brew install bash` would defeat the npx-zero-install pitch. The features I really want from bash 4 (associative arrays, `mapfile`, `${var,,}`) all have OK-ish 3.2 workarounds. The script does check `BASH_VERSINFO` at startup and exits cleanly if it's older than 3.2.
~~~

---

## 2. Reddit r/macOS — primary post

- **Title** (max 300 chars; aim ≤90 for mobile preview): `I built a free macOS cleanup CLI you can run with `npx macleanup` — single bash file, no telemetry`
- **Flair**: pick "Showcase" or "Apps" per sub rules
- **Disclosure**: Reddit's self-promo rules require you to disclose you built it. The post body does this in line 1.

### Body

~~~text
[Disclosure: I'm the author. This is a free, source-available tool with no paid version, no upsell, no ads.]

I've been on a mission for a while to fix the "my Mac is full and I don't want to install yet another paid cleaner" problem. After cleaning up my Mac by hand way too many times, I finally scripted it. It's called **macleanup**.

**One command, no install:**

`npx macleanup`

That's it. npm fetches the package, runs the interactive menu, and reclaims its own cache afterwards. Your reports and logs persist at `~/.mac-cleanup/` — never inside the disposable npx cache.

**What's in the box:**

- 27 sections covering Xcode caches, every package-manager cache (npm/yarn/pnpm/brew/pip/pod/cargo/go/flutter/Gradle), Docker, browser caches, system caches, Time Machine snapshots, etc.
- A real `--dry-run` that **never** touches disk — preview before deleting anything
- Stale `node_modules` finder (configurable age threshold)
- Orphan LaunchAgents audit (the silent battery killer when you uninstall apps and forget the leftovers)
- Idle-app detector with bulk-uninstall via Trash
- Multi-select UI for review-then-delete
- 5 named profiles: `dev`, `minimal`, `cache-only`, `deep`, `audit`

**What's not in the box:**

- No GUI, no Electron, no telemetry, no network calls (other than an optional, manual `--check-update`)
- No modification or redistribution per the license — it's **source-available**, not OSI open-source. You can read it, run it, share the URL. You can't fork-and-republish.

**Some specific use cases:**

- `npx macleanup --dry-run --all` → preview the safe-batch cleanup
- `npx macleanup --profile dev --dry-run` → developer preset (dev-tool caches + stale node_modules)
- `npx macleanup --only "1,17"` → pre-flight before reinstalling Xcode
- `npx macleanup --only 25` → orphan LaunchAgents audit (read-only on this command)

**Tech decisions** (in case you're curious):

The whole tool is one bash file (~2,400 lines) plus an 80-line Node launcher. Tarball is 41 KB. I picked this shape because a tool that runs `rm -rf` and `sudo` on your behalf should be readable — not a closed binary. You can audit the entire source in an hour.

**Honest disclaimer:** Cleanup tools can break things. The script confirms before every destructive section, dry-runs everything when `--dry-run` is set, moves apps to Trash via Finder (not `rm -rf`), and skips Apple-managed paths. Even so — back up before you run any cleanup tool.

**Repo**: https://github.com/aoneahsan/macleanup
**npm**: https://www.npmjs.com/package/macleanup

Honest feedback wanted. If you find bugs, file an issue. If the tool deletes something it shouldn't, that's a security bug — email me at aoneahsan@gmail.com privately rather than the issue tracker.
~~~

---

## 3. Reddit r/MacApps — alternate post

- **Title**: `[Tool] macleanup — free, source-available macOS cleanup CLI you run with `npx macleanup``
- Slightly tighter version of the r/macOS post (this sub prefers concise)

### Body

~~~text
[OC, Author] Free, no install, no paid tier.

`npx macleanup` runs an interactive 27-section cleanup menu. Single bash file (~2,400 lines), 80-line Node launcher for the npx magic, 41 KB tarball total. macOS 11+, Apple Silicon + Intel.

**Highlights:**
- Real `--dry-run` (preview before deleting)
- Stale `node_modules` / `vendor` / `target` finder with configurable age
- Orphan LaunchAgents audit (uninstalled-app leftovers that slow down boot)
- Idle-app detector with bulk uninstall (apps go to Trash via Finder)
- Persistent reports at `~/.mac-cleanup/reports/`
- 5 named profiles: `dev`, `minimal`, `cache-only`, `deep`, `audit`
- Zero network calls (optional `--check-update` is the only exception)

**Try the safe preview:**

`npx macleanup --dry-run --all`

**Source-available** (you can read + run, can't redistribute or modify). Repo on GitHub, package on npm. Honest feedback welcome.
~~~

---

## 4. Show HN — fallback short post (if URL submission gets buried)

- **Title**: `Show HN: A free macOS cleanup CLI in one bash file`
- **URL**: `https://github.com/aoneahsan/macleanup`

(No body needed for URL submissions on HN. The discussion happens in comments.)

### Comment-ready talking points (paste as your own first comment)

~~~text
Author here. A few notes for context:

- Total source is two files: a 2,400-line bash script and an 80-line Node launcher. Tarball is 41 KB. You can audit the whole thing in an hour.
- Distribution via `npx macleanup` so users don't need to install anything. The Node launcher exists for that one purpose.
- Persistent state lives at `~/.mac-cleanup/{logs,reports}/` so reports survive npx cache cleanup.
- License is source-available, not OSI open-source. Personal/non-commercial use, no modifications, no redistribution. I picked this so the tool can't be repackaged into paid cleaner products without permission.
- Zero network calls in the default code path. Optional, manual `--check-update` is the only exception and is opt-in via flag.

Happy to answer any technical questions about the implementation, the trade-offs, or specific sections.
~~~

---

## 5. Indie Hackers post

- **Title**: `Shipped my first npm package: a free macOS cleanup CLI you run with `npx macleanup``
- **Tag**: `Show IH` or equivalent

### Body

~~~text
This is a small launch but a fun one.

I'd cleaned up my Mac by hand maybe 30 times in my career — each time thinking "this should be a script." Last week I finally wrote it.

It's called **macleanup**. Free, source-available, single bash file, 41 KB tarball.

**One command:**
`npx macleanup`

27 cleanup sections, real `--dry-run` mode, persistent reports at `~/.mac-cleanup/`, multi-select interactive UI, no telemetry.

**The build / ship in numbers:**
- 4 weeks of evenings
- 2 files (bash + Node launcher)
- 41 KB total tarball
- 0 paid features
- 0 network calls (other than an optional manual update check)

**The lesson I keep relearning:** If you do something painful three times, automate it. If you do it ten times, package it. If you do it thirty times, ship it.

Honest feedback welcome — both on the tool itself and on the launch shape (single npm package, source-available license, no GUI). Did I leave money on the table by not making it freemium? Probably. But that's a trade I made deliberately.

**Try it:** `npx macleanup --dry-run --all`
**Source:** github.com/aoneahsan/macleanup

— Ahsan Mahmood
aoneahsan.com · linkedin.com/in/aoneahsan
~~~

---

## Pre-launch checklist

Before posting any of these:

1. [ ] `npm publish` has succeeded — `npx macleanup --version` returns `4.3.0` from a fresh terminal.
2. [ ] GitHub repo is **public** with the personal-data scrub completed (re-init or `git filter-repo` per earlier conversation).
3. [ ] README's badges resolve correctly (npm version badge, license badge).
4. [ ] You have **at least one prepared answer** for each of: "Why source-available?", "Why bash?", "Why a dotfile location?", "Will you take PRs?", "Is this safe to run on my work Mac?"
5. [ ] You're free to respond to comments for at least the first 4–6 hours after posting. HN/Reddit punish absent authors.
6. [ ] Different posts go to different platforms on different days. Don't blast all five within an hour — it triggers spam filters and looks desperate.

## Suggested ordering

- Day 0 (Monday morning, US time): Show HN URL submission + first author-comment with talking points.
- Day 1: r/macOS post.
- Day 2: r/MacApps post (only if Day 1 didn't already cover the audience).
- Day 3: Indie Hackers post.
- Days 4–7: LinkedIn posts from `linkedin-posts-01.md`, spread one per day.

---

## Resumability marker

If you've used a post, append `[USED]` to its `##` heading. The next batch generator reads the markers and produces fresh angles rather than repeating.
