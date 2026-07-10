# Cold-Email Pitches — Batch 01

**Author**: Ahsan Mahmood — <aoneahsan@gmail.com> · [aoneahsan.com](https://aoneahsan.com) · [linkedin.com/in/aoneahsan](https://linkedin.com/in/aoneahsan) · +92 304 6619706
**Tool**: `macleanup` (run with `npx macleanup`)
**Generated**: 2026-05-10
**Batch**: 01 of N (next batch will be `email-pitches-02.md`)

## How to use this file

1. Pick the template whose audience matches your prospect.
2. Replace the `{{placeholders}}` with one specific, real observation about them — a recent post, a repo, a talk, a product launch. **If the personalisation is generic, the email is junk.** Write one personalised line or skip the email.
3. Read it aloud once before sending. If it sounds like marketing copy, rewrite it.
4. After sending, append `[USED]` to that template's `##` heading.

Each template is **`≤120 words` body**, with a **2–4 word lowercase subject** that looks like an internal email (per cold-email best practice — short utilitarian subjects beat clever ones for open-rate). Single CTA, P.S. with the npx command, compact author block.

These are templates. They expect you to do the personalisation. The first sentence should connect to **their** world, not yours.

---

## 1. Indie dev / solopreneur

- **Audience**: Solo developer, indie hacker
- **Personalisation hook**: Reference one of their projects / recent posts

**Subject:** `tiny mac tool`

~~~text
Hi {{first_name}},

Saw {{their_thing — repo, post, product launch}} — figured you'd appreciate this.

I just shipped a free macOS cleanup CLI: `npx macleanup`. Single bash file you can read in an hour, no install.

It finds the things that bug me as a solo dev:
• Stale node_modules / vendor / target you forgot
• Xcode DerivedData
• Orphan LaunchAgents from uninstalled apps
• Large files untouched 100+ days

Real --dry-run so you can preview before deleting anything.

Worth a 60-second look?

— Ahsan
aoneahsan.com  ·  linkedin.com/in/aoneahsan

P.S. one command:  npx macleanup --dry-run --all
~~~

---

## 2. iOS / macOS dev team lead

- **Audience**: Engineering manager / staff iOS developer
- **Personalisation hook**: Their recent App Store ship, WWDC talk, blog post

**Subject:** `xcode disk pressure`

~~~text
Hi {{first_name}},

Saw your team shipped {{recent_release}} — congrats.

After every Xcode major-version bump my own DerivedData + .xcarchive folder eats 30-50 GB. I built a small CLI for the pre-flight cleanup so I never have to do it by hand again.

`npx macleanup --only "1,17"` runs:
• Section 1 — DerivedData + unavailable simulators
• Section 17 — interactive review of every .xcarchive

Single bash file, ~2,400 lines, free, no telemetry. Useful for your dev fleet?

— Ahsan
aoneahsan.com  ·  linkedin.com/in/aoneahsan

P.S. dry-run is safe:  npx macleanup --only "1,17" --dry-run
~~~

---

## 3. macOS sysadmin / IT admin

- **Audience**: IT admin managing a fleet of Macs
- **Personalisation hook**: Reference their company, role, or a JAMF/Munki post

**Subject:** `fleet cleanup script`

~~~text
Hi {{first_name}},

You handle Macs at {{company}}, so you've probably had the "my Mac is full" ticket more than once.

I shipped a free CLI that handles the safe cleanup paths in one command: `npx macleanup`.

Designed for predictable, scriptable runs:
• `--profile minimal` for a weekly scheduled sweep
• `--dry-run` always available — no surprise deletions
• Persistent reports at ~/.mac-cleanup/reports/ for audit
• `--no-sudo` to skip every privileged section
• Zero network calls — passes corporate proxy review easily

Worth a look for your fleet hygiene runbook?

— Ahsan
aoneahsan.com

P.S.  npx macleanup --profile minimal --dry-run
~~~

---

## 4. Agency / consultancy CTO

- **Audience**: Engineering leader at a dev consultancy
- **Personalisation hook**: Their hiring page / engineering blog / recent client work

**Subject:** `dev box hygiene`

~~~text
Hi {{first_name}},

{{Company}} runs a lot of client projects, which means your engineers' Macs accumulate the artefacts of every contract that ever ran.

Built a free CLI for the cleanup: `npx macleanup`. Multi-project teams get hit hardest by:
• Stale node_modules from old client repos
• .gradle / DerivedData from forgotten Android + iOS work
• Orphan app data from one-off vendor tools

Single bash file, dry-run safe-by-default, persistent reports per machine. Worth recommending to your devs?

— Ahsan
aoneahsan.com  ·  linkedin.com/in/aoneahsan

P.S. preview only:  npx macleanup --dry-run --all
~~~

---

## 5. Tech YouTuber / content creator

- **Audience**: Mac/dev-focused YouTuber, blogger, newsletter writer
- **Personalisation hook**: Reference one of their recent videos / posts

**Subject:** `tool worth a look`

~~~text
Hi {{first_name}},

Loved {{their_recent_video — be specific, time-stamp it}}.

I just shipped a free macOS cleanup CLI: `npx macleanup`. Distinct from the existing landscape because:
• Single bash file you can read on screen
• Real --dry-run mode (most cleaners fake it)
• 27 sections including stale node_modules + LaunchAgents audit
• Zero telemetry, zero network calls
• MIT licensed (license terms in repo)

Mostly emailing because I think your audience would find the "cleanup tool you can audit" angle interesting. Happy to send you a 90-second walkthrough script if useful.

— Ahsan
aoneahsan.com  ·  linkedin.com/in/aoneahsan

P.S.  npx macleanup --dry-run --all
~~~

---

## 6. DevTools / DX engineer

- **Audience**: Developer-experience engineer at a tooling company
- **Personalisation hook**: A blog post, a tool they ship, an OSS contribution

**Subject:** `bash cli question`

~~~text
Hi {{first_name}},

You spend more time than most thinking about developer-experience trade-offs — your post on {{their_post}} stuck with me.

Just shipped a CLI that took the contrarian shape: single bash file (~2,400 lines), tiny Node launcher for npx, zero deps, no GUI.

`npx macleanup` gives users 27 macOS cleanup sections without an install.

Curious whether the pure-bash + npx packaging pattern feels right to you, or if I'm missing something obvious. Honest 5-minute critique would be appreciated.

— Ahsan
aoneahsan.com  ·  linkedin.com/in/aoneahsan

P.S. source: github.com/aoneahsan/macleanup
~~~

---

## 7. Tech newsletter editor

- **Audience**: Editor of a Mac/dev/tools newsletter (e.g. Console, Hacker Newsletter, etc.)
- **Personalisation hook**: A recent issue and which segment yours fits

**Subject:** `for a future issue`

~~~text
Hi {{first_name}},

Long-time reader of {{newsletter}} — issue #{{N}} on {{topic}} was particularly good.

Pitching a tool for the {{which segment — "tools" / "macOS" / "open source"}} section: `npx macleanup`. Free, MIT-licensed macOS cleanup CLI, single bash file, npx-distributable.

Angle that I think readers would care about:
• Trust by inspection (read every line) vs. trust by brand
• Zero network calls
• 27 sections from caches to LaunchAgents audit

Happy to write a 50-word blurb in your house style if useful.

— Ahsan
aoneahsan.com  ·  linkedin.com/in/aoneahsan

P.S.  npx macleanup --dry-run --all
~~~

---

## 8. Open-source maintainer

- **Audience**: Fellow OSS maintainer of a developer tool
- **Personalisation hook**: Their project, an issue thread you read, a release

**Subject:** `npx as a distribution`

~~~text
Hi {{first_name}},

Maintainer-to-maintainer note. Your work on {{their_project}} has been useful — particularly {{specific_thing}}.

I shipped `npx macleanup` recently and noticed Node-launcher-spawning-bash is a packaging shape that gets you global-bin distribution without a homebrew tap or a code-signing dance.

Two questions if you've got 60 seconds:
1. Have you considered npx as a distribution channel for {{their_project}}?
2. Any pitfalls I should look out for after the first 1,000 installs?

Honest answers welcome — even "this is a bad idea" is useful.

— Ahsan
aoneahsan.com  ·  linkedin.com/in/aoneahsan

P.S.  npx macleanup
~~~

---

## 9. Mac power-user friend (warm reach-out)

- **Audience**: Someone you actually know — friendly tone
- **Personalisation hook**: Whatever you last talked about

**Subject:** `you'll like this`

~~~text
Hey {{first_name}},

Remember when you were complaining about {{thing — slow Mac / full disk / "I've stopped trying to clean it"}}?

Built this for you basically. Free. One command:

   npx macleanup --dry-run --all

Single bash file, 27 cleanup sections, real dry-run mode, no telemetry. Reports save at ~/.mac-cleanup/ so you can audit before deleting.

If it works for you, would love a brutally honest reaction. If it doesn't, also tell me — I'd rather hear it from a friend than a stranger.

— Ahsan
aoneahsan.com  ·  +92 304 6619706
~~~

---

## 10. CTO / VP Engineering (executive brief)

- **Audience**: Senior engineering leader. Ultra-brief, peer-level.
- **Personalisation hook**: Their recent talk, hire announcement, or org news

**Subject:** `mac dev hygiene`

~~~text
{{first_name}},

Saw {{recent_signal}}. Brief note.

For dev-fleet disk hygiene we've been using a small CLI that's worked well: `npx macleanup`. Single-file bash, no install, dry-run by default, no network calls. Predictable enough to put in a scheduled run.

Useful pattern even if you don't ship it to your team — the source is short enough to read in a meeting.

— Ahsan Mahmood
aoneahsan.com  ·  linkedin.com/in/aoneahsan

P.S.  npx macleanup --profile minimal --dry-run
~~~

---

## Resumability marker

When you've used a template, edit its `##` heading to add `[USED]`, e.g.:

```
## 1. Indie dev / solopreneur [USED]
```

The next batch generator will count `[USED]` markers and produce a fresh batch in `email-pitches-02.md`.

## Reminder on personalisation

The cold-email skill is unambiguous: **if you remove the personalised opening and the email still makes sense, the personalisation isn't working.** The `{{placeholders}}` exist precisely because you have to do the work. Sending these as-is to 100 strangers will get you a 0% reply rate and possibly a spam flag. Send 10 with real research and you'll outperform every shotgun campaign in their inbox.
