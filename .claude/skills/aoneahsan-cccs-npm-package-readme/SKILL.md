---
name: aoneahsan-cccs-npm-package-readme
description: 'The canonical README pattern shared by every one of our npm packages: the header block with logo, badges and at-a-glance table, the fixed section order and its emoji map, what each section may contain, and the rule keeping the same fact from appearing twice. Use when writing or checking a package README.'
metadata:
  author: aoneahsan
  source: custom-skills/_source-understanding/projects/npm-package-survey.md
---

# The package README

One shape for every package, so a user who learns one recognises the next. Copy
`assets/README.template.md` and delete what the package does not need — **never** invent an order.

Formatting law (anchors, TOC, links, fences) is `aoneahsan-cccs-markdown`. This skill owns *what goes where*.

## The header block — above the first heading

Nine parts, in order; 1–5 inside a centred `<div>`:

1. **Logo** — SVG master, `width="120"`, absolute raw-GitHub URL
2. **`<h1>`** — the package name exactly as published
3. **One-line promise**, ≤ 100 characters, bold
4. **Badges** — version · downloads · license · types · size · CI · node, always that order
5. **Link row** — ≤ 6 short labels: Docs · npm · GitHub · Changelog · AI Guide · Support
6. **`> [!IMPORTANT]`** — only when a must-know-before-install fact exists
7. **Summary**, 2–4 sentences: what it is, who for, what makes it different
8. **At-a-glance table** — version · license · node · platforms · install size · types · status
9. **Table of contents** (H2s only)

## The section order

Fixed. Skip what does not apply; **never reorder what remains.** ✅ = always present; anything else is the
condition that makes the section apply.

| Section | When | | Section | When |
|---|---|---|---|---|
| 💡 Why `<pkg>` | ✅ | | 🚑 Recovery & Troubleshooting | has failure modes |
| ✨ Features | ✅ | | 🚧 Limitations | ✅ |
| 📱 Platform Support | multi-platform | | ❓ FAQ | questions recur |
| 📋 Requirements | non-trivial | | 🏢 Adopters | real ones exist |
| 📦 Installation | ✅ | | 📚 Documentation | ✅ |
| 🚀 Quick Start | ✅ | | 🔄 Changelog | ✅ |
| 🛠️ Usage | ✅ | | 🗺️ Roadmap | optional |
| ⚙️ Configuration | configurable | | 🤝 Contributing | ✅ |
| 🔧 API Reference | ✅ | | 🗂️ Repository | odd layout |
| 🧩 Types | TS-first | | 💬 Support | ✅ |
| 💻 Command Line | has a `bin` | | 📄 License | ✅ |
| 🧪 Examples | useful | | 👤 Author | ✅ |
| 🎛️ Advanced Features | they exist | | 🔗 Links | ✅ |
| | | | 🏷️ Keywords | ✅ |

Read down the left column, then the right. The TOC uses 🧭. **The emoji is part of the section's identity** —
the same section carries the same glyph in every package, and that is what makes the family recognisable.

**What each section may and may not contain is `references/sections.md`** — read it before writing one.

## The single-home rule

**A fact lives in exactly one section; every other mention is a link.** Three places carry links, doing
genuinely different jobs — anything beyond them is repetition:

| Place | Job |
|---|---|
| Header link row | navigation — short labels, no descriptions |
| 📚 Documentation | annotated map: which document answers which question |
| 🔗 Links | the flat canonical URL registry, including non-doc URLs |

## Never in a package README

- **Internal audit scaffolding** — `Current State`, `Verified Package Architecture`, `Verification Commands`,
  which 5–7 of the owner's packages carry today. They are internal QA notes, not user documentation → move to
  `CONTRIBUTING.md` or delete.
- **Duplicate headings** — two `## Links` sections collide on one anchor id.
- **Relative links or images** — npm renders the README off-repo, so they are dead there.
- Invented adopters, fabricated statistics, a claim the package cannot deliver.
- Depth belonging on the docs site. The README earns a reader their first success, then points onward.

## Related skills

`aoneahsan-cccs-markdown` (anchors, TOC, fences, renderer limits) · `aoneahsan-cccs-npm-package` (the
`package.json` this README must agree with, and the docs-target ladder) · `aoneahsan-cccs-copywriting` (the
prose and the honesty rules) · `aoneahsan-cccs-packages-up-to-date` (the publish gate that ships it).
