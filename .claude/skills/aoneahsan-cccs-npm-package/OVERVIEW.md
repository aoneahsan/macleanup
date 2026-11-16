# npm packages — overview

## Purpose

The owner publishes 14 npm packages. Until now the catalog covered dependencies
(`aoneahsan-cccs-packages-up-to-date`) and the runtime (`aoneahsan-cccs-nodejs`) but never **the package as a
product someone else installs** — so every package's metadata, build shape and repository wiring was decided
independently, and the results diverged.

A survey on 2026-07-25 measured the cost. Three of six package repositories probed returned **404 from the
URL their own `package.json` advertises**, so npmjs.com's "Repository" link and every `bugs` link is dead for
those packages. `native-update` has a documentation URL in its `repository` field instead of a git remote.
`strata-storage` has **two manifests carrying the same package name**, one a patch behind — the exact shape
that produced the 2.8.2 incident, where a publish from the wrong directory shipped a tree missing required
setup documentation and sat as `latest` for 25 days. Not one of the 14 has the `docs/PACKAGES.md` the
documentation rule requires.

## What this skill does

- Fixes the **`package.json` field contract** — every field populated and checked against reality, with the
  rule that `repository` must be a git remote that actually resolves.
- Makes **one manifest per package name** an explicit rule, with the 2.8.2 incident as the reason.
- Requires `files` as an allowlist rather than `.npmignore`, because a denylist leaks whatever it forgot.
- Sets the build shape: dual ESM + CJS, real `.d.ts` per format, source maps off in published output, the
  fleet's `typescript ~6.0.3` pin.
- Requires **every `exports` subpath to be walked and resolved on disk**, then the packed tarball installed
  and imported for real — a repo build says nothing about the exports map.
- Draws the library-specific dependency line: anything the host app owns is a peer with a wide range; prefer
  zero runtime dependencies.
- Ties semver to the public surface and requires a changelog entry per published version.
- Encodes the **docs-target ladder** — docs site → public repo → marketing site → build a docs site at
  `<npm-name>-docs.aoneahsan.com` — with a probe before any URL is written down.
- States what may and may not enter the tarball, verified against the extracted tarball rather than the repo.

## When it gets invoked

- Creating a new npm package, or preparing an existing one for release.
- Changing entry points, the `exports` map, the build, or the `files` array.
- Fixing package metadata — a wrong `repository`, a missing `funding`, stale `keywords`.
- Deciding where a package's documentation should live, or building it a docs site.
- Auditing an unfamiliar or inherited package.
- "why is the repository link on npm broken", "which directory do we publish from".

## Where it applies

| Scope | Applies |
|---|---|
| Project types | every published npm library the owner owns; not apps, not private workspace units |
| Stack override | the concerns map to any package registry — `pub`, crates.io, Packagist. Manifest field names change; the contract (resolving repo link, allowlisted files, verified entry points, one manifest per name) does not |

## Sources

| Source | Record |
|---|---|
| 14-package survey + live registry/repo probes, 2026-07-25 | `_source-understanding/projects/npm-package-survey.md` |
| `strata-storage@2.8.2` incident | `aoneahsan-cccs-packages-up-to-date/references/publishing.md` |
| Owner decision, 2026-07-25 | docs ladder rung 4 — build a site at `<npm-name>-docs.aoneahsan.com` |

## Related skills

- `aoneahsan-cccs-npm-package-readme` — the canonical README pattern and its template
- `aoneahsan-cccs-packages-up-to-date` — dependency upgrades and the seven-step publish gate
- `aoneahsan-cccs-markdown` — the anchor contract every public file in the package follows
- `aoneahsan-cccs-typescript` — the TS6 pin and library tsconfig
- `aoneahsan-cccs-docusaurus` — building the docs site when the ladder reaches rung 4

## Maintenance

- **Living registries this skill points at:** `~/.claude/rules/public-repo-governance.md`,
  `~/.claude/rules/package-version-known-issues.md` (the TS pin) — linked, never copied.
- **Volatile:** the TypeScript pin moves when TS 7 is usable. The docs ladder is an owner decision and should
  not be changed without one.
- **Last reviewed:** 2026-07-25
