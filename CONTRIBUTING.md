# Contributing to mac-cleanup

Thank you for considering a contribution! Before you spend time on a
patch, please read this short note — `mac-cleanup` ships under the
**MIT** license (see [LICENSE.md](LICENSE.md)) and this covers how
contributions are handled.

## What contributions look like

- **Bug reports**, **regression reports**, and **macOS-version-specific
  feedback** are very welcome via GitHub issues.
- **Feature requests** are welcome — describe the use case, not just the
  implementation. Real workflows beat speculative options.
- **Pull requests** are welcome but **acceptance is at the author's sole
  discretion**. PRs that materially change behaviour need an issue
  discussion first.
- **Documentation tweaks** (typos, clarifications, real-world examples
  for the README) are the easiest contributions to land.

## What contributions are NOT

- A blanket "open governance" promise. This is a single-author project
  and will remain so. (The MIT license means you're always free to fork
  and take it in your own direction — but this repo stays author-led.)

## Pull-request guidelines

1. **One concern per PR.** A new section, a flag, a docs edit — pick
   one. Smaller PRs land faster.
2. **Keep the script self-contained.** No external dependencies, no
   sourcing of helper files, no language other than bash 3.2+
   compatible.
3. **Defaults must remain safe.** Anything destructive must:
   - confirm by default,
   - honour `--dry-run`,
   - not run as part of `--all` unless it's strictly cache/log/report.
4. **Style.** Two-space indent, `local` for every function-scoped var,
   `#` headers for sections, lower_snake_case function names, ANSI
   colours via the existing `RED`/`GREEN`/`…` variables.
5. **Test.** At minimum `bash -n mac-cleanup.sh` and run the new
   section with `--dry-run`. If you touch a helper used widely, smoke
   the safe batch.
6. **Author block.** Don't add new top-level author names — but you may
   add yourself in the matching CHANGELOG entry.

## License grant for accepted contributions

By submitting a PR you agree that:

- The contribution is yours to license, or you have permission from the
  rights holder to submit it.
- Once merged, the contribution falls under the same **MIT** license as
  the rest of the project.
- The author may use, modify, sublicense, or remove your contribution
  without further compensation or attribution beyond an entry in
  CHANGELOG.md.

## Commit style

```
section 23: stop pruning .gradle when scan root is ~/Documents

Fixes false-positive on user reports of missing build outputs after
a clean. Excludes ~/Library and the well-known per-user cache roots
explicitly via -path predicates.
```

Subject ≤72 chars, imperative tone, body wraps at 72 chars. Reference
issues (`Refs #12`, `Fixes #34`) where applicable.

## Code of conduct

Be patient. Be specific. Assume good faith. Ad-hominem, harassment, or
demanding behaviour gets you blocked. The author reserves the right to
close any issue or PR without explanation.

## Contact

For anything that doesn't fit GitHub:

- Email: <aoneahsan@gmail.com>
- Web: <https://aoneahsan.com>
- LinkedIn: <https://linkedin.com/in/aoneahsan>
