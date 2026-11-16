<!--
  README TEMPLATE — aoneahsan npm packages
  Copy to the package root as README.md (UPPERCASE) and fill in.

  RULES
  1. Keep the section ORDER. Delete whole sections the package does not need; never reorder what remains.
  2. Every heading keeps its <a id> line and its emoji. The emoji is part of the section's identity.
  3. Every URL is ABSOLUTE — npm renders this file outside the repo, so relative paths are dead.
  4. One fact, one section. If it is already above, link to it instead of restating it.
  5. Delete this comment block.

  Placeholders: <PKG> npm name · <REPO> github repo · <DOCS> docs URL · <Name> display name
-->

<div align="center">

<img src="https://raw.githubusercontent.com/aoneahsan/<REPO>/main/assets/logo.svg" alt="<Name> logo" width="120" />

<h1><PKG></h1>

<p><strong>One line, under 100 characters, saying what this does for whom.</strong></p>

[![npm version](https://img.shields.io/npm/v/<PKG>.svg)](https://www.npmjs.com/package/<PKG>)
[![downloads](https://img.shields.io/npm/dm/<PKG>.svg)](https://www.npmjs.com/package/<PKG>)
[![license](https://img.shields.io/npm/l/<PKG>.svg)](https://github.com/aoneahsan/<REPO>/blob/main/LICENSE)
[![types](https://img.shields.io/npm/types/<PKG>.svg)](https://www.npmjs.com/package/<PKG>)
[![bundle size](https://img.shields.io/bundlephobia/minzip/<PKG>.svg)](https://bundlephobia.com/package/<PKG>)
[![node](https://img.shields.io/node/v/<PKG>.svg)](https://nodejs.org)

[Docs](<DOCS>) · [npm](https://www.npmjs.com/package/<PKG>) · [GitHub](https://github.com/aoneahsan/<REPO>) · [Changelog](https://github.com/aoneahsan/<REPO>/blob/main/CHANGELOG.md) · [AI Guide](https://github.com/aoneahsan/<REPO>/blob/main/AI-INTEGRATION-GUIDE.md) · [Support](https://github.com/aoneahsan/<REPO>/issues)

</div>

<!-- Only when there is a fact a user MUST know before installing. Otherwise delete. -->
> [!IMPORTANT]
> The one thing that breaks the package if it is missed — a required native sync step, a peer that must be
> installed first, a platform that is not supported yet.

Two to four sentences: what this is, who it is for, and what makes it different from the obvious
alternative. No hype, no superlatives — a developer deciding in ten seconds whether to keep reading.

| | |
|---|---|
| **Version** | `x.y.z` |
| **License** | MIT |
| **Node** | `>=20.12` |
| **Platforms** | Web · iOS · Android · Node |
| **Install size** | ~XX kB minzipped |
| **Types** | Bundled `.d.ts` (ESM + CJS) |
| **Status** | Stable · actively maintained |

<a id="table-of-contents"></a>
## 🧭 Table of Contents&nbsp;[#](#table-of-contents)

- [💡 Why \<PKG\>](#why-pkg)
- [✨ Features](#features)
- [📦 Installation](#installation)
- [🚀 Quick Start](#quick-start)
- [🛠️ Usage](#usage)
- [🔧 API Reference](#api-reference)
- [🚧 Limitations](#limitations)
- [📚 Documentation](#documentation)
- [🤝 Contributing](#contributing)
- [📄 License](#license)

<a id="why-pkg"></a>
## 💡 Why \<PKG\>&nbsp;[#](#why-pkg)

The problem this exists to solve, in a short paragraph. Then the honest comparison:

| | `<PKG>` | The usual alternative |
|---|---|---|
| … | … | … |

**Not the right tool when** — say plainly where it does not fit. A reader who leaves here because you were
honest is a bug report you never receive.

<a id="features"></a>
## ✨ Features&nbsp;[#](#features)

- **Capability** — one line on what it does for the user. No code; code lives in Usage.
- **Capability** — …

<a id="platform-support"></a>
## 📱 Platform Support&nbsp;[#](#platform-support)

| Platform | Supported | Notes |
|---|---|---|
| Web | ✅ | … |
| Android | ✅ | … |
| iOS | ⚠️ | … |
| Node | ✅ | … |

<a id="requirements"></a>
## 📋 Requirements&nbsp;[#](#requirements)

| Requirement | Version | Why |
|---|---|---|
| Node | `>=20.12` | … |
| `<peer>` | `>=6 <9` | peer — the host app owns it |

<a id="installation"></a>
## 📦 Installation&nbsp;[#](#installation)

```bash
yarn add <PKG>
```

Any post-install step goes here, and nowhere else — a native sync, a config file, a generated key.

<a id="quick-start"></a>
## 🚀 Quick Start&nbsp;[#](#quick-start)

The smallest complete example that produces a real result. One block, runnable as written.

```ts
import { thing } from '<PKG>';

const result = await thing.doIt();
```

<a id="usage"></a>
## 🛠️ Usage&nbsp;[#](#usage)

### The common task

A few lines, then the next task. Each is the shortest form that works; depth links to the docs site.

<a id="configuration"></a>
## ⚙️ Configuration&nbsp;[#](#configuration)

| Option | Type | Default | What it does |
|---|---|---|---|
| `option` | `string` | `'value'` | … |

<a id="api-reference"></a>
## 🔧 API Reference&nbsp;[#](#api-reference)

A signature index, not the full documentation. Each entry links to its page.

| Export | Signature | Docs |
|---|---|---|
| `thing.doIt` | `(opts?: Options) => Promise<Result>` | [→](<DOCS>/api/do-it) |

<a id="types"></a>
## 🧩 Types&nbsp;[#](#types)

The types a consumer actually touches.

```ts
export interface Options { /* … */ }
export type Result = { /* … */ };
```

<a id="command-line"></a>
## 💻 Command Line&nbsp;[#](#command-line)

```bash
npx <PKG> <command> [options]
```

| Command | What it does |
|---|---|
| `init` | … |

| Flag | Default | What it does |
|---|---|---|
| `--dry-run` | `false` | … |

<a id="examples"></a>
## 🧪 Examples&nbsp;[#](#examples)

| Goal | Example |
|---|---|
| … | [→](https://github.com/aoneahsan/<REPO>/tree/main/examples/…) |

<a id="advanced-features"></a>
## 🎛️ Advanced Features&nbsp;[#](#advanced-features)

- **Feature** — one line, then a link. Depth belongs on the docs site.

<a id="recovery-troubleshooting"></a>
## 🚑 Recovery & Troubleshooting&nbsp;[#](#recovery-troubleshooting)

| Symptom | Cause | Fix |
|---|---|---|
| … | … | … |

<a id="limitations"></a>
## 🚧 Limitations&nbsp;[#](#limitations)

What this does **not** do, stated as plainly as what it does.

- …

<a id="faq"></a>
## ❓ FAQ&nbsp;[#](#faq)

**Question people actually ask?**
The answer, in one or two sentences.

<a id="adopters"></a>
## 🏢 Adopters&nbsp;[#](#adopters)

Real, verifiable users only. Delete this section rather than inventing one.

<a id="documentation"></a>
## 📚 Documentation&nbsp;[#](#documentation)

Which document answers which question:

| Document | Read it when |
|---|---|
| [Getting started](<DOCS>/getting-started) | first time using the package |
| [API reference](<DOCS>/api) | you need an exact signature |
| [AI integration guide](https://github.com/aoneahsan/<REPO>/blob/main/AI-INTEGRATION-GUIDE.md) | a coding agent is implementing against it |

<a id="changelog"></a>
## 🔄 Changelog&nbsp;[#](#changelog)

Latest release: **`x.y.z`** — one line on what changed.
Full history: [CHANGELOG.md](https://github.com/aoneahsan/<REPO>/blob/main/CHANGELOG.md).

<a id="roadmap"></a>
## 🗺️ Roadmap&nbsp;[#](#roadmap)

- …

<a id="contributing"></a>
## 🤝 Contributing&nbsp;[#](#contributing)

Fork and open a pull request — see
[CONTRIBUTING.md](https://github.com/aoneahsan/<REPO>/blob/main/CONTRIBUTING.md) for setup, standards, and
how to request collaborator access. `main` is protected: every change lands through a reviewed PR.

<a id="repository"></a>
## 🗂️ Repository&nbsp;[#](#repository)

```
src/        …
dist/       build output (published)
examples/   runnable examples
```

<a id="support"></a>
## 💬 Support&nbsp;[#](#support)

Questions and bugs: [open an issue](https://github.com/aoneahsan/<REPO>/issues).

If this package saves you time, you can support its maintenance at
[aoneahsan.com/payment](https://aoneahsan.com/payment?project-id=<PKG>&project-identifier=<PKG>).

<a id="license"></a>
## 📄 License&nbsp;[#](#license)

MIT © Ahsan Mahmood — see [LICENSE](https://github.com/aoneahsan/<REPO>/blob/main/LICENSE).

<a id="author"></a>
## 👤 Author&nbsp;[#](#author)

**Ahsan Mahmood** — [aoneahsan.com](https://aoneahsan.com) · [GitHub](https://github.com/aoneahsan) ·
[LinkedIn](https://linkedin.com/in/aoneahsan) · [aoneahsan@gmail.com](mailto:aoneahsan@gmail.com)

<a id="links"></a>
## 🔗 Links&nbsp;[#](#links)

| | |
|---|---|
| Documentation | <DOCS> |
| npm | https://www.npmjs.com/package/\<PKG\> |
| Repository | https://github.com/aoneahsan/\<REPO\> |
| Issues | https://github.com/aoneahsan/\<REPO\>/issues |
| Changelog | https://github.com/aoneahsan/\<REPO\>/blob/main/CHANGELOG.md |
| Support the project | https://aoneahsan.com/payment |

<a id="keywords"></a>
## 🏷️ Keywords&nbsp;[#](#keywords)

*keyword · keyword · keyword · keyword · keyword*
