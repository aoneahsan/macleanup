<div align="center">
  <img src="../assets/logo/macleanup-mark.svg" width="96" alt="macleanup"/>
  <h1>macleanup — desktop app</h1>
  <p>A tiny native macOS GUI (Tauri) in front of the <code>mac-cleanup</code> CLI.</p>
</div>

A thin, native wrapper around the battle-tested `mac-cleanup.sh`. The Rust core
runs the **bundled** script in `--json` mode and streams its output to a polished
React UI. No cleanup logic is reimplemented — all 28 sections, safety rules, and
dry-run guarantees come straight from the script.

- **Tiny:** Tauri uses the macOS system WebView (no bundled Chromium) → a ~5–10 MB `.app`.
- **Safe-by-default:** dry-run preview everywhere; deep/irreversible sections gated behind explicit confirms.
- **Google sign-in + free-run gate:** 1 free run, then sign in with Google for more (Firebase Auth + Firestore).
- **Forced auto-update on launch:** checks for a newer version on start and updates before use.

---

## Prerequisites

| Tool | Why | Install |
|------|-----|---------|
| Node 18+ | frontend build + icon gen | https://nodejs.org |
| Rust (stable) | compiles the Tauri core | `curl https://sh.rustup.rs -sSf \| sh` |
| Xcode Command Line Tools | macOS linker | `xcode-select --install` |

```bash
cd desktop
npm install
```

## Develop

```bash
npm run tauri:dev      # syncs the CLI into resources, then launches the app
```

Until you add Firebase/Google config (below), the app runs in **DEV MODE**:
no sign-in required, unlimited runs — so you can use the cleanup UI immediately.

## Build a distributable

```bash
npm run tauri:build    # sync script + generate icons + build .app and .dmg
# output: src-tauri/target/release/bundle/{macos/macleanup.app, dmg/*.dmg}
```

---

## Configure Google sign-in + run-gating (Firebase)

1. **Firebase project** → create one at <https://console.firebase.google.com>.
   - Enable **Authentication → Sign-in method → Google**.
   - Create a **Firestore** database.
   - Deploy the security rules: `firebase deploy --only firestore:rules`
     (rules live in [`firebase/firestore.rules`](firebase/firestore.rules)).
2. **Google OAuth client** → in Google Cloud Console → *APIs & Services →
   Credentials* → *Create credentials → OAuth client ID* → **Desktop app**.
   Copy the **Client ID** (and, for a desktop client, the client secret — for
   installed apps this is not confidential).
3. Fill in [`src/config.ts`](src/config.ts) (the Firebase **web apiKey**,
   `projectId`, `authDomain`, and the Google **clientId**/secret). These are
   client-side values and safe to ship — **never** put a private key here.

The auth flow is PKCE + system-browser + a localhost loopback redirect (Google
forbids OAuth inside embedded webviews), exchanging the Google `id_token` for a
Firebase session via the Identity Toolkit REST API. No heavy SDK is bundled.

> The free-run limit is enforced client-side for convenience; the Firestore
> **rules** are the real server-side guard. To make limits un-bypassable, gate
> entitlement in a small backend / Cloud Function and have the app read it.

---

## Auto-update (GitHub Releases)

1. **Generate an updater key pair** (one-time):
   ```bash
   npm run tauri -- signer generate -w ~/.macleanup/updater.key
   ```
   - Put the printed **public key** into `src-tauri/tauri.conf.json` →
     `plugins.updater.pubkey` (replace `REPLACE_WITH_TAURI_UPDATER_PUBKEY`).
   - Keep the **private key** secret (e.g. a GitHub Actions secret
     `TAURI_SIGNING_PRIVATE_KEY`). **Do not commit it.**
2. **Build signed update artifacts:**
   ```bash
   export TAURI_SIGNING_PRIVATE_KEY="$(cat ~/.macleanup/updater.key)"
   export TAURI_SIGNING_PRIVATE_KEY_PASSWORD="<your password>"
   npm run tauri:build
   ```
   This emits an `.app.tar.gz` + `.sig` alongside the `.dmg`.
3. **Publish a GitHub Release** containing those artifacts plus a `latest.json`
   manifest (Tauri can generate it), at the endpoint configured in
   `tauri.conf.json`:
   `https://github.com/aoneahsan/macleanup/releases/latest/download/latest.json`.

On launch the app checks that endpoint; if a newer version exists it downloads,
installs, and relaunches **before** the app is usable. If the updater isn't
configured yet or the machine is offline, it **fails open** and launches normally.

---

## Code signing & notarization (recommended before wide distribution)

This app currently ships **unsigned**. On first launch macOS Gatekeeper will
warn "unidentified developer" — users must **right-click → Open** once (or
`System Settings → Privacy & Security → Open Anyway`).

To remove that friction (and smooth auto-update), add an Apple Developer ID:

```bash
export APPLE_SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)"
export APPLE_ID="you@example.com"
export APPLE_PASSWORD="app-specific-password"   # or APPLE_API_KEY/_ISSUER
npm run tauri:build                              # Tauri signs + notarizes
```

---

## How it fits together

```
desktop/
├─ src/                      React UI (Vite)
│  ├─ config.ts              your Firebase + Google config (fill in)
│  └─ lib/                   cli bridge · sections · auth · entitlement · updater
├─ src-tauri/                Rust core
│  ├─ src/main.rs            runs the bundled CLI (--json), streams output, OAuth loopback
│  ├─ tauri.conf.json        bundle + updater config
│  ├─ resources/             bundled copy of ../../mac-cleanup.sh (generated)
│  └─ icons/                 generated from ../assets/logo (generated)
└─ scripts/                  sync-script.mjs · gen-icons.mjs
```

The bundled `mac-cleanup.sh` is copied from the **repo root** at build time, so
the GUI and CLI always ship the same version.
