# The repo around the package — governance, docs, changelog, tarball hygiene

## Files at the package root

| File | Required | Ships in the tarball |
|---|---|---|
| `README.md` | ✅ | ✅ |
| `LICENSE` (no extension) | ✅ | ✅ |
| `CHANGELOG.md` | ✅ | ✅ |
| `CONTRIBUTING.md` | ✅ public repos | ❌ |
| `AI-INTEGRATION-GUIDE.md` | when consumers are agents | ✅ |
| `SECURITY.md` | when the package handles auth/crypto/secrets | ❌ |
| `CLAUDE.md` / `AGENTS.md` | ✅ | ❌ **never** |
| `docs/PACKAGES.md` | ✅ | ❌ |

**Banned outright:** `IMPLEMENTATION_COMPLETE.md`, `RELEASE_READY.md`, `VALIDATION_COMPLETE.md` and every
other banner status file. They are the "useless documentation" the global rule forbids — they record a moment,
go stale immediately, and tell a reader nothing. `unified-tracking` carries three of them today.

## The tarball is public forever

Verify against the **extracted tarball**, never the repo — the `files` allowlist is the only thing that
decides what ships, and reading the repo tells you what you *hoped* would ship.

```bash
npm pack --pack-destination /tmp/cand
tar -tzf /tmp/cand/*.tgz | sed 's|^package/||' | sort

cd /tmp && rm -rf ins && mkdir ins && tar -xzf /tmp/cand/*.tgz -C ins
cd ins/package

# nothing internal or secret
find . -type f | grep -iE '\.env|secret|credential|serviceaccount|\.pem$|\.jks$|\.p8$|npmrc|CLAUDE\.md|AGENTS\.md'
grep -rlE "npm_[A-Za-z0-9]{30,}|BEGIN (RSA|EC|OPENSSH) PRIVATE KEY|AIza[0-9A-Za-z_-]{30,}" .
```

Both commands must return nothing. Unpublishing is not a remedy — a leaked key in a published tarball is
public and mirrored, and the only real response is to rotate the secret.

## `CHANGELOG.md`

Keep a Changelog format, newest first, one entry per **published** version. It is the single source the
README's Changelog section and any docs-site release page read from — never a second hand-maintained copy.

```markdown
## [2.8.3] - 2026-06-30

### Fixed
- Restored the `npx cap sync` native-setup step dropped from the bundled docs in 2.8.2.

### Deprecated
- `2.8.2` is deprecated on the registry: its docs omit the required native-setup step.
```

A version on npm with no changelog entry is a release nobody can explain. When a release is deprecated, the
reason goes in that version's entry too, so it survives outside the registry.

## `AI-INTEGRATION-GUIDE.md`

Eight of the owner's fourteen packages ship one, and it earns its place: coding agents are a real consumer,
and they need different material from a human. Written **for an agent implementing against the package** —
complete runnable examples over prose, every import path spelled out, the error shapes it will hit, and the
constraints it must not violate. Kept in `files` so it travels inside the tarball, where an agent reading
`node_modules` will find it.

## Public-repo governance

Every public package repo carries:

- a root `CONTRIBUTING.md` — how to fork and PR, how to request collaborator access, and that write access
  still cannot push to `main`;
- **Issues enabled**, with `bugs.url` pointing at `/issues`;
- a `main` **ruleset**: PR required, ≥1 approving review, CI status check, no force-push, no deletion, and
  **bypass limited to Repository admin** so the owner can maintain `main` directly and nobody else can;
- support links to `aoneahsan.com/payment` only — never Open Collective or GitHub Sponsors.

Full law, including the exact ruleset JSON and `gh` commands:
`~/.claude/rules/public-repo-governance.md` when present on this machine.

🔴 **A public repo takes no secrets, ever** — only `.env.example` with placeholder values. Sweep before every
commit:

```bash
git ls-files | grep -iE '(^|/)\.env$|\.env\.|secret|credential|serviceaccount|\.pem$|\.jks$|\.keystore$|\.p8$|\.npmrc'
```

## The docs-target ladder

Resolve in order and stop at the first that exists:

| Rung | Target | Then |
|---|---|---|
| 1 | a public **docs site** for the package | `homepage` → it; README links deep into it |
| 2 | its public **GitHub repo** | README links to `/blob/main/docs/...` |
| 3 | a **marketing site** containing real docs | link the docs section, not the landing page |
| 4 | none exist | **build a docs site** — `<npm-name>-docs.aoneahsan.com` |

Rung 4 is an owner decision from 2026-07-25: a public repo on GitHub Pages, built per
`aoneahsan-cccs-docusaurus`, with the DNS record recorded as an owner-only row in `docs/MANUAL-TASKS.md` so
the work is never blocked waiting on it. When the package already has a marketing site, the docs domain is
derived from **that** site's real deployed domain, not from the package name.

**Probe every URL before it is written into a README:**

```bash
for u in https://<docs> https://github.com/aoneahsan/<repo>; do
  printf '%s -> ' "$u"; curl -s -o /dev/null -w '%{http_code}\n' -m 8 "$u"
done
```

`000` means the host does not resolve and whatever source named it is wrong — fix that source in the same
pass. Written sources agreeing with each other proves nothing; only the probe distinguishes a real host from a
copied typo.
