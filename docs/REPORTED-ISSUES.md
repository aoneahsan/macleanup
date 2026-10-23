# Reported Issues — macleanup

Open issues only. When one is fixed, move the entry to `RESOLVED-ISSUES.md` with the resolution date and the
fixing version. Never delete an entry.

**Last Updated:** 2026-10-23

---

### ISSUE-003 — `engines.node: ">=14"` is declared but not exercised

**Affected version:** 4.6.1
**Severity:** Low — a wrong floor here produces a confusing failure rather than a clean `EBADENGINE`.

**Symptom.** `package.json` declares `"engines": { "node": ">=14" }`. Nothing verifies that claim: there is
no `.nvmrc`, no CI matrix, and no test run on Node 14. The launcher is only ever executed on the maintainer's
current Node (24.x at the time of writing).

**Root cause.** The floor appears to have been chosen by inspection rather than measurement. Reading
`bin/mac-cleanup.js`, the syntax used (spread in an array literal, `Object.assign`, `catch (_)` with a
binding, `require`) is all ES2015-or-earlier and *should* run on Node 14, so the declaration is plausible —
but "plausible" is not "verified".

**Suggested fix.** Either run the launcher once under Node 14 and record the result, or raise the floor to a
version actually supported and tested. **Raising the floor is a breaking change** (a consumer on an older
Node would newly fail `EBADENGINE`), so it belongs in a major bump, not a patch. Adding an `.nvmrc` pinning
the development version would also close the gap the metadata contract expects.

**Reporter:** package-standard audit, 2026-07-25.

---

### ISSUE-004 — `main` points at the CLI launcher, so `require('macleanup')` runs the cleanup tool

**Affected version:** 4.6.1
**Severity:** Medium — an unusual but genuinely destructive footgun.

**Symptom.** `package.json` sets `"main": "bin/mac-cleanup.js"`. That file is not a module — it exports
nothing and, on load, spawns `mac-cleanup.sh` with `stdio: 'inherit'` and the parent's `process.argv`. So
`require('macleanup')` or `import 'macleanup'` from any Node program launches the interactive cleanup tool as
an import side effect, inheriting whatever argv the host process happens to have. A tool that scans
`node_modules` for importable entry points would trigger it.

**Root cause.** `main` was set alongside `bin` for a package that has no library surface. The README now
states plainly that there is no programmatic API.

**Suggested fix.** Remove `main` entirely. A `bin`-only package is well-formed, and `require('macleanup')`
would then fail fast with a resolution error instead of executing a destructive tool.

> **This needs an owner decision before it is changed.** `main` is a published entry point, and removing one
> is a compatibility change even when — as here — the behaviour it enables is undesirable. It was left
> untouched in the 2026-07-25 audit for that reason.

**Reporter:** package-standard audit, 2026-07-25.

---
