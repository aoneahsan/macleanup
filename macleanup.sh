#!/usr/bin/env bash
# =============================================================================
#  macleanup  —  comprehensive, safe-by-default macOS cleanup & maintenance.
# =============================================================================
#
#  Made by   : the macleanup team <aoneahsan@gmail.com>
#  Website   : https://macleanup.aoneahsan.com
#  Docs      : https://macleanup-docs.aoneahsan.com
#  Repo      : https://github.com/aoneahsan/macleanup
#  npm       : https://www.npmjs.com/package/macleanup
#  Copyright : (c) 2024-2026 Ahsan Mahmood <aoneahsan@gmail.com>
#  License   : MIT — free to use, copy, modify, and redistribute.
#              See LICENSE.md for full terms. AS-IS, no warranty.
#
#  One self-contained interactive bash script. Every destructive action
#  confirms before running. `--dry-run` deletes nothing but writes logs/reports.
#  Logs + reports persist at ~/.macleanup/{logs,reports}/ across runs.
#
#  Quick start
#      npx macleanup                # zero-install via npm
#      ./macleanup.sh                          # direct from a checkout
#      ./macleanup.sh --dry-run --all          # preview the safe-batch
#      ./macleanup.sh --all --yes              # unattended safe cleanup
#      ./macleanup.sh --list                   # show every section
#      ./macleanup.sh --version                # print version and exit
#
#  Requirements
#      • macOS 11 Big Sur or later (Apple Silicon or Intel)
#      • bash 3.2+ (ships with macOS by default)
#      • Node 14+ ONLY when invoked through `npx` / global npm install
#
# =============================================================================

set -uo pipefail

# The script is split into modules under lib/, sourced in order. They run exactly as
# the single file did; the split only keeps each file short enough to read.
MACLEANUP_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"
for _macleanup_module in "$MACLEANUP_LIB_DIR"/[0-9][0-9]-*.sh; do
  # shellcheck source=/dev/null
  . "$_macleanup_module" || { printf 'macleanup: could not load %s\n' "$_macleanup_module" >&2; exit 1; }
done
unset _macleanup_module

main "$@"
