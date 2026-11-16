# Section-by-section content contract

What each section holds, what it must not hold, and when to delete it. The order is fixed; every section here
is optional-by-condition except the ones marked required.

## The header block

**Logo** — SVG master at `assets/logo.svg`, referenced by absolute raw-GitHub URL, `width="120"`. A package
with no logo gets one made from its initial and brand colour before the README is called done; two of fourteen
have one today.

**One-line promise** — under 100 characters, bold, no marketing verbs. *"One storage API across web, native
and Node."* not *"The ultimate storage solution."* It is the same sentence as `package.json` `description`;
if they differ, one of them is wrong.

**Badges** — fixed order so the eye learns it: version, downloads, license, types, size, CI, node. Every badge
links to what it measures. Only badges that measure themselves — never a hand-written "production ready".

**Link row** — at most six, short labels only. It is a navigation bar; the annotation belongs in 📚 Documentation.

**`> [!IMPORTANT]` callout** — only when a user who skips it gets a broken install. `strata-storage`'s missing
`npx cap sync` step is the canonical case: its absence from the bundled docs broke native adapters silently on
device. No such fact → delete the block. A callout on every README trains people to skip callouts.

**Summary** — 2–4 sentences: what it is, who it is for, what makes it different. This is the paragraph npm
search results and AI assistants quote.

**At-a-glance table** — the facts a developer checks before installing. `Version` matches `package.json`;
`Node` matches `engines`; `Install size` comes from bundlephobia, not a guess.

## 💡 Why `<pkg>` — required

The problem first, the package second. Then an honest comparison table against the real alternative, and a
**"not the right tool when"** line. Naming where it does not fit is the most trust-building sentence in the
file, and it prevents the issue reports that start *"I assumed this would…"*.

Never: superlatives, competitor disparagement, invented benchmark numbers.

## ✨ Features — required

Capability bullets, bolded lead, one line each. **No code** — the first code a reader meets should be
Installation, then Quick Start. If a bullet needs a snippet to make sense, it belongs in Usage.

## 📱 Platform Support — when multi-platform

The matrix table and nothing else. ✅ / ⚠️ / ❌ with a Notes column carrying the caveat. Every prerequisite
belongs in Requirements; every setup step in Installation.

## 📋 Requirements — when non-trivial

Runtime versions, peer dependencies, native prerequisites — each with **why**, so a reader can judge whether a
version they have is close enough. Delete when the answer is just "Node".

## 📦 Installation — required

The install command, then every post-install step: a native sync, a config file, a generated key, a platform
permission. This is the only place setup steps appear.

Show `yarn add` as the house default; add `npm i`/`pnpm add` only for a CLI tool where `npx` is the real entry
point.

## 🚀 Quick Start — required

**One** example. The smallest complete thing that produces a real result, runnable exactly as written —
imports included, no `…` elisions, no undefined variables. If it needs three blocks it is not a quick start;
move it to Usage and find the smaller win.

## 🛠️ Usage — required

The common tasks, one short example each under an H3. Shortest form that works. Anything needing a page of
explanation gets two lines here and a link to the docs site.

## ⚙️ Configuration — when configurable

One options table: name, type, default, what it does. A **Default** column removes the need to write
"defaults to X" in every description. Deep options go to the docs site.

## 🔧 API Reference — required

An **index, not the documentation**: exported name, signature, link. A README that inlines a full API reference
is unreadable and goes stale the day after it is written. When there is no docs site yet, link into the repo's
`docs/` — and note the package needs a docs site (see the ladder in `aoneahsan-cccs-npm-package`).

## 🧩 Types — when TS-first

The exported types a consumer actually touches, as a code block. Not every internal type — the ones that
appear in a signature above.

## 💻 Command Line — when the package has a `bin`

Invocation, a command table, a flag table. Flags get defaults. Anything destructive is marked, and a
`--dry-run` is documented first if one exists.

## 🧪 Examples — when useful

Goal-oriented: *"I want to X"* → link. Prefer runnable examples in the repo over inline code; inline examples
here duplicate Usage.

## 🎛️ Advanced Features — when they exist

One line and a link per feature. This section exists to tell a reader the capability is there — not to teach
it. If it grows past a screen, it is the docs site's job.

## 🚑 Recovery & Troubleshooting — when there are failure modes

A `Symptom → Cause → Fix` table, symptom phrased the way a user experiences it (the error text they see, not
the internal cause). This is the section most likely to be found by search, so use their words.

## 🚧 Limitations — required

What the package does **not** do, plainly. Known gaps, unsupported platforms, deliberate non-goals. Required
even when short: a README with no limitations section reads as one that has not thought about them.

## ❓ FAQ — when questions recur

Real questions, from issues and support conversations. Never invented ones — a fabricated FAQ is filler that
pushes real content further down.

## 🏢 Adopters — when real ones exist

Verifiable users only, and **delete the section rather than invent one**. An empty or padded adopters list is
worse than none.

## 📚 Documentation — required

The annotated map: which document answers which question, and when to read it. Distinct from 🔗 Links, which
is the flat URL registry — this one has a "read it when" column and only covers documentation.

## 🔄 Changelog — required

The latest version and one line on what changed, then a link to `CHANGELOG.md`. Never a second copy of the
history; the changelog file is the single home.

## 🗺️ Roadmap — optional

Only when there is a real plan. Delete rather than ship an aspirational list that ages into a broken promise.

## 🤝 Contributing — required

A short paragraph and a link to `CONTRIBUTING.md`: how to fork and PR, how to request collaborator access, and
that `main` is protected so every change lands through review.

## 🗂️ Repository — when the layout is non-obvious

A folder map for a monorepo or an unusual structure. A conventional `src`/`dist` package does not need it.

## 💬 Support — required

Where to file issues, then the support link in the exact standard form:
`https://aoneahsan.com/payment?project-id=<name>&project-identifier=<name>`. Never Open Collective, never
GitHub Sponsors. Framed as giving back, never as asking.

## 📄 License — required

SPDX identifier, copyright line, link to the `LICENSE` file. One line.

## 👤 Author — required

Name and contact links. Kept identical across every package.

## 🔗 Links — required

The flat canonical URL registry — documentation, npm, repository, issues, changelog, support. The **one place
a bare URL is written out**; everywhere else in the file a URL is a labelled link. This is what makes the
single-home rule enforceable rather than aspirational.

## 🏷️ Keywords — required

One italic line, `·`-separated, mirroring `package.json` `keywords` exactly. If they drift, `package.json` is
the source of truth.
