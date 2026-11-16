# The `package.json` contract

A worked manifest for a TypeScript library published dual ESM + CJS. Every field is populated deliberately —
none of it is copied from a sibling without being checked.

```jsonc
{
  "name": "strata-storage",
  "version": "2.8.3",
  "description": "One storage API across web, native and Node.",
  "keywords": ["storage", "capacitor", "indexeddb", "localstorage", "sqlite", "typescript"],
  "license": "MIT",
  "author": "Ahsan Mahmood <aoneahsan@gmail.com> (https://aoneahsan.com)",

  "repository": { "type": "git", "url": "git+https://github.com/aoneahsan/strata-storage.git" },
  "homepage": "https://stratastorage-docs.aoneahsan.com",
  "bugs": { "url": "https://github.com/aoneahsan/strata-storage/issues" },
  "funding": "https://aoneahsan.com/payment?project-id=strata-storage&project-identifier=strata-storage",

  "type": "module",
  "sideEffects": false,
  "engines": { "node": ">=20.12" },

  "main": "./dist/index.cjs",
  "module": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.js",
      "require": "./dist/index.cjs"
    },
    "./adapters": {
      "types": "./dist/adapters/index.d.ts",
      "import": "./dist/adapters/index.js",
      "require": "./dist/adapters/index.cjs"
    },
    "./package.json": "./package.json"
  },

  "files": ["dist", "README.md", "LICENSE", "CHANGELOG.md", "AI-INTEGRATION-GUIDE.md"],

  "peerDependencies": { "@capacitor/core": ">=6 <9" },
  "peerDependenciesMeta": { "@capacitor/core": { "optional": true } },

  "scripts": {
    "build": "tsup",
    "typecheck": "tsc --noEmit",
    "lint": "eslint .",
    "prepublishOnly": "yarn build"
  }
}
```

## Field notes

**`repository` must resolve.** Probe it, every time:

```bash
curl -s -o /dev/null -w '%{http_code}\n' "https://api.github.com/repos/aoneahsan/<repo>"
```

`404` means npmjs.com's "Repository" link and every `bugs` link is dead for that package's users. Three of six
of the owner's package repos failed this on 2026-07-25, and `native-update` had a **documentation URL** in the
field rather than a git remote. A `repository` value is not documentation — it is where `npm repo <pkg>`,
provenance and the registry's own links point.

**`files` is an allowlist. Never `.npmignore`.** A denylist ships whatever it forgot to name — a new folder,
a stray `.env`, an internal record. If both exist, `files` wins and the `.npmignore` is dead confusion; delete
it. Note `README.md` is case-sensitive on Linux CI: a `files` entry saying `"README.md"` beside a tracked
`Readme.md` resolves on macOS and ships **nothing** elsewhere.

**`exports` replaces `main`/`module`/`types` for modern resolvers**, but keep all four so older bundlers and
`node10`-style TypeScript resolution still work. Order matters inside each subpath: `types` first, then
`import`, then `require`. Export `"./package.json"` explicitly — tooling reads it, and a strict `exports` map
otherwise forbids that.

**`sideEffects: false`** lets bundlers drop unused code from the package. It is a claim: if any module does
work at import time (registers a global, patches a prototype, installs a polyfill), the honest value is the
array form listing those files. A wrong `false` produces bugs that only appear in a consumer's production
build.

**`type: "module"`** makes `.js` ESM, so the CJS output must be `.cjs`. Get this wrong and Node throws
`ERR_REQUIRE_ESM` at consumers using `require`.

**`engines.node`** is the version actually tested, matching `.nvmrc`. Raising it is a **major** — it can break
installs for consumers who did nothing.

**`funding`** is the owner's payment link with both query parameters, per the support-links standard. Never
Open Collective, GitHub Sponsors, or any other platform.

**`prepublishOnly`** builds from the clean tree so a stale `dist/` can never be published. It is the cheapest
guard against the class of failure `strata-storage@2.8.2` belongs to.

## One manifest per package name

Before any publish:

```bash
find . -name package.json -not -path '*/node_modules/*' \
  -exec python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('version'), d.get('name'), sys.argv[1])" {} \;
```

Two entries sharing a `name` is a stop-the-line finding. `npm publish` uses the current working directory, so
the wrong `cd` ships the wrong tree — with a green typecheck, lint, build and install, because the code may be
identical while the *documentation* differs. That is precisely how `strata-storage@2.8.2` shipped without its
required `npx cap sync` instructions and stayed `latest` for 25 days.

The fix is structural, not procedural: one directory owns the name; anything else that needs to live beside it
(a marketing site, an internal twin) gets its own name and its own repo.

## Auditing an existing manifest

```bash
python3 - <<'PY'
import json, pathlib
p = json.load(open('package.json'))
required = ['name','version','description','keywords','license','author',
            'repository','homepage','bugs','funding','engines','files','exports']
missing = [f for f in required if not p.get(f)]
print('MISSING:', missing or 'none')

exports = p.get('exports', {})
targets = []
def walk(node):
    if isinstance(node, str): targets.append(node)
    elif isinstance(node, dict):
        for v in node.values(): walk(v)
walk(exports)
for t in targets:
    if t.startswith('./'):
        print(('OK   ' if pathlib.Path(t).exists() else 'BROKEN '), t)
PY
```

Run it **after** the build — before it, every `dist/` target is legitimately absent.
