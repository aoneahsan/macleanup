# `--json-events` — the macleanup event stream

Last Updated: 2026-10-30 · Schema version: **1** · Since: macleanup 5.1.0

`--json-events` turns a run into a stream of newline-delimited JSON (NDJSON) on **stdout**, one event per line. Every human line, prompt and log line goes to stderr. The macleanup desktop app reads this stream. Scripts and CI can read it too.

```bash
npx macleanup --dry-run --all --json-events
npx macleanup --only 3,5,23 --yes --json-events 2>/dev/null | jq -c 'select(.type=="section_result")'
```

`--json-events` implies `--quiet`. It cannot be combined with `--json`, which still prints one summary object at the end. The flags are mutually exclusive, and passing both exits with code 2.

## Envelope

Every event carries the same three fields:

| Field | Type | Meaning |
|---|---|---|
| `v` | integer | Schema version. It is `1` for this document. A consumer refuses a higher major version it does not know. |
| `type` | string | One of the event types below. |
| `ts` | integer | Unix time in milliseconds when the event was written. |

Consumers must ignore fields they do not know, because additive fields do not bump `v`.

## Event types, in stream order

| `type` | When | Fields |
|---|---|---|
| `plan` | once, first | `version` (CLI version), `dry_run` (bool), `profile` (string or null), `sections` — array of `{id, title, stamp, sudo, deep}` |
| `disk` | after `plan`, and again before `summary` | `phase` (`"before"` or `"after"`), `total_kb`, `free_kb`, `purgeable_kb` (null when unknown), `snapshots` (count of local APFS snapshots), `snapshot_note` (bool: true when snapshots may hold freed space) |
| `section_start` | each section | `id`, `title`, `stamp` |
| `item` | each path a section would touch (dry run) or touched (real run) | `id` (section), `path`, `kb`, `action` (`"delete"`, `"trash"`, `"archive"`, `"report"`, `"skip"`), `unique` (bool: user data with no other copy, which needs a keep/archive/delete choice) |
| `progress` | while a section works through items | `id`, `done`, `total` (null when unknown) |
| `section_result` | each section, after its last `item` | `id`, `status` (`"completed"`, `"skipped"`, `"failed"`), `freed_kb`, `items` (count), `reason` (string or null; required for `skipped` and `failed`) |
| `error` | a non-fatal problem | `id` (section or null), `message` |
| `summary` | once, last | `attempted` (ids), `completed` (ids), `skipped` (ids), `failed` (ids), `freed_kb`, `disk_free_before_kb`, `disk_free_after_kb`, `elapsed_s`, `reports` (paths), `log` (path), `dry_run` (bool) |

`stamp` is the section's recovery tier, the same four the docs' "What gets deleted" page and the desktop app use: `"routine"` (caches and logs the system or the tool rebuilds), `"trash"` (moved to the Trash, recoverable until you empty it), `"permanent"` (removed for good; only your own backup brings it back) or `"read"` (reads and reports, changes no files).

`sudo` is true for sections that ask for an administrator password (6, 7, 11, 13, 14, 20, 25). `deep` is true for the sections a non-interactive run refuses without `--i-understand-deep` (6, 10, 11, 14, 21, 24).

A section id is an integer from 0 to 27. `title` is the same text `--list` prints.

## Guarantees

- `plan` is the first line and `summary` is the last. A stream that ends without `summary` means the process was interrupted. The consumer then treats every section without a `section_result` as `failed`, with reason `"interrupted"`.
- In a dry run, `item.action` is what *would* happen. Nothing is changed, and `freed_kb` is the estimate the section prints today.
- Paths appear only in this local stream, the local log and the local report. macleanup sends nothing anywhere. The desktop app never uploads `path`; a synced run summary carries only section ids, byte counts, statuses and the macOS version.
- Strings are JSON-escaped (backslash, double quote and control characters).
- Deep sections (6, 10, 11, 14, 21, 24) still need `--i-understand-deep` in a non-interactive run. Without it they come back `skipped` with reason `"needs --i-understand-deep"`.
- Sections that need a password use `sudo`. A non-interactive consumer sets `MACLEANUP_ASKPASS` to an executable askpass helper (the desktop app does); the script then routes `sudo` through it. Without one, those sections come back `skipped` with reason `"needs administrator password"`.
- `--json-events` needs a non-interactive selection (`--only`, `--profile` or `--all`). Without one it exits with code 2.

## Exit codes

With `--json-events`: `0` — the run finished, even if some sections were skipped · `1` — at least one section failed · `2` — invalid arguments · `130` — interrupted. Without it, exit codes are unchanged from 5.0.0.
