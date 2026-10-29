# Reported Issues — macleanup

Open issues only. When one is fixed, move the entry to `RESOLVED-ISSUES.md` with the resolution date and the
fixing version. Never delete an entry.

**Last Updated:** 2026-10-29

---

### ISSUE-003 — `engines.node: ">=14"` is declared but not exercised

**Affected version:** 4.6.1
**Severity:** Low — a wrong floor here produces a confusing failure rather than a clean `EBADENGINE`.

**Symptom.** `package.json` declares `"engines": { "node": ">=14" }`. Nothing verifies that claim: there is
no `.nvmrc`, no CI matrix, and no test run on Node 14. The launcher is only ever executed on the maintainer's
current Node (24.x at the time of writing).

**Root cause.** The floor appears to have been chosen by inspection rather than measurement. Reading
`bin/macleanup.js`, the syntax used (spread in an array literal, `Object.assign`, `catch (_)` with a
binding, `require`) is all ES2015-or-earlier and *should* run on Node 14, so the declaration is plausible —
but "plausible" is not "verified".

**Suggested fix.** Either run the launcher once under Node 14 and record the result, or raise the floor to a
version actually supported and tested. **Raising the floor is a breaking change** (a consumer on an older
Node would newly fail `EBADENGINE`), so it belongs in a major bump, not a patch. Adding an `.nvmrc` pinning
the development version would also close the gap the metadata contract expects.

**Reporter:** package-standard audit, 2026-07-25.

---
