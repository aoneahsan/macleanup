# Resolved Issues

### ISSUE-001 — Section 10 (Empty Trash) is permanently destructive but not deep-gated, so `--profile minimal --yes` empties the Trash unattended

**Resolved:** 2026-10-23 · released in 4.7.0

**Affected version:** 4.6.1 (present since profiles were added in 4.3.0)
**Severity:** High — irreversible data loss with no second opt-in.

**Symptom.** `mac-cleanup --profile minimal --yes` empties the user's Trash without any gate beyond `--yes`.
Everything in the Trash is permanently gone, including items a user had deliberately parked there for
recovery — possibly items macleanup itself put there during an earlier section-21 or section-24 run.

**Repro.**

```bash
mac-cleanup --profile minimal --yes     # Trash is emptied
```

**Root cause.** Three facts combine, each individually reasonable:

- `mac-cleanup.sh:896` — `minimal)` resolves to sections `5,7,8,9,10`, and section 10 is *Empty Trash*.
- `mac-cleanup.sh:3293` — `DEEP_INTERACTIVE_SECTIONS=" 6 11 14 21 24 "`. **Section 10 is not in the set**,
  so it does not require `--i-understand-deep`.
- `confirm()` — `if (( ASSUME_YES )); then return 0; fi` returns true unconditionally, so section 10's own
  `confirm "Empty Trash (…)? This is irreversible."` is auto-accepted by `--yes`.

The deep-gate set is otherwise well chosen; section 10 looks like an omission, since it is the only
*permanently* destructive section reachable from a named profile.

**Suggested fix.** Either (a) add `10` to `DEEP_INTERACTIVE_SECTIONS` so `--yes` alone cannot empty the
Trash, or (b) remove section 10 from the `minimal` profile — a "quick, mostly-safe weekly sweep" arguably
should not contain the one irreversible section. (a) is the safer change and matches how 11/14/24 are already
treated. Both are behaviour changes and would want a minor bump plus a changelog note.

**Interim mitigation.** Documented in the README's tier table as a `[!WARNING]` (2026-07-25) so the behaviour
is at least not a surprise.

**Reporter:** package-standard audit, 2026-07-25.

---

### ISSUE-002 — Denying macOS Automation access silently downgrades sections 21 and 12 from move-to-Trash to permanent delete

**Resolved:** 2026-10-23 · released in 4.7.0

**Affected version:** 4.6.1
**Severity:** High — the documented safety guarantee ("apps are moved to Trash, you can recover") stops
holding, with no clear signal to the user.

**Symptom.** The safety model promises that uninstalled apps and orphaned app data go to the Trash and stay
recoverable. When macOS has not granted the terminal Automation access for Finder — or the session is
headless/SSH — the items are deleted outright instead. The user believes they can restore from the Trash and
cannot.

**Repro.** Revoke Automation access for the terminal (System Settings → Privacy & Security → Automation),
then run section 21 against a disposable app and check the Trash. Nothing arrives there.

**Root cause.** `osascript_trash()` (`mac-cleanup.sh:696`) swallows all output —
`osascript -e "…" >/dev/null 2>&1` — and returns the non-zero exit as an ordinary failure. Callers then fall
back to a direct delete:

- `mac-cleanup.sh:2609` (section 21, companion data) — `if osascript_trash "$dp" || safe_rm_rf "$dp"; then`
  — **fully silent**; no warning is emitted at all.
- `mac-cleanup.sh:2593` (section 21, the `.app` itself) — warns `"Finder move failed; trying guarded rm"`
  before falling back, which is better but does not name the cause.
- `mac-cleanup.sh:2050` (section 12) — same `|| safe_rm_rf` shape.

Section 24 is unaffected: it calls `osascript_trash` with **no** rm fallback, so a permission failure there
fails safe.

**Suggested fix.** Detect the permission failure specifically rather than treating it as a generic error:
capture `osascript`'s stderr, and on the Automation-denied case either (a) abort the section with an
actionable message naming the System Settings path, or (b) prompt once — "Trash is unavailable; delete
permanently instead?" — defaulting to no. At minimum, make the companion-data fallback warn as loudly as the
`.app` fallback does.

**Interim mitigation.** Documented in the README as a `[!WARNING]` and in Recovery & Troubleshooting
(2026-07-25).

**Reporter:** package-standard audit, 2026-07-25.

---

---

### ISSUE-005 — `docs/` still describes v4.5.0

**Resolved:** 2026-10-23 · current published version references updated to 4.6.3

**Affected version:** docs as of 4.6.1
**Severity:** Low — documentation drift.

**Symptom.** `docs/README.md` states `**Current version:** 4.5.0` and closes with
`_Documentation last reviewed against mac-cleanup v4.5.0._`, two releases behind the published 4.6.1. Its
comparison table also cites "~3000 lines, 2 files"; the script is now ~3,600 lines.

**Root cause.** The docs set is maintained separately from the release flow, and no gate ties a docs review
to a version bump.

**Suggested fix.** Refresh the version references and re-read the pages against 4.6.1. Longer term, either
drop the hardcoded version from `docs/README.md` (the npm badge already carries it) or add a parity check to
`prepublishOnly` like the existing `version:check`, which already guards `mac-cleanup.sh`.

**Reporter:** package-standard audit, 2026-07-25.
