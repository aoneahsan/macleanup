# Build, types, and proving the entry points

## The output shape

Dual ESM + CJS, with a real declaration file for each format, and **no source maps in published output** (the
fleet rule — they expose source and bloat the tarball).

```ts
// tsup.config.ts
import { defineConfig } from 'tsup';

export default defineConfig({
  entry: ['src/index.ts', 'src/adapters/index.ts'],
  format: ['esm', 'cjs'],
  dts: true,
  sourcemap: false,   // never ship source maps
  clean: true,        // a stale dist/ is how wrong trees get published
  treeshake: true,
  target: 'node20',
});
```

`clean: true` matters more than it looks. A build that leaves yesterday's artefacts behind can publish files
no longer in the source — the failure mode the publish gate's content-regression diff exists to catch.

## tsconfig for a library

```jsonc
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "declaration": true,
    "declarationMap": false,     // ships source paths; keep off
    "sourceMap": false,
    "inlineSourceMap": false,
    "isolatedModules": true,
    "verbatimModuleSyntax": true,
    "skipLibCheck": true,
    "paths": { "@/*": ["./src/*"] }   // relative targets, no baseUrl — TS7-forward
  },
  "include": ["src"]
}
```

`typescript` stays pinned at **`~6.0.3`**. TS 7 is the native Go port and ships essentially no JS API, which
breaks `typescript-eslint` and `@capacitor/cli`. Check
`~/.claude/rules/package-version-known-issues.md` for the current state before changing it.

Dropping `baseUrl` and making `paths` relative is harmless today and required by TS 7, so do it once now.

## Proving the entry points — a repo build is not evidence

A green `yarn build` says the source compiles. It says nothing about whether the `exports` map points at
files that exist, which is what every consumer actually resolves through. Two checks, both mandatory before a
release:

### 1. Every subpath target resolves on disk

```bash
python3 - <<'PY'
import json, pathlib, sys
pkg = json.load(open('package.json'))
bad = []
def walk(node, path='exports'):
    if isinstance(node, str):
        if node.startswith('./') and not pathlib.Path(node).exists():
            bad.append(f'{path} -> {node}')
    elif isinstance(node, dict):
        for k, v in node.items():
            walk(v, f'{path}.{k}')
for f in ('exports', 'main', 'module', 'types', 'bin'):
    if f in pkg: walk(pkg[f], f)
print('BROKEN:', bad or 'none')
sys.exit(1 if bad else 0)
PY
```

### 2. Install the packed tarball and import it for real

```bash
npm pack --pack-destination /tmp/cand
mkdir -p /tmp/smoke && cd /tmp/smoke && npm init -y >/dev/null
npm i /tmp/cand/*.tgz

node -e "const m = require('<pkg>'); if (!m || !Object.keys(m).length) { throw new Error('empty CJS export'); }"
node --input-type=module -e "import * as m from '<pkg>'; if (!Object.keys(m).length) throw new Error('empty ESM export');"
```

Import **both** formats and instantiate something real — a bare `require` that returns `{}` passes a truthiness
check while being useless. For a package with a `bin`, run it with `--help` and assert exit code 0.

Test the tarball, not the repo: `npm pack` applies the `files` allowlist, so this is the first moment the
published shape actually exists.

## Peer dependencies

Anything the consuming app already owns is a peer, never a dependency — bundling a second copy of React or
`@capacitor/core` breaks singletons and context in ways that surface as impossible bugs.

```jsonc
"peerDependencies": { "react": ">=18 <20", "@capacitor/core": ">=6 <9" },
"peerDependenciesMeta": { "@capacitor/core": { "optional": true } },
"devDependencies": { "react": "^19.2.4", "@capacitor/core": "^8.0.1" }
```

- The range is **as wide as genuinely supported**, not the version you happen to build against. A narrow range
  forces consumers into upgrades they did not ask for.
- Every peer needs a matching `devDependency` or the package cannot typecheck itself.
- `optional: true` for a peer only some consumers need — otherwise everyone gets an install warning for a
  capability they never use.
- Narrowing a peer range is a **major**: it can break installs for people who changed nothing.

## Verify before handing to the publish gate

```bash
yarn typecheck && yarn lint && yarn build   # zero errors, zero warnings
```

Then the two entry-point checks above. Only then does
`aoneahsan-cccs-packages-up-to-date/references/publishing.md` take over — its content-regression diff and
tarball secret sweep assume the artefact already builds and imports.
