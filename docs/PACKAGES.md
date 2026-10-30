# Packages — macleanup

Inventory of every `package.json` unit in this repository, what each depends on, and why.

**Last Updated:** 2026-07-25

---

## Manifest units

| Path | Name | Published? | Purpose |
|---|---|---|---|
| `package.json` | `macleanup` | ✅ npm | The CLI. Ships the bash script + a Node launcher. |
| `desktop/package.json` | `macleanup-desktop` | ❌ never | Tauri GUI wrapping the same script. Built and released as a `.app` via GitHub Releases, not npm. |

**One manifest per package name.** Verified 2026-07-25 — the two manifests carry *distinct* names, so there is
no directory from which `npm publish` could ship the wrong tree. Re-verify after any build:

```bash
find . -name package.json -not -path "*/node_modules/*" -not -path "./.yarn/*" \
  -exec node -p "require('{}').name" \;
```

Nothing in this repo has a build step that emits a `package.json`, so there is no `dist/package.json` marker
to collide. Confirmed clean at the same date.

---

## `macleanup` (root) — runtime dependencies

**None.** This is deliberate and is a feature of the product: the published package is plain bash (an entry script and its `lib/` modules)
plus a ~100-line Node launcher, so `npx macleanup` installs nothing transitively and there is no supply chain to
audit beyond npm itself.

### devDependencies

**None.** The gates are shell and Node built-ins (`bash -n`, `node -c`), so no tooling is installed.

### Intentional metadata pins

| Field | Value | Why |
|---|---|---|
| `engines.node` | `>=14` | The launcher uses only ES2015-era syntax and `child_process`. **Not currently exercised on Node 14** — see `REPORTED-ISSUES.md` ISSUE-003. Raising this floor is a breaking change, so it stays until it is deliberately majored. |
| `os` | `["darwin"]` | The tool is macOS-only and enforces Darwin at runtime. npm refuses to install it elsewhere, which is the correct failure. |
| `cpu` | `["x64", "arm64"]` | Apple Silicon and Intel. |
| `preferGlobal` | `true` | Legacy npm hint; harmless, retained. It only produces a warning if a user installs the CLI as a local dependency. |
| `publishConfig.access` | `public` | Redundant for an unscoped package (public is already the default) but explicit, and correct. Retained so the intent survives if the package is ever scoped. |
| `sideEffects` | *absent* | Deliberately **not** set. `sideEffects: false` is a bundler tree-shaking hint and would be actively false here — the entry point spawns a process. |

### Published files

`files` is an allowlist (there is no `.npmignore`, and there must never be one):

```
bin/  macleanup.sh  README.md  LICENSE.md  CHANGELOG.md  SECURITY.md
```

`CHANGELOG.md` is listed explicitly. npm does **not** include it automatically, so omitting it would ship
installed copies with no history. Verified present in the extracted tarball 2026-07-25.

`docs/`, `desktop/`, `assets/`, `CLAUDE.md` and `AGENTS.md` are all excluded by omission.

---

## `macleanup-desktop`

A Tauri + React + Vite application. It reimplements no cleanup logic — it runs the bundled `macleanup.sh`
in `--json` mode and renders the stream. It is **not** published to npm and is not part of the CLI's
dependency surface; its manifest is listed here only so the inventory is complete.

Its own dependencies are managed inside `desktop/` and are out of scope for the published package.

---

## Adding a dependency

The root package's zero-dependency property is a documented promise in the README. Adding a runtime dependency
to it is a product decision, not a routine one — it changes what `npx macleanup` pulls onto a user's machine.
Prefer a bash or Node built-in.
