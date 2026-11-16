---
name: aoneahsan-cccs-npm-package
description: 'Authoring published npm libraries: the package.json field contract, the exports map and dual ESM/CJS build with real type declarations, peer-dependency discipline, what may enter the tarball, semver and changelog practice, the AI integration guide, public-repo governance, and where a package''s docs live. Use before a release.'
metadata:
  author: aoneahsan
  source: custom-skills/_source-understanding/projects/npm-package-survey.md
---

# npm packages

Dependencies and the publish gate live in `aoneahsan-cccs-packages-up-to-date`. This skill is everything
else: the package as a **product** other people install.

## The metadata contract

Every field below is populated, and each is checked against reality — not copied from a sibling package.
Full reference with the exports map: `references/package-json.md`.

| Field | Rule |
|---|---|
| `name` | matches the folder and the README H1. **One manifest per package name, ever** |
| `description` | one line, identical to the README tagline |
| `repository` | **a real git remote that resolves** — not a docs URL, not a 404 |
| `homepage` · `bugs` | the docs site (else the repo) · the repo's `/issues` |
| `funding` | `https://aoneahsan.com/payment?project-id=<name>&project-identifier=<name>` |
| `license` · `author` | SPDX id · the owner's name + email |
| `keywords` | 5–12 real search terms, mirrored in the README's Keywords line |
| `engines.node` | the version actually tested, matching `.nvmrc` |
| `files` | an allowlist. Never `.npmignore` — a denylist leaks whatever it forgot |
| `exports`/`main`/`module`/`types` | every declared subpath resolves on disk |
| `sideEffects` | `false` unless it really has them — it gates tree-shaking |

**`repository` pointing nowhere is a live defect.** Of six of the owner's package repos probed on 2026-07-25,
**three returned 404** from the URL their own `package.json` advertises — so npmjs.com's "Repository" link and
every `bugs` link is broken for those users.

**Two manifests sharing one `name` is the highest-severity shape here.** `npm publish` uses the working
directory, so the wrong `cd` silently ships the wrong tree — which is how `strata-storage@2.8.2` passed every
conventional gate while dropping required setup docs, and sat as `latest` for 25 days.

## Build and types

Dual ESM + CJS with real `.d.ts` for each, source maps **off** in published output, `typescript ~6.0.3` (the
fleet pin — TS 7 breaks the toolchain). A repo build proves nothing about the `exports` map: **walk every
subpath and assert its `types`/`import`/`require` target exists on disk**, then install the packed tarball and
import it for real. A typo'd subpath is invisible until a consumer hits it. `references/build-and-types.md`.

## Dependencies of a library

A library imposes its dependencies on every consumer, so the bar is higher than an app's. Anything the host
app already owns — React, Capacitor, a framework — is a **peer**, with a range as wide as it genuinely
supports plus a matching `devDependency`. Prefer zero runtime dependencies.

## Versioning and the changelog

Semver against the **public** surface: a changed exported signature, a removed subpath, or a raised `engines`
floor is a major. `CHANGELOG.md` in Keep-a-Changelog form, newest first, one entry per published version — the
single source the README's Changelog section reads from. A version on npm with no changelog entry is a release
nobody can explain.

## Where the docs live — the ladder

Resolve in order, stop at the first that exists, and **link only what you verified resolves**:

1. a public **docs site** for the package;
2. its public **GitHub repo**;
3. a **marketing site** that contains real docs;
4. none of these → **build a docs site** at `<npm-name>-docs.aoneahsan.com` (owner decision 2026-07-25),
   public repo on GitHub Pages, per `aoneahsan-cccs-docusaurus`. The DNS record is an owner-only row in
   `docs/MANUAL-TASKS.md`, so nothing is blocked waiting on it.

Probe before writing any URL into a README: `curl -s -o /dev/null -w '%{http_code}' -m 8 <url>`. Written
sources agreeing with each other proves nothing — a typo propagates into all of them.

## What ships, and what must not

The tarball is public forever. It carries `dist/`, `README.md`, `LICENSE`, `CHANGELOG.md` and
`AI-INTEGRATION-GUIDE.md` when there is one — never `CLAUDE.md`/`AGENTS.md`, internal records, `.env` in any
form, keys, or internal notes. Verify against the **extracted tarball**, not the repo.

`references/repo-and-docs.md` covers that sweep, the AI guide, and public-repo governance (root
`CONTRIBUTING.md`, issues on, a `main` ruleset with owner-only bypass — full law in
`~/.claude/rules/public-repo-governance.md`). Every package also keeps `docs/PACKAGES.md`.

## Related skills

`aoneahsan-cccs-npm-package-readme` (the README pattern) · `aoneahsan-cccs-packages-up-to-date` (dependency
upgrades and the publish gate) · `aoneahsan-cccs-markdown` · `aoneahsan-cccs-typescript` ·
`aoneahsan-cccs-docusaurus` (when the ladder ends at rung 4).
