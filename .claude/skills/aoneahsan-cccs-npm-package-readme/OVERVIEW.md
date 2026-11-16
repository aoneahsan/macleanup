# The package README — overview

## Purpose

A user who learns one of the owner's packages should recognise the next one instantly. That only happens if
every README has the same shape, and a survey on 2026-07-25 found it did not.

Across the 14 published packages, only four headings appear in all of them (`Installation`, `Quick Start`,
`Features`, `License`). The files run from **57 to 829 lines**. **Not one has a table of contents.** Two have
a logo; six have no badges at all. Three visibly different generations of house style are in circulation at
once — an internal audit trio (`Current State` / `Verified Package Architecture` / `Verification Commands`)
leaking into 5–7 public READMEs, a heavy-emoji generation, and a plain-prose generation. Two packages ship a
**duplicate `## Links` heading**, which collides on one anchor id and makes the second unreachable. One has no
H1 at all.

This skill fixes the shape. `aoneahsan-cccs-markdown` owns formatting law; this one owns **what goes where**,
so the two compose without overlapping.

## What this skill does

- Defines the **header block** — logo, title, one-line promise, a fixed badge order, a short link row, an
  optional must-know callout, a summary, an at-a-glance table, and the table of contents.
- Fixes the **27-section order** and marks which are required, which are conditional, and which are skipped.
- Assigns each section a **stable emoji**, so the same section carries the same glyph in every package. The
  explicit-anchor contract is what makes emoji headings safe to use at all.
- States, per section, what it holds **and nothing else** — the fix for READMEs that explain installation
  three times.
- Carries the **single-home rule** and the one deliberate exception: three link-bearing places that do
  genuinely different jobs (navigation row, annotated docs map, flat URL registry).
- Bans internal audit scaffolding, duplicate headings, relative links, and invented adopters from public
  README copy.
- Ships `assets/README.template.md` — a fill-in-the-blanks file, so the pattern is reproduced mechanically
  rather than remembered.

## When it gets invoked

- Writing or rewriting any package README.
- Adding a section, or wondering where a piece of information belongs.
- "the readme is a mess" / "make this package look like the others".
- Auditing a package before a release — the README ships inside the tarball, so it is release content.
- Any work that changes what the package does, since Features, Limitations and the API index move with it.

## Where it applies

| Scope | Applies |
|---|---|
| Project types | every published npm package the owner owns |
| Stack override | the section order is language-independent; a Dart or Rust package keeps the same order and swaps the install/usage idiom |

## Sources

| Source | Record |
|---|---|
| 14-package README survey, 2026-07-25 | `_source-understanding/projects/npm-package-survey.md` |
| Owner decisions, 2026-07-25 | the section list, one emoji per H2 from a fixed map, no repetition across sections |

## Related skills

- `aoneahsan-cccs-markdown` — anchors, TOC, code fences, link policy, renderer limits
- `aoneahsan-cccs-npm-package` — the `package.json` this README must agree with; the docs-target ladder
- `aoneahsan-cccs-copywriting` — the prose inside the sections and the honest-framing rules
- `aoneahsan-cccs-packages-up-to-date` — the publish gate; a README only reaches npmjs.com by publishing

## Maintenance

- **Living registries this skill points at:** none directly; the support-link format comes from
  `~/.claude/rules/publishing-compliance.md`.
- **The emoji map is a contract.** Changing a glyph means changing it in every package or the family stops
  looking like a family — treat it as an owner decision.
- **Last reviewed:** 2026-07-25
