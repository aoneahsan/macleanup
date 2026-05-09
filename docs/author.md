# Author & Credits

> The complete credits page for **mac-cleanup** — who built it, why,
> how to support the project, and how to hire the author for adjacent work.

---

## About the author

<table>
  <tr>
    <td valign="top" width="160">
      <a href="https://github.com/aoneahsan">
        <img src="https://github.com/aoneahsan.png" width="140" alt="Ahsan Mahmood" style="border-radius:50%"/>
      </a>
    </td>
    <td valign="top">
      <h3 style="margin-top:0">Ahsan Mahmood</h3>
      <em>Senior software engineer · macOS power user · maker of small sharp tools</em><br/><br/>
      <strong>Ahsan Mahmood</strong> is the sole author and maintainer of <strong>mac-cleanup</strong>.
      He's a senior engineer with deep experience across mobile, web, and
      developer tooling — Capacitor, React, Flutter, TypeScript,
      Node.js, Firebase, and the macOS / iOS toolchain.
      <br/><br/>
      mac-cleanup grew out of years of reclaiming gigabytes from his own
      developer machines and the realisation that <em>most cleanup tools
      either delete too aggressively (and break things) or do too little
      (and leave gigabytes of cruft).</em> mac-cleanup sits in the
      middle: safe by default, transparent about what it touches, and
      auditable line-by-line.
    </td>
  </tr>
</table>

### Where to find Ahsan online

| Platform | Link |
|---|---|
| 🌐 **Website** | <https://aoneahsan.com> |
| 💼 **LinkedIn** | <https://linkedin.com/in/aoneahsan> |
| 🐙 **GitHub** | <https://github.com/aoneahsan> |
| 📦 **npm** | <https://www.npmjs.com/~aoneahsan> |
| 📧 **Email** | <aoneahsan@gmail.com> |
| 📱 **Phone (WhatsApp / Signal)** | +92 304 6619706 |

