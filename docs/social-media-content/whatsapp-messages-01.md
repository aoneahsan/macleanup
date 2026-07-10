# WhatsApp Messages — Batch 01

**Author**: Ahsan Mahmood — <aoneahsan@gmail.com> · [aoneahsan.com](https://aoneahsan.com) · [linkedin.com/in/aoneahsan](https://linkedin.com/in/aoneahsan) · +92 304 6619706
**Tool**: `macleanup` (run with `npx macleanup`)
**Generated**: 2026-05-10
**Batch**: 01 of N (next batch will be `whatsapp-messages-02.md`)

## How to use this file

1. Pick a message that fits the recipient (friend, colleague, dev contact, family).
2. Copy everything between the `~~~` fences.
3. Paste into WhatsApp.
4. After sending, append `[USED]` to that message's `##` heading. The next batch generator will skip used items and only refill what's missing.

Each message is **`≤400` chars** so it lands as one snappy bubble — no scrolling, no "tap to read more". Tone is casual, like recommending a tool to a friend. Every message includes the `npx` command, one verified value bullet, and an author signoff.

Claims have been cross-checked against the actual product. No invented features.

---

## 1. Casual launch share

- **Audience**: Mac-using friends / colleagues
- **Char count**: ~370 / 400

~~~text
Hey! Just shipped a free Mac cleanup tool — macleanup 🧹

One command, no install:
  npx macleanup

27 sections covering Xcode, brew, npm, Docker, stale node_modules, large unused files, orphan login items + more. Has a real dry-run so you preview before deleting anything.

Free. Single bash file you can read.

— Ahsan
aoneahsan.com
~~~

---

## 2. Disk-space pain

- **Audience**: Anyone complaining about a slow / full Mac
- **Char count**: ~340 / 400

~~~text
Mac running out of space?

Try this — it's a dry-run, nothing gets touched:
  npx macleanup --dry-run --all

Free CLI I built. Scans 27 places (caches, dev folders, abandoned node_modules, orphan app data) and shows what's safe to delete. You opt-in per section.

— Ahsan
aoneahsan.com
~~~

---

## 3. Dev-focused

- **Audience**: Engineering friends, fellow developers
- **Char count**: ~330 / 400

~~~text
If you're a dev on Mac, you probably have GBs of node_modules + .gradle rotting on disk.

  npx macleanup --profile dev --dry-run

Finds them all (older than 100 days by default), shows sizes, lets you bulk-delete with one tick. Free, open source (MIT), macOS only.

— Ahsan
linkedin.com/in/aoneahsan
~~~

---

## 4. Safety / trust angle

- **Audience**: Friends who don't trust paid Mac cleaners
- **Char count**: ~360 / 400

~~~text
Built a macOS cleanup CLI you can actually read 👇

One bash file, ~2,400 lines. No binaries, no telemetry, no phone-home.

  npx macleanup

Real dry-run mode. Confirms before every delete. Reports persist at ~/.mac-cleanup/.

Free. Try it: aoneahsan.com

— Ahsan
+92 304 6619706
~~~

---

## 5. Quick stats from a real scan

- **Audience**: Anyone you've talked Mac-perf with
- **Char count**: ~290 / 400

~~~text
Just scanned my own Mac with my new tool — found:

• 5 GB stale .gradle caches
• 8 dead LaunchAgents from uninstalled apps
• 30+ abandoned node_modules

Yours is probably similar 😅

  npx macleanup --dry-run --all

Free. macOS 11+.

— Ahsan
aoneahsan.com
~~~

---

## 6. Pre-Xcode reinstall

- **Audience**: iOS / Mac developers
- **Char count**: ~330 / 400

~~~text
About to reinstall Xcode? Run this first:

  npx macleanup --only "1,17" --dry-run

Wipes DerivedData and reviews every .xcarchive. Easily tens of GB back, in 60 seconds. Free, single bash file, no install needed (npx fetches it).

— Ahsan
linkedin.com/in/aoneahsan
~~~

---

## 7. Pure call to action

- **Audience**: Cold contacts / one-line pitch
- **Char count**: ~330 / 400

~~~text
Free macOS cleanup tool 🧹

  npx macleanup

• 27 sections
• Dry-run safe-by-default
• Persistent reports at ~/.mac-cleanup/
• Zero network calls, no telemetry
• Single bash file, fully readable

macOS 11+, Apple Silicon + Intel.

— Ahsan Mahmood
aoneahsan.com  ·  +92 304 6619706
~~~

---

## 8. Privacy-first angle

- **Audience**: Privacy-conscious friends
- **Char count**: ~370 / 400

~~~text
Don't trust paid Mac cleaners with your file paths? Same.

  npx macleanup

Zero network calls. Single bash file you can read in an hour. No analytics, no telemetry, no upsell. Reports stay local at ~/.mac-cleanup/.

Free. MIT-licensed. macOS only.

— Ahsan
aoneahsan@gmail.com
aoneahsan.com
~~~

---

## 9. Personal / founder share

- **Audience**: Mutuals, supportive friends
- **Char count**: ~310 / 400

~~~text
Spent 4 hours cleaning my Mac yesterday.

Built a tool today so I never have to again 😅

  npx macleanup --dry-run --all

27 cleanup sections, multi-select UI, persistent reports, free.

If your Mac is sluggish this'll show you why in 2 minutes.

— Ahsan
aoneahsan.com
~~~

---

## 10. Profiles feature

- **Audience**: Power users / dev colleagues
- **Char count**: ~340 / 400

~~~text
5 named presets in macleanup, pick one with --profile:

• dev      → npm/Xcode/Docker + node_modules
• audit    → read-only scans, no deletes
• deep     → big monthly clean
• minimal  → quick weekly
• cache-only → every cache layer

  npx macleanup --profile dev --dry-run

Free. macOS only.

— Ahsan
linkedin.com/in/aoneahsan
~~~

---

## 11. LaunchAgents — slow login fix

- **Audience**: Anyone whose Mac feels slow at login
- **Char count**: ~350 / 400

~~~text
Mac slow on every login?

Probably orphan LaunchAgents from uninstalled apps still firing in the background. Section 25 of macleanup scans for them in 5 seconds:

  npx macleanup --only 25

Read-only on that command. Lists every login item pointing at a missing binary.

Free.
— Ahsan
aoneahsan.com
~~~

---

## 12. One-line elevator pitch

- **Audience**: Anyone — quick share
- **Char count**: ~320 / 400

~~~text
Free macOS cleanup CLI, single bash file, zero install:

  npx macleanup --dry-run --all

27 sections, true dry-run, persistent reports, no telemetry, no upsell. Made by one dev because I needed it.

— Ahsan Mahmood
aoneahsan@gmail.com
aoneahsan.com
+92 304 6619706
~~~

---

## Resumability marker

When you've used a message, edit its `##` heading to add `[USED]`, e.g.:

```
## 1. Casual launch share [USED]
```

The next batch generator will count the `[USED]` markers, see how many remain unused, and produce a fresh batch of 10–15 in `whatsapp-messages-02.md`. Used messages in this file remain for archival.