If a link in this documentation set appears as **"Ahsan Mahmood"**, it
points back to this page (or directly to <https://aoneahsan.com>).

---

## Why mac-cleanup exists

There are three categories of macOS cleanup software in the wild today:

1. **Paid GUI apps** — CleanMyMac, MacCleaner Pro, Sensei, etc. Polished
   UIs. Subscription pricing. Often delete too aggressively, sometimes
   on autopilot, and you can't audit the source.
2. **One-shot blog posts** — `rm -rf ~/Library/Caches` style. Free.
   Often catastrophic on Apple-managed paths or actively-used directories.
   No safety nets.
3. **Tiny CLI gists** — single-purpose, single-author, undocumented,
   unmaintained. Often broken on the latest macOS release.

`mac-cleanup` was written to fill the middle:

- **Free** like the gists.
- **Auditable** like the gists (~3,000 lines of plain bash, two files).
- **Safe-by-default** like the paid apps (every destructive op confirms,
  every section can be previewed via `--dry-run`).
- **Comprehensive** like the paid apps (27 targeted sections).
- **No telemetry, no network calls, no upsells** — unlike either.

Read the [README](../README.md) "Why mac-cleanup" comparison table for
the side-by-side.

---

## Project history

| Date | Milestone |
|---|---|
| 2024 | First internal version — single bash script for personal use. |
| Early 2026 | Modular split into per-section files for maintainability. |
| 2026-04 | **v4.0.0** — re-bundled into a single self-contained file. |
| 2026-05 | **v4.1.0** — sections 23/24/25/26 added. `--scan-roots`, `--list`, `--version`. |
| 2026-05 | **v4.2.0** — `npx macleanup` zero-install via Node launcher. Persistent logs/reports moved to `~/.mac-cleanup/{logs,reports}/`. Branding header in every artefact. |
| 2026-05 | **v4.3.0** — `--profile`, `--exclude`, `--notify`, `--check-update`, `--brew-autoremove` added. (Section 23 incident — see [Recovery Guide](recovery-guide.md).) |
| 2026-05 | **v4.3.1** — SAFETY FIX: `CRITICAL_HOME_DIRS` allowlist; `brew autoremove` made opt-in; no silent `$HOME` fallback. |
| 2026-05 | **v4.3.2** — age-aware cache pruning (`--cache-age-days`, default 100). |
| 2026-05 | **v4.3.3** — universal two-condition rule for non-cache deletes (`--idle-days`, default 100). |
| 2026-05 | **v4.4.0** — `--feedback`, `--report-issue`, `--stats`, `--contact`, crash hint, branded welcome screen. |

See [CHANGELOG.md](../CHANGELOG.md) for the full per-version detail.

---

## How to support the project

mac-cleanup is **free**. There is no paid tier, no upsell, no
"professional edition." If it saves you time or disk, here are five
ways to give back, in increasing order of effort:

### 1. ⭐ Star the repo

The single highest-leverage action you can take in 3 seconds:

> [**github.com/aoneahsan/macleanup**](https://github.com/aoneahsan/macleanup)

GitHub stars are the project's social proof. The more stars, the more
developers find it via search and "trending tools" lists.

### 2. 🐦 Share it with a fellow Mac developer

Post it in your team Slack, your tech-Twitter circle, your dev WhatsApp
group, or your favourite subreddit. A 10-word recommendation from a
trusted friend beats every search-engine result.

Suggested copy you can copy-paste:

> "Just used [mac-cleanup](https://github.com/aoneahsan/macleanup) to
> reclaim 28 GB on my Mac in 5 minutes. Single bash file, `--dry-run`
> first, `npx macleanup` to try. Built by [Ahsan Mahmood](https://github.com/aoneahsan)."

### 3. 💬 Send feedback

```bash
mac-cleanup --feedback
```

Opens your mail client with a prefilled message. Tell Ahsan what
worked, what didn't, what you'd like added. Real user stories shape
the next release more than any GitHub stars do.

### 4. 🐛 Report bugs (or fix one)

```bash
mac-cleanup --report-issue
```

Pre-filled GitHub issue with your environment info. Or open a pull
request — see [CONTRIBUTING.md](../CONTRIBUTING.md). Acceptance is at
the author's discretion (it's a single-file project where consistency
matters), but proposals are always welcome.

### 5. 💼 Hire Ahsan for adjacent work

Ahsan takes consulting and contract engagements in:

- **Mobile development** — Capacitor, React Native, Flutter, native iOS/Android
- **Frontend development** — React, Next.js, TypeScript, Tailwind, design systems
- **Full-stack** — Node.js, Firebase, Supabase, Cloudflare, REST/GraphQL APIs
- **Developer tooling** — CLIs, automation, IDE extensions, build pipelines
- **Architecture & code review** — for teams scaling fast or rebuilding
- **Technical writing** — docs that engineers actually read

Get in touch at [aoneahsan.com](https://aoneahsan.com) or directly at
<aoneahsan@gmail.com>. Mention you found him via mac-cleanup — it
helps him understand which projects are bringing in opportunities.

---

## Other projects by Ahsan

Ahsan's GitHub is at [github.com/aoneahsan](https://github.com/aoneahsan).
A non-exhaustive sample of his other open work:

- Mobile-first **Capacitor plugins** (push notifications, in-app
  purchases, deep linking, splash screens, performance utilities).
- **TypeScript libraries** for state management, routing helpers, and
  React component patterns.
- **Bash and Node CLI tooling** for daily-use developer workflows.
- **Reference implementations** for Firebase auth, Firestore security
  rules, and Cloudflare Workers patterns.

Browse his pinned and most-starred repositories at
<https://github.com/aoneahsan?tab=repositories>.

---

## Tech credits

`mac-cleanup` is built on the shoulders of these well-maintained tools
and standards. Where the script invokes them, it does so directly via
the system or PATH.

| Tool | Used for | License |
|---|---|---|
| **bash** (3.2+) | The entire script | GPL-3.0 (system component) |
| **macOS** | The platform | proprietary |
| **Node.js** (14+) | The `npx` launcher only | MIT |
| **`xcrun` / `simctl`** | Section 1 simulator cleanup | proprietary (Apple) |
| **`tmutil`** | Section 11 Time Machine snapshot management | proprietary (Apple) |
| **`launchctl` / `plutil`** | Section 25 LaunchAgents audit | proprietary (Apple) |
| **`osascript`** | Trash move + macOS notifications | proprietary (Apple) |
| **`docker`** | Section 4 (only if installed) | Apache-2.0 (Docker, Inc.) |
| **`brew`** | Section 3 (only if installed) | BSD-2-Clause |
| **`npm` / `yarn` / `pnpm` / `pip` / `pod` / `cargo` / `go` / `gem`** | Section 3 (only if installed) | various open source |

No third-party libraries are bundled or required. The package's
`dependencies` field in `package.json` is empty.

---

## Documentation credits

This documentation set was written by **Ahsan Mahmood** with editorial
collaboration from Claude (Anthropic) for structure and copywriting
polish. Every claim about the tool's behaviour was verified against the
script source for accuracy.

If you find a documentation error, please open an issue or send a PR
against the [`docs/` folder](https://github.com/aoneahsan/macleanup/tree/main/docs).

---

## Citation

If you reference `mac-cleanup` in a blog post, a conference talk, an
internal wiki, or a paper, a one-line credit is appreciated:

> `mac-cleanup` — comprehensive, safe-by-default macOS cleanup tool by
> Ahsan Mahmood (<https://github.com/aoneahsan/macleanup>).

A BibTeX-friendly form:

```bibtex
@misc{mac_cleanup_2026,
  author       = {Ahsan Mahmood},
  title        = {mac-cleanup: A safe-by-default macOS cleanup and maintenance tool},
  year         = {2026},
  url          = {https://github.com/aoneahsan/macleanup},
  note         = {Source-available, version 4.4.0}
}
```

---

## License

`mac-cleanup` is released under the **Source-Available License v1.0**.
You may **read** and **run** the tool on your own machines for personal
or internal-business use. You may **not** modify, redistribute, or
sell it. The author offers it AS-IS with no warranty and is not liable
for any data loss or damage.

Full terms: [LICENSE.md](../LICENSE.md). Notice file: [NOTICE](../NOTICE).

---

## Get in touch

### Direct contact

| Channel | Link |
|---|---|
| Website | <https://aoneahsan.com> |
| LinkedIn | <https://linkedin.com/in/aoneahsan> |
| GitHub | <https://github.com/aoneahsan> |
| Email | <aoneahsan@gmail.com> |
| WhatsApp / Signal | +92 304 6619706 |

### From inside the tool

```bash
mac-cleanup --contact         # the author contact card
mac-cleanup --feedback        # open mail client with prefilled message
mac-cleanup --report-issue    # open a pre-filled GitHub issue
mac-cleanup --stats           # show your run history at ~/.mac-cleanup
```

All of those collect environment info **locally only**. Nothing is
auto-sent until you explicitly Submit / Send.

---

## Thank you

If you've made it this far in the documentation: **thank you for caring
about the details**. mac-cleanup was built for people who read the
script before running it — that's the audience this tool deserves.

If it reclaimed gigabytes for you and saved you the cost of a
subscription cleaner app, the kindest thank-you is a ⭐ on the
[GitHub repo](https://github.com/aoneahsan/macleanup) and a share with
one fellow Mac developer.

— *Ahsan Mahmood*<br/>
&nbsp;&nbsp;&nbsp;&nbsp;[aoneahsan.com](https://aoneahsan.com) · [linkedin.com/in/aoneahsan](https://linkedin.com/in/aoneahsan) · [github.com/aoneahsan](https://github.com/aoneahsan)

---

## See also

- [Documentation index](README.md)
- [Project README](../README.md)
- [LICENSE.md](../LICENSE.md)
- [CHANGELOG.md](../CHANGELOG.md)
- [SECURITY.md](../SECURITY.md)
- [CONTRIBUTING.md](../CONTRIBUTING.md)

---

_Author & credits page for **mac-cleanup** v4.4.0._
