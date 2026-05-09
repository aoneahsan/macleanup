#!/usr/bin/env bash
# =============================================================================
#  mac-cleanup  —  comprehensive, safe-by-default macOS cleanup & maintenance.
# =============================================================================
#
#  Author    : Ahsan Mahmood  <aoneahsan@gmail.com>
#  Website   : https://aoneahsan.com
#  LinkedIn  : https://linkedin.com/in/aoneahsan
#  GitHub    : https://github.com/aoneahsan
#  Repo      : https://github.com/aoneahsan/macleanup
#  npm       : https://www.npmjs.com/package/macleanup
#  Copyright : (c) 2024-2026 Ahsan Mahmood. All rights reserved.
#  License   : Source-available, personal & non-commercial use only.
#              No modification, no redistribution, no resale.
#              See LICENSE.md for full terms. AS-IS, no warranty.
#
#  One self-contained interactive bash script. Every destructive action
#  confirms before running. `--dry-run` reports without touching disk.
#  Logs + reports persist at ~/.mac-cleanup/{logs,reports}/ across runs.
#
#  Quick start
#      npx macleanup                # zero-install via npm
#      ./mac-cleanup.sh                          # direct from a checkout
#      ./mac-cleanup.sh --dry-run --all          # preview the safe-batch
#      ./mac-cleanup.sh --all --yes              # unattended safe cleanup
#      ./mac-cleanup.sh --list                   # show every section
#      ./mac-cleanup.sh --version                # print version and exit
#
#  Requirements
#      • macOS 11 Big Sur or later (Apple Silicon or Intel)
#      • bash 3.2+ (ships with macOS by default)
#      • Node 14+ ONLY when invoked through `npx` / global npm install
#
# =============================================================================

set -uo pipefail

# ── runtime preflight ────────────────────────────────────────────────────
if [[ "$(uname -s 2>/dev/null)" != "Darwin" ]]; then
  printf 'mac-cleanup: this tool only runs on macOS (Darwin). Detected: %s\n' \
    "$(uname -s 2>/dev/null || echo unknown)" >&2
  exit 1
fi
if [[ -z "${BASH_VERSINFO+set}" ]] \
   || (( BASH_VERSINFO[0] < 3 )) \
   || (( BASH_VERSINFO[0] == 3 && BASH_VERSINFO[1] < 2 )); then
  printf 'mac-cleanup: bash 3.2+ required. Detected: %s\n' "${BASH_VERSION:-unknown}" >&2
  exit 1
fi

# ──────────────────────────────────────────────────────────────────────────
#                                CONSTANTS
# ──────────────────────────────────────────────────────────────────────────
SCRIPT_VERSION="4.3.3"
SCRIPT_NAME="mac-cleanup"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TODAY="$(date +%Y-%m-%d)"
RUN_TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S %Z')"

# ── Author / branding constants — embedded in every log + report ──────────
AUTHOR_NAME="Ahsan Mahmood"
AUTHOR_EMAIL="aoneahsan@gmail.com"
AUTHOR_WEBSITE="https://aoneahsan.com"
AUTHOR_LINKEDIN="https://linkedin.com/in/aoneahsan"
AUTHOR_GITHUB="https://github.com/aoneahsan"
PROJECT_REPO="https://github.com/aoneahsan/macleanup"
PROJECT_NPM="https://www.npmjs.com/package/macleanup"
PROJECT_NPM_INSTALL="npx macleanup"

# ── Persistent runtime directories (survive npx cache cleanup) ────────────
# Default to $HOME/.mac-cleanup/{logs,reports} so reports + history are
# stable regardless of whether the script ran from a git checkout, an
# /opt install, or `npx macleanup`. Both paths can be
# overridden via --logs-dir / --reports-dir or environment variables.
DEFAULT_DATA_DIR="$HOME/.mac-cleanup"
LOG_DIR="${MAC_CLEANUP_LOGS_DIR:-$DEFAULT_DATA_DIR/logs}"
REPORTS_DIR="${MAC_CLEANUP_REPORTS_DIR:-$DEFAULT_DATA_DIR/reports}"
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}-${TODAY}.log"
ORPHAN_REPORT="${REPORTS_DIR}/orphans-${TODAY}.txt"
UNUSED_APPS_REPORT="${REPORTS_DIR}/unused-apps-${TODAY}.txt"
LARGE_FILES_REPORT="${REPORTS_DIR}/large-files-${TODAY}.txt"
STALE_BUILD_REPORT="${REPORTS_DIR}/stale-build-${TODAY}.txt"
LARGE_STALE_REPORT="${REPORTS_DIR}/large-stale-${TODAY}.txt"
LAUNCH_AUDIT_REPORT="${REPORTS_DIR}/launch-audit-${TODAY}.txt"
DU_REPORT="${REPORTS_DIR}/disk-usage-${TODAY}.txt"

UNUSED_APP_THRESHOLD_DAYS_DEFAULT=100
STALE_BUILD_THRESHOLD_DAYS_DEFAULT=100
LARGE_FILE_THRESHOLD_DAYS_DEFAULT=100
LARGE_FILE_SIZE_GB_DEFAULT=1
# Age threshold (days) for cache pruning in sections 1, 2, 3.
# Any file whose atime AND mtime are both ≥ this many days old is
# considered unused and may be removed. Files actively in use keep
# recent atime, so they survive every pass even if they were
# downloaded long ago. Use 0 for a full wipe (old behaviour).
CACHE_AGE_DAYS_DEFAULT=100
# Universal idle threshold for non-cache deletes (sections 12, 23 et al).
# Per the 4.3.3 safety rule: any uninstall/delete of software/tools/data
# (not pure cache) must satisfy BOTH conditions —
#   (a) not used by any active software/tool, and
#   (b) not touched by the user (atime+mtime) for ≥ this many days.
IDLE_THRESHOLD_DAYS_DEFAULT=100

# Regenerable dev artefact directory names. Each can be rebuilt by re-running
# the project's install/build, so deleting them is non-destructive provided
# the developer hasn't been actively working in that tree.
STALE_BUILD_PATTERNS=(
  node_modules vendor dist build out
  .next .nuxt .turbo .vite .parcel-cache .svelte-kit .astro
  target Pods coverage .nyc_output
)
# IMPORTANT: `.cache` was removed from STALE_BUILD_PATTERNS in 4.3.1.
# It matched ~/.cache and any project-internal `.cache/` directory
# indiscriminately, including critical tool state. Per-tool cache cleaning
# is now strictly the job of section 3.

# CRITICAL_HOME_DIRS — toolchain managers, language runtimes, secret
# stores, IDE state, OS-level caches. NEVER entered by section 23,
# NEVER deleted by any helper, regardless of mtime, regardless of
# whether their basename matches a STALE_BUILD_PATTERNS entry.
#
# This list is the safety contract that prevents the 4.3.0 bug where
# section 23 could nuke node_modules deep inside ~/.bun, ~/.local,
# ~/.pnpm-store etc. — breaking every globally installed tool.
CRITICAL_HOME_DIRS=(
  # Node version + package managers
  .nvm .fnm .n .tnvm .volta .asdf
  .npm .npm-packages .yarn .pnpm-store .pnpm
  # Other language runtimes
  .bun .deno .rbenv .pyenv .rustup .rye .ruby
  .cargo .gradle .m2 .sbt .ivy2
  .pub-cache .cocoapods
  # OS / tool caches & config
  .cache .config .docker .android .dartServer
  # Editors / IDEs / AI agents (state)
  .vscode .vscode-server .cursor .cursor-server
  .idea .nvim .vim .emacs.d
  .claude .codex .agents .ollama
  # Secrets / credentials — never touch
  .ssh .gnupg .aws .azure .gcloud .kube .terraform.d
  .password-store .1password .keepass
  # Shell + git
  .oh-my-zsh .git
)

# Filesystem allowlists for non-Apple bundle ID prefixes that we *do not*
# treat as orphan candidates even if no installed bundle matches them
# (these get auto-recreated, are part of macOS, or belong to system tooling).
APPLE_PREFIXES=("com.apple." "com.apple-samplecode." "apple." "com.Apple.")

mkdir -p "$LOG_DIR" "$REPORTS_DIR" 2>/dev/null || true

# ──────────────────────────────────────────────────────────────────────────
#                                COLORS
# ──────────────────────────────────────────────────────────────────────────
if [[ -t 1 && -n "${TERM:-}" && "${TERM}" != "dumb" ]]; then
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'
  BLUE=$'\033[34m'; CYAN=$'\033[36m'; MAGENTA=$'\033[35m'
  BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""; MAGENTA=""; BOLD=""; DIM=""; NC=""
fi

# ──────────────────────────────────────────────────────────────────────────
#                                STATE
# ──────────────────────────────────────────────────────────────────────────
DRY_RUN=0          # --dry-run
RUN_ALL=0          # --all
BATCH_MODE=0       # implied by --all / --only
ASSUME_YES=0       # --yes / -y
NO_SUDO=0          # --no-sudo
QUIET=0            # --quiet
ONLY_SECTIONS=""   # --only "0,3,5,21"
UNUSED_APP_THRESHOLD_DAYS="$UNUSED_APP_THRESHOLD_DAYS_DEFAULT"
STALE_BUILD_THRESHOLD_DAYS="$STALE_BUILD_THRESHOLD_DAYS_DEFAULT"
LARGE_FILE_THRESHOLD_DAYS="$LARGE_FILE_THRESHOLD_DAYS_DEFAULT"
LARGE_FILE_SIZE_GB="$LARGE_FILE_SIZE_GB_DEFAULT"
SCAN_ROOTS_OVERRIDE=""  # --scan-roots "p1:p2:p3"
NO_REPORTS=0       # --no-reports (skip writing report .txt files)
CLEANUP_LOGS_ON_FINISH=0  # --cleanup-logs-on-finish
EXCLUDE_SECTIONS=""  # --exclude "14,17"
PROFILE_NAME=""    # --profile dev|minimal|cache-only|deep|audit
NOTIFY=0           # --notify (macOS notification on completion)
CHECK_UPDATE=0     # --check-update (query npm for latest)
BREW_AUTOREMOVE=0  # --brew-autoremove (opt-in; removes "unused" formulae)
CACHE_AGE_DAYS="$CACHE_AGE_DAYS_DEFAULT"  # --cache-age-days N
IDLE_THRESHOLD_DAYS="$IDLE_THRESHOLD_DAYS_DEFAULT"  # --idle-days N (sections 12, 23)

TOTAL_FREED_KB=0
DISK_FREE_BEFORE_KB=""
DISK_FREE_AFTER_KB=""
START_EPOCH="$(date +%s)"
COMPLETED_SECTIONS=()
TMPFILES=()

_cleanup_temps() {
  local f
  for f in "${TMPFILES[@]+"${TMPFILES[@]}"}"; do
    [[ -n "$f" && -e "$f" ]] && rm -f "$f" 2>/dev/null || true
  done
  # Honour --cleanup-logs-on-finish here in the trap so it fires for every
  # exit path (interactive Q, --all, --only, signal, error) — moving this
  # to the bottom of main() missed the early `return 0` paths.
  # Reports always persist; only this run's log is removed.
  if [[ "${CLEANUP_LOGS_ON_FINISH:-0}" == "1" ]] && [[ -f "${LOG_FILE:-}" ]]; then
    rm -f -- "$LOG_FILE" 2>/dev/null || true
  fi
  # Reset terminal attributes so an interrupted printf doesn't leave the
  # shell in a coloured / dimmed state — only when we were using colours.
  if [[ -n "${NC:-}" ]]; then
    printf '%b' "$NC" 2>/dev/null || true
  fi
}

trap _cleanup_temps EXIT INT TERM

# ──────────────────────────────────────────────────────────────────────────
#                                LOGGING
# ──────────────────────────────────────────────────────────────────────────
log_to_file() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$LOG_FILE" 2>/dev/null || true; }
info()        { (( QUIET )) || printf '%b[INFO]%b %s\n' "$BLUE" "$NC" "$*"; log_to_file "INFO  $*"; }
ok()          { (( QUIET )) || printf '%b[ OK ]%b %s\n' "$GREEN" "$NC" "$*"; log_to_file "OK    $*"; }
warn()        { printf '%b[WARN]%b %s\n' "$YELLOW" "$NC" "$*"; log_to_file "WARN  $*"; }
err()         { printf '%b[ERR ]%b %s\n' "$RED" "$NC" "$*" >&2; log_to_file "ERR   $*"; }
step()        { printf '\n%b▶ %s%b\n' "$CYAN$BOLD" "$*" "$NC"; log_to_file "STEP  $*"; }
note()        { (( QUIET )) || printf '%b   %s%b\n' "$DIM" "$*" "$NC"; log_to_file "NOTE  $*"; }
divider()     { (( QUIET )) || printf '%b%s%b\n' "$DIM" "────────────────────────────────────────────────────────────" "$NC"; }
header()      {
  divider
  printf '%b  %s%b\n' "$BOLD$MAGENTA" "$*" "$NC"
  divider
}

# ──────────────────────────────────────────────────────────────────────────
#                                HELPERS
# ──────────────────────────────────────────────────────────────────────────
has_cmd() { command -v "$1" >/dev/null 2>&1; }

# size_kb path → KB used (echoes 0 if missing)
size_kb() {
  if [[ -e "$1" ]]; then
    du -sk "$1" 2>/dev/null | awk '{print $1+0}'
  else
    echo 0
  fi
}

# size_h path → human-readable (e.g. "1.4G")
size_h() {
  if [[ -e "$1" ]]; then
    du -sh "$1" 2>/dev/null | awk '{print $1}'
  else
    echo "0B"
  fi
}

# human_kb KB → human-readable
human_kb() {
  awk -v kb="$1" 'BEGIN {
    if (kb < 1) { print "0B"; exit }
    if (kb < 1024)              { printf "%dK", kb; exit }
    if (kb < 1024*1024)         { printf "%.1fM", kb/1024; exit }
    if (kb < 1024*1024*1024)    { printf "%.2fG", kb/1024/1024; exit }
    printf "%.2fT", kb/1024/1024/1024
  }'
}

# track_freed before_kb after_kb → adds delta to TOTAL_FREED_KB
track_freed() {
  local before="${1:-0}" after="${2:-0}" delta
  delta=$(( before - after ))
  (( delta < 0 )) && delta=0
  TOTAL_FREED_KB=$(( TOTAL_FREED_KB + delta ))
}

# disk_free_kb mountpoint → free KB
disk_free_kb() {
  df -k "${1:-/}" 2>/dev/null | awk 'NR==2 {print $4+0}'
}

# confirm "prompt" [auto_yes] → 0 yes, 1 no
# Respects BATCH_MODE / ASSUME_YES.
confirm() {
  local prompt="$1" auto_yes="${2:-0}" reply
  if (( ASSUME_YES )); then return 0; fi
  if (( BATCH_MODE )); then
    if (( auto_yes )); then return 0; fi
    return 1
  fi
  printf '%b%s [y/N]:%b ' "$BOLD" "$prompt" "$NC" >&2
  read -r reply || reply=""
  [[ "$reply" =~ ^([yY]|[yY][eE][sS])$ ]]
}

# confirm_yes "prompt" → 0 only if user types literal "yes"
confirm_yes() {
  local prompt="$1" reply
  if (( ASSUME_YES && BATCH_MODE )); then return 0; fi
  printf '%b%s%b\n%bType "yes" to proceed:%b ' "$YELLOW" "$prompt" "$NC" "$BOLD" "$NC" >&2
  read -r reply || reply=""
  [[ "$reply" == "yes" ]]
}

press_enter() {
  (( BATCH_MODE )) && return 0
  printf '\n%bPress Enter to continue…%b' "$DIM" "$NC" >&2
  read -r _ || true
}

# safe_rm_rf path → respects DRY_RUN; refuses suspicious paths
safe_rm_rf() {
  local p="$1"
  case "$p" in
    ""|"/"|"/Users"|"/Users/"|"$HOME"|"$HOME/"|"/Library"|"/System"|"/Applications")
      err "Refusing to delete suspicious path: '$p'"
      return 1 ;;
  esac
  if (( DRY_RUN )); then
    note "[dry-run] rm -rf $p"
    return 0
  fi
  rm -rf -- "$p" 2>/dev/null || return 1
}

safe_rm_f() {
  local p="$1"
  if (( DRY_RUN )); then note "[dry-run] rm -f $p"; return 0; fi
  rm -f -- "$p" 2>/dev/null || return 1
}

# clean_dir_contents path
# Removes everything inside path (but not the dir itself), tracks freed KB.
clean_dir_contents() {
  local d="$1" before after
  [[ -z "$d" ]] && return 0
  if [[ ! -d "$d" ]]; then
    note "Skipping (missing): $d"
    return 0
  fi
  before=$(size_kb "$d")
  if (( DRY_RUN )); then
    note "[dry-run] would clear $(human_kb "$before") in $d"
    return 0
  fi
  # Delete contents; never the directory itself. Use ${var:?} guard.
  ( shopt -s dotglob nullglob; rm -rf -- "${d:?}"/* 2>/dev/null ) || true
  after=$(size_kb "$d")
  track_freed "$before" "$after"
  ok "Cleared $(human_kb "$(( before - after ))") from $d"
}

# clean_dir_old path days [name_glob…]
# Deletes files older than N days inside dir; honors DRY_RUN; tracks freed KB.
clean_dir_old() {
  local d="$1" days="$2"
  shift 2
  local globs=("$@")
  [[ ! -d "$d" ]] && return 0
  local before after
  before=$(size_kb "$d")
  if (( DRY_RUN )); then
    note "[dry-run] would prune files >${days}d in $d"
    return 0
  fi
  if (( ${#globs[@]} == 0 )); then
    find "$d" -type f -mtime "+$days" -print0 2>/dev/null | xargs -0 rm -f 2>/dev/null || true
  else
    local g name_args=()
    for g in "${globs[@]}"; do name_args+=( -o -name "$g" ); done
    name_args=( "${name_args[@]:1}" )  # drop leading -o
    find "$d" -type f -mtime "+$days" \( "${name_args[@]}" \) -print0 2>/dev/null \
      | xargs -0 rm -f 2>/dev/null || true
  fi
  after=$(size_kb "$d")
  track_freed "$before" "$after"
  ok "Pruned $(human_kb "$(( before - after ))") (>${days}d) from $d"
}

# clean_dir_unused path days
# Like clean_dir_contents, but only removes files whose atime AND mtime
# are both ≥ N days old — i.e., files that haven't been opened OR modified
# in N days. Used for cache directories where we want to preserve actively-
# used items (e.g., a Gradle distribution the user invokes once a month
# keeps recent atime, so it survives every pass).
#
# `days == 0` triggers a full wipe (clean_dir_contents semantics) — kept
# as an escape hatch for users who really want the old <4.3.2 behaviour.
#
# After file pruning, empty directories are removed in up to 4 passes so
# nested empties collapse all the way up.
clean_dir_unused() {
  local d="$1" days="${2:-${CACHE_AGE_DAYS:-100}}"
  [[ -z "$d" ]] && return 0
  if [[ ! -d "$d" ]]; then
    note "Skipping (missing): $d"
    return 0
  fi
  local before after freed
  before=$(size_kb "$d")
  if (( DRY_RUN )); then
    if (( days == 0 )); then
      note "[dry-run] would full-wipe $d ($(human_kb "$before"))"
    else
      note "[dry-run] would prune files unused (atime+mtime) >${days}d in $d"
    fi
    return 0
  fi
  if (( days == 0 )); then
    ( shopt -s dotglob nullglob; rm -rf -- "${d:?}"/* 2>/dev/null ) || true
  else
    # Files where BOTH atime > N days AND mtime > N days. Anything used
    # recently (read by a tool, or rewritten) keeps its atime/mtime fresh
    # and survives.
    find "$d" -mindepth 1 -type f -atime "+$days" -mtime "+$days" \
      -print0 2>/dev/null | xargs -0 rm -f 2>/dev/null || true
    # Collapse newly-empty directories. Multiple passes handle nesting
    # (parent becomes empty after children are removed, etc.).
    local _ pass
    for pass in 1 2 3 4; do
      find "$d" -mindepth 1 -type d -empty -delete 2>/dev/null || break
    done
  fi
  after=$(size_kb "$d")
  track_freed "$before" "$after"
  freed=$(( before - after ))
  if (( freed > 0 )); then
    if (( days == 0 )); then
      ok "Wiped $(human_kb "$freed") from $d"
    else
      ok "Pruned $(human_kb "$freed") (>${days}d unused) from $d"
    fi
  else
    note "Nothing to prune in $d (everything used within ${days} days)"
  fi
}

# require_sudo — returns 0 if we have (or got) sudo, 1 otherwise
require_sudo() {
  if (( NO_SUDO )); then
    warn "Skipping (sudo disabled): $*"
    return 1
  fi
  if sudo -n true 2>/dev/null; then
    return 0
  fi
  if (( BATCH_MODE && ! ASSUME_YES )); then
    warn "Skipping (sudo required, batch mode): $*"
    return 1
  fi
  printf '%b   This step requires sudo. You may be prompted for your password.%b\n' "$DIM" "$NC"
  if sudo -v 2>/dev/null; then
    return 0
  fi
  warn "Could not obtain sudo; skipping."
  return 1
}

# sudo_run cmd…  — runs with sudo if we can, otherwise warns and skips
sudo_run() {
  if (( DRY_RUN )); then
    note "[dry-run] sudo $*"
    return 0
  fi
  if sudo -n true 2>/dev/null || sudo -v 2>/dev/null; then
    sudo "$@"
    return $?
  fi
  warn "sudo unavailable; skipping: $*"
  return 1
}

mark_done() {
  local n="$1"
  COMPLETED_SECTIONS+=("$n")
}

is_done() {
  local n="$1" item
  for item in "${COMPLETED_SECTIONS[@]+"${COMPLETED_SECTIONS[@]}"}"; do
    [[ "$item" == "$n" ]] && return 0
  done
  return 1
}

# is_apple_bundle bundle_id  → 0 if Apple
is_apple_bundle() {
  local bid="$1" prefix
  for prefix in "${APPLE_PREFIXES[@]}"; do
    [[ "$bid" == "$prefix"* ]] && return 0
  done
  return 1
}

# write_branding_header FILE [SUBTITLE]
# Writes a fixed credits/info banner to FILE. Used for log files when
# they're first opened, and for every report file when generated.
# The banner contains: tool name + version, author + contact, repo,
# npm, license summary, and the run timestamp. Keeps a permanent
# attribution trail in every artefact the user keeps after a run.
write_branding_header() {
  local file="$1" subtitle="${2:-}"
  {
    printf '# ============================================================================\n'
    printf '#  %s v%s — %s\n' "$SCRIPT_NAME" "$SCRIPT_VERSION" "${subtitle:-comprehensive macOS cleanup & maintenance tool}"
    printf '# ----------------------------------------------------------------------------\n'
    printf '#  Author    : %s <%s>\n' "$AUTHOR_NAME" "$AUTHOR_EMAIL"
    printf '#  Website   : %s\n' "$AUTHOR_WEBSITE"
    printf '#  LinkedIn  : %s\n' "$AUTHOR_LINKEDIN"
    printf '#  GitHub    : %s\n' "$AUTHOR_GITHUB"
    printf '#  Repo      : %s\n' "$PROJECT_REPO"
    printf '#  npm       : %s\n' "$PROJECT_NPM"
    printf '#  License   : Source-Available v1.0 — personal use, no modification, no resale\n'
    printf '#              Provided AS IS, no warranty. See LICENSE.md.\n'
    printf '#  Generated : %s\n' "$RUN_TIMESTAMP"
    printf '#  Host      : %s (%s)\n' "$(uname -n 2>/dev/null || echo '?')" "$(sw_vers -productVersion 2>/dev/null || echo '?')"
    printf '# ============================================================================\n'
    printf '\n'
  } >> "$file" 2>/dev/null || true
}

# init_log_file → ensures the day's log file starts with the credits banner
# the first time we touch it. Subsequent appends from log_to_file() just
# add lines below the banner.
init_log_file() {
  if [[ ! -s "$LOG_FILE" ]]; then
    write_branding_header "$LOG_FILE" "session log"
  fi
}

# init_report_file PATH SUBTITLE
# Creates (or truncates) a report file with the standard credits banner.
# Honours --no-reports → returns 1 so callers can skip writing details.
init_report_file() {
  local file="$1" subtitle="$2"
  if (( NO_REPORTS )); then
    return 1
  fi
  : > "$file"
  write_branding_header "$file" "$subtitle"
  return 0
}

# osascript_trash "absolute_path" → moves a path to Trash via Finder.
# Properly escapes both backslashes and double-quotes so paths containing
# them don't break the AppleScript invocation (rare on macOS but possible
# if a user has bizarre filenames). Honours DRY_RUN.
osascript_trash() {
  local p="$1"
  if (( DRY_RUN )); then
    note "[dry-run] move to Trash: $p"
    return 0
  fi
  local q="${p//\\/\\\\}"; q="${q//\"/\\\"}"
  osascript -e "tell application \"Finder\" to delete POSIX file \"$q\"" >/dev/null 2>&1
}

# prompt_int "label" default → echo a positive integer (default if invalid/empty)
# Honors BATCH_MODE (returns default without prompting).
prompt_int() {
  local label="$1" default="$2" reply
  if (( BATCH_MODE )); then printf '%s' "$default"; return 0; fi
  printf '%b%s%b %b[default: %s]:%b ' "$BOLD" "$label" "$NC" "$DIM" "$default" "$NC" >&2
  read -r reply || reply=""
  if [[ "$reply" =~ ^[0-9]+$ && "$reply" -gt 0 ]]; then
    printf '%s' "$reply"
  else
    printf '%s' "$default"
  fi
}

# multi_select TOTAL → prints unique 1-based indices on stdout
# Accepts: "all" / "a"  → every index 1..TOTAL
#          "none" / "n" / empty → nothing (success, no output)
#          "1,3,5-10"  → individual + ranges
# Out-of-range and malformed tokens are silently ignored.
# When ASSUME_YES is set, auto-selects all (no prompt).
multi_select() {
  local total="$1"
  if (( total <= 0 )); then return 0; fi
  if (( ASSUME_YES )); then
    seq 1 "$total"
    return 0
  fi
  local reply
  printf '\n%bSelection syntax:%b %b1,3,5-10%b | %ball%b | %bnone%b (Enter = none)\n' \
    "$BOLD" "$NC" "$CYAN" "$NC" "$CYAN" "$NC" "$CYAN" "$NC" >&2
  printf '%bSelect items (1..%d):%b ' "$BOLD" "$total" "$NC" >&2
  read -r reply || reply=""
  reply="${reply// /}"
  case "$reply" in
    ""|[nN]|[nN][oO][nN][eE]) return 0 ;;
    [aA]|[aA][lL][lL]) seq 1 "$total"; return 0 ;;
  esac
  local part s e t out=""
  IFS=',' read -ra _parts <<<"$reply"
  for part in "${_parts[@]}"; do
    if [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
      s="${BASH_REMATCH[1]}"; e="${BASH_REMATCH[2]}"
      if (( s > e )); then t=$s; s=$e; e=$t; fi
      while (( s <= e )); do
        if (( s >= 1 && s <= total )); then out+="$s"$'\n'; fi
        s=$(( s + 1 ))
      done
    elif [[ "$part" =~ ^[0-9]+$ ]]; then
      if (( part >= 1 && part <= total )); then out+="$part"$'\n'; fi
    fi
  done
  if [[ -n "$out" ]]; then
    printf '%s' "$out" | sort -un
  fi
}

# tmp_file → mktemp registered for cleanup
tmp_file() {
  local f
  f=$(mktemp -t maccleanup.XXXXXX)
  TMPFILES+=("$f")
  printf '%s' "$f"
}

# ──────────────────────────────────────────────────────────────────────────
#                              ARGS / HELP
# ──────────────────────────────────────────────────────────────────────────
print_help() {
  cat <<EOF
${BOLD}${SCRIPT_NAME} v${SCRIPT_VERSION}${NC}
A comprehensive, interactive macOS cleanup & maintenance tool.

${BOLD}Usage${NC}
  $0 [options]

${BOLD}Options${NC}
  --all                       Run all safe sections without prompting per-section.
  --only "L"                  Run only sections in comma-separated list L (e.g. "0,5,21,23").
  --exclude "L"               Skip sections in list L (applied on top of
                              --all, --only, --profile).
  --profile NAME              Run a named bundle of sections. NAME ∈
                              { dev | minimal | cache-only | deep | audit }.
  --yes, -y                   Auto-confirm prompts (use with --all for full unattended).
  --dry-run                   Show what would be cleaned without deleting anything.
  --no-sudo                   Skip every section that needs sudo.
  --threshold N               Days for "unused" apps (default: ${UNUSED_APP_THRESHOLD_DAYS_DEFAULT}).
  --stale-build-days N        Days threshold for stale build artefacts
                              (node_modules, vendor, dist, …) (default: ${STALE_BUILD_THRESHOLD_DAYS_DEFAULT}).
  --large-file-days N         Days threshold for unused large files (default: ${LARGE_FILE_THRESHOLD_DAYS_DEFAULT}).
  --large-file-size-gb N      Min size in GB for the large-file scan (default: ${LARGE_FILE_SIZE_GB_DEFAULT}).
  --scan-roots "P1:P2:…"      Override scan roots for sections 23 / 24
                              (colon-separated absolute paths).
  --logs-dir PATH             Persistent logs directory
                              (default: \$HOME/.mac-cleanup/logs).
  --reports-dir PATH          Persistent reports directory
                              (default: \$HOME/.mac-cleanup/reports).
  --no-reports                Skip writing per-section .txt report files.
                              (Logs still written.)
  --cleanup-logs-on-finish    Delete this run's log file at exit.
                              Default: keep all logs forever.
  --quiet                     Less chatter (errors and warnings still shown).
  --no-color                  Disable ANSI colour output (auto on non-TTYs).
  --notify                    Show a macOS notification when the run finishes.
  --check-update              Query npm for the latest published version
                              and report if newer (no telemetry sent).
  --brew-autoremove           Run 'brew autoremove' as part of section 3.
                              Off by default since 4.3.1 — autoremove can
                              uninstall dependency-installed formulae like
                              node/python and break global tools.
  --cache-age-days N          Age threshold for cache pruning in sections
                              1, 2, 3. Files whose atime AND mtime are
                              both ≥ N days old are deleted; recent files
                              kept. Default: ${CACHE_AGE_DAYS_DEFAULT}.
                              Use 0 for a full wipe (old <4.3.2 behaviour).
  --idle-days N               Universal idle threshold for non-cache
                              deletes in sections 12 (orphan data) and
                              23 (stale build artefacts). Default:
                              ${IDLE_THRESHOLD_DAYS_DEFAULT}. Per the 4.3.3 safety rule, items
                              are only deleted if they're (a) not in use
                              by any active software AND (b) untouched
                              for ≥ N days.
  --list                      List every section number and label, then exit.
  --version, -V               Print version and exit.
  -h, --help                  Show this help.

${BOLD}Examples${NC}
  $0                                       # interactive menu (recommended)
  $0 --dry-run --all                       # preview the safe-batch cleanup
  $0 --all --yes                           # unattended safe cleanup
  $0 --profile dev --dry-run               # run the developer preset
  $0 --profile deep --exclude 14 --yes     # everything heavy, but skip [14]
  $0 --threshold 60                        # treat apps idle >60d as unused
  $0 --only 23 --stale-build-days 60 --dry-run
  $0 --only 24 --large-file-size-gb 2 --large-file-days 180 --dry-run
  $0 --all --yes --notify --quiet          # cron / unattended w/ notification
  $0 --check-update                        # ask npm if a newer version exists

${BOLD}Safety${NC}
  • Destructive operations always confirm by default.
  • The deepest cleanups (orphan data, /private/var/folders, iOS backups,
    Xcode archives, app uninstall, Trash empty) are NEVER auto-run; you
    must select them from the menu or pass --yes explicitly.
  • Logs are written to: ${LOG_FILE}
EOF
}

# Named profile presets — bundles of section numbers users can invoke
# instead of memorising lists. Resolved by resolve_profile() into a
# comma-separated list compatible with --only.
profile_sections() {
  case "$1" in
    dev)        printf '1,2,3,4,23' ;;
    minimal)    printf '5,7,8,9,10' ;;
    cache-only) printf '3,5,6,7,9,19' ;;
    deep)       printf '0,1,2,3,4,5,6,7,8,9,17,19,23,26' ;;
    audit)      printf '0,12,18,21,25,26' ;;
    *)          return 1 ;;
  esac
}

# apply_exclude "comma_list_in" → echoes filtered comma list with sections
# in EXCLUDE_SECTIONS removed. No-op when EXCLUDE_SECTIONS is empty.
apply_exclude() {
  local _input="$1"
  if [[ -z "$EXCLUDE_SECTIONS" || -z "$_input" ]]; then
    printf '%s' "$_input"
    return 0
  fi
  local _exclude_set _ex _s _out=""
  IFS=',' read -ra _exclude_set <<<"$EXCLUDE_SECTIONS"
  local _arr
  IFS=',' read -ra _arr <<<"$_input"
  for _s in "${_arr[@]}"; do
    _s="${_s// /}"
    [[ -z "$_s" ]] && continue
    local _skip=0
    for _ex in "${_exclude_set[@]}"; do
      _ex="${_ex// /}"
      [[ "$_s" == "$_ex" ]] && { _skip=1; break; }
    done
    (( _skip )) && continue
    [[ -n "$_out" ]] && _out+=","
    _out+="$_s"
  done
  printf '%s' "$_out"
}

# notify_user "title" "message" — fire a macOS notification banner via
# osascript. No-op when --notify is not set or osascript is missing.
notify_user() {
  (( NOTIFY )) || return 0
  has_cmd osascript || return 0
  local title="${1:-mac-cleanup}" msg="${2:-Done}"
  local t="${title//\\/\\\\}"; t="${t//\"/\\\"}"
  local m="${msg//\\/\\\\}"; m="${m//\"/\\\"}"
  osascript -e "display notification \"$m\" with title \"$t\" sound name \"Glass\"" \
    >/dev/null 2>&1 || true
}

# check_update_npm — opt-in only (--check-update). Queries the public
# npm registry for the latest published version and prints a one-line
# advisory when it differs from $SCRIPT_VERSION. Silent on network
# failure; never blocks the run; never sends user data.
check_update_npm() {
  (( CHECK_UPDATE )) || return 0
  has_cmd curl || return 0
  local resp latest
  # 4-second connect timeout, 6-second total.
  resp=$(curl -fsSL --connect-timeout 4 --max-time 6 \
    'https://registry.npmjs.org/macleanup/latest' 2>/dev/null) || return 0
  latest=$(printf '%s' "$resp" | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
  if [[ -z "$latest" ]]; then
    note "Update check: registry returned no version field."
    return 0
  fi
  if [[ "$latest" == "$SCRIPT_VERSION" ]]; then
    ok "Update check: you are on the latest published version ($SCRIPT_VERSION)."
  else
    warn "Update check: newer version available — installed $SCRIPT_VERSION, latest $latest."
    note "Upgrade with:  npx macleanup@latest"
  fi
}

# Section catalogue — single source of truth for `--list`, `--help`, and
# the interactive menu. Each entry is "<number>|<one-line label>".
SECTION_CATALOGUE=(
  "0|System health & process monitor"
  "1|Xcode caches, DerivedData, simulators"
  "2|Android / Gradle caches"
  "3|Package manager caches (npm, yarn, pnpm, brew, pip, pod, cargo, go, ruby, flutter)"
  "4|Docker prune (containers/images/volumes)"
  "5|User caches (~/Library/Caches, Saved State, DiagnosticReports)"
  "6|System caches (/Library/Caches) — sudo"
  "7|Logs (user + system)"
  "8|Temp files (\$TMPDIR, /tmp, ~/tmp)"
  "9|Update caches"
  "10|Empty Trash"
  "11|Time Machine local snapshots — sudo"
  "12|Orphaned app data scan"
  "13|System maintenance (periodic) — sudo"
  "14|Deep cache /private/var/folders — sudo + REBOOT"
  "15|Installer leftovers report"
  "16|iOS / iPadOS device backups"
  "17|Xcode archives"
  "18|Large files report"
  "19|Browser caches (Chrome, Firefox, Brave, Arc, Edge)"
  "20|DNS / mDNS reset — sudo"
  "21|Apps unused N+ days (review or bulk uninstall)"
  "22|Purgeable space trigger"
  "23|Stale build artefacts N+ days (node_modules, vendor, dist, …)"
  "24|Large stale files ≥N GB unused N+ days"
  "25|LaunchAgents / LaunchDaemons audit"
  "26|Disk usage report (~/* and ~/Library/*)"
)

print_section_list() {
  printf '%b%s v%s — section catalogue%b\n\n' "$BOLD" "$SCRIPT_NAME" "$SCRIPT_VERSION" "$NC"
  local entry n label
  for entry in "${SECTION_CATALOGUE[@]}"; do
    n="${entry%%|*}"; label="${entry#*|}"
    printf '   [%2s] %s\n' "$n" "$label"
  done
  printf '\nRun a single section:   %s --only <n>\n' "$0"
  printf 'Run several:            %s --only "0,3,5,21"\n' "$0"
}

# resolve_scan_roots → echoes scan roots one per line.
# Honours --scan-roots if set (colon-separated); otherwise falls back to
# common dev folders that exist, or $HOME as last resort.
resolve_scan_roots() {
  if [[ -n "$SCAN_ROOTS_OVERRIDE" ]]; then
    local part
    IFS=':' read -ra _parts <<<"$SCAN_ROOTS_OVERRIDE"
    for part in "${_parts[@]}"; do
      [[ -d "$part" ]] && printf '%s\n' "$part"
    done
    return 0
  fi
  # Auto-detect common dev folders. We DO NOT silently fall back to
  # scanning the entire $HOME — that's how the 4.3.0 bug nuked things
  # inside ~/.bun, ~/.local, ~/.pnpm-store. If none of these exist the
  # caller (section 23) handles the empty-result case explicitly and
  # asks the user to pass --scan-roots.
  local cand
  for cand in \
    "$HOME/Projects" "$HOME/projects" \
    "$HOME/Code" "$HOME/code" \
    "$HOME/Developer" "$HOME/dev" \
    "$HOME/repos" "$HOME/work" "$HOME/Work" \
    "$HOME/Documents" "$HOME/Desktop" \
    "$HOME/Downloads"; do
    [[ -d "$cand" ]] && printf '%s\n' "$cand"
  done
}

parse_args() {
  while (( $# )); do
    case "$1" in
      --all)        RUN_ALL=1; BATCH_MODE=1 ;;
      --only)
        shift
        [[ -n "${1:-}" ]] || { err "--only needs a list"; exit 2; }
        ONLY_SECTIONS="$1"; BATCH_MODE=1 ;;
      --yes|-y)     ASSUME_YES=1 ;;
      --dry-run)    DRY_RUN=1 ;;
      --no-sudo)    NO_SUDO=1 ;;
      --quiet)      QUIET=1 ;;
      --threshold)
        shift
        [[ "${1:-}" =~ ^[0-9]+$ ]] || { err "--threshold needs a number"; exit 2; }
        UNUSED_APP_THRESHOLD_DAYS="$1" ;;
      --stale-build-days)
        shift
        [[ "${1:-}" =~ ^[0-9]+$ ]] || { err "--stale-build-days needs a number"; exit 2; }
        STALE_BUILD_THRESHOLD_DAYS="$1" ;;
      --large-file-days)
        shift
        [[ "${1:-}" =~ ^[0-9]+$ ]] || { err "--large-file-days needs a number"; exit 2; }
        LARGE_FILE_THRESHOLD_DAYS="$1" ;;
      --large-file-size-gb)
        shift
        [[ "${1:-}" =~ ^[0-9]+$ ]] || { err "--large-file-size-gb needs a number"; exit 2; }
        LARGE_FILE_SIZE_GB="$1" ;;
      --scan-roots)
        shift
        [[ -n "${1:-}" ]] || { err "--scan-roots needs a value"; exit 2; }
        SCAN_ROOTS_OVERRIDE="$1" ;;
      --logs-dir)
        shift
        [[ -n "${1:-}" ]] || { err "--logs-dir needs a path"; exit 2; }
        LOG_DIR="$1"
        LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}-${TODAY}.log"
        mkdir -p "$LOG_DIR" 2>/dev/null || true ;;
      --reports-dir)
        shift
        [[ -n "${1:-}" ]] || { err "--reports-dir needs a path"; exit 2; }
        REPORTS_DIR="$1"
        ORPHAN_REPORT="${REPORTS_DIR}/orphans-${TODAY}.txt"
        UNUSED_APPS_REPORT="${REPORTS_DIR}/unused-apps-${TODAY}.txt"
        LARGE_FILES_REPORT="${REPORTS_DIR}/large-files-${TODAY}.txt"
        STALE_BUILD_REPORT="${REPORTS_DIR}/stale-build-${TODAY}.txt"
        LARGE_STALE_REPORT="${REPORTS_DIR}/large-stale-${TODAY}.txt"
        LAUNCH_AUDIT_REPORT="${REPORTS_DIR}/launch-audit-${TODAY}.txt"
        DU_REPORT="${REPORTS_DIR}/disk-usage-${TODAY}.txt"
        mkdir -p "$REPORTS_DIR" 2>/dev/null || true ;;
      --no-reports)
        NO_REPORTS=1 ;;
      --cleanup-logs-on-finish)
        CLEANUP_LOGS_ON_FINISH=1 ;;
      --exclude)
        shift
        [[ -n "${1:-}" ]] || { err "--exclude needs a list"; exit 2; }
        EXCLUDE_SECTIONS="$1" ;;
      --profile)
        shift
        [[ -n "${1:-}" ]] || { err "--profile needs a name (dev|minimal|cache-only|deep|audit)"; exit 2; }
        PROFILE_NAME="$1"
        if ! profile_sections "$PROFILE_NAME" >/dev/null; then
          err "Unknown profile '$PROFILE_NAME'. Try: dev, minimal, cache-only, deep, audit"
          exit 2
        fi
        BATCH_MODE=1 ;;
      --notify)
        NOTIFY=1 ;;
      --check-update)
        CHECK_UPDATE=1 ;;
      --brew-autoremove)
        BREW_AUTOREMOVE=1 ;;
      --cache-age-days)
        shift
        [[ "${1:-}" =~ ^[0-9]+$ ]] || { err "--cache-age-days needs a number"; exit 2; }
        CACHE_AGE_DAYS="$1" ;;
      --idle-days)
        shift
        [[ "${1:-}" =~ ^[0-9]+$ ]] || { err "--idle-days needs a number"; exit 2; }
        IDLE_THRESHOLD_DAYS="$1" ;;
      --no-color)
        RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""; MAGENTA=""; BOLD=""; DIM=""; NC=""
        ;;
      --list)
        print_section_list; exit 0 ;;
      --version|-V)
        printf '%s %s\n' "$SCRIPT_NAME" "$SCRIPT_VERSION"
        exit 0 ;;
      -h|--help)    print_help; exit 0 ;;
      *) err "Unknown option: $1"; print_help; exit 2 ;;
    esac
    shift
  done
}

# ══════════════════════════════════════════════════════════════════════════
# ───────────────────────── SECTION FUNCTIONS ──────────────────────────────
# ══════════════════════════════════════════════════════════════════════════

# Section 0 — System Health Check & Process Monitor
s00_health() {
  header "[0] System Health Check"
  local mac_ver chip ram_b uptime
  mac_ver=$(sw_vers -productVersion 2>/dev/null || echo "?")
  chip=$(uname -m)
  ram_b=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
  uptime=$(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')

  info "macOS:    $mac_ver"
  info "Chip:     $chip ($([[ "$chip" == "arm64" ]] && echo "Apple Silicon" || echo "Intel"))"
  info "RAM:      $(awk -v b="$ram_b" 'BEGIN{printf "%.1f GB", b/1024/1024/1024}')"
  info "Uptime:   $uptime"
  printf '\n%bDisk:%b\n' "$BOLD" "$NC"
  df -h / | sed 's/^/   /'

  printf '\n%bMemory pressure:%b\n' "$BOLD" "$NC"
  if has_cmd memory_pressure; then
    memory_pressure 2>/dev/null | head -8 | sed 's/^/   /' || true
  else
    vm_stat | head -10 | sed 's/^/   /'
  fi

  printf '\n%bTop CPU processes:%b\n' "$BOLD" "$NC"
  ps -Aceo pcpu,pid,comm | sort -k1 -n -r | head -6 | sed 's/^/   /'
  printf '\n%bTop memory processes:%b\n' "$BOLD" "$NC"
  ps -Aceo pmem,pid,comm | sort -k1 -n -r | head -6 | sed 's/^/   /'

  # Battery (laptops only)
  if system_profiler SPPowerDataType 2>/dev/null | grep -q "Battery Information"; then
    printf '\n%bBattery:%b\n' "$BOLD" "$NC"
    system_profiler SPPowerDataType 2>/dev/null \
      | awk '/Cycle Count|Condition|Maximum Capacity|State of Charge/ {print "   " $0}'
  fi

  # Disk SMART
  printf '\n%bSSD SMART:%b\n' "$BOLD" "$NC"
  diskutil info disk0 2>/dev/null | awk '/SMART Status/ {print "   " $0}' \
    || note "   diskutil info unavailable"

  mark_done 0
  press_enter
}

# Section 1 — Xcode caches & DerivedData
s01_xcode() {
  header "[1] Xcode caches, DerivedData, simulators"
  if ! [[ -d "$HOME/Library/Developer/Xcode" ]] && ! has_cmd xcrun; then
    info "No Xcode installation detected — skipping."
    mark_done 1; return 0
  fi
  info "Pruning Xcode caches unused for ${CACHE_AGE_DAYS}+ days (atime+mtime). Recently-built projects survive."
  local d
  for d in \
    "$HOME/Library/Developer/Xcode/DerivedData" \
    "$HOME/Library/Developer/Xcode/iOS DeviceSupport" \
    "$HOME/Library/Developer/Xcode/tvOS DeviceSupport" \
    "$HOME/Library/Developer/Xcode/watchOS DeviceSupport" \
    "$HOME/Library/Developer/Xcode/Logs" \
    "$HOME/Library/Developer/Xcode/DocumentationCache" \
    "$HOME/Library/Caches/com.apple.dt.Xcode"; do
    [[ -d "$d" ]] && clean_dir_unused "$d" "$CACHE_AGE_DAYS"
  done
  if has_cmd xcrun; then
    if (( DRY_RUN )); then
      note "[dry-run] xcrun simctl delete unavailable"
    else
      info "Removing unavailable simulators…"
      xcrun simctl delete unavailable >/dev/null 2>&1 || warn "simctl delete unavailable failed"
      ok "Removed unavailable simulators"
    fi
  fi
  if [[ -d "$HOME/Library/Developer/CoreSimulator" ]]; then
    local sz; sz=$(size_h "$HOME/Library/Developer/CoreSimulator")
    if confirm "Wipe ALL CoreSimulator data ($sz)? Loses every simulator's saved state."; then
      clean_dir_contents "$HOME/Library/Developer/CoreSimulator"
    fi
  fi
  mark_done 1; press_enter
}

# Section 2 — Android / Gradle
s02_android() {
  header "[2] Android / Gradle caches"
  info "Pruning items unused for ${CACHE_AGE_DAYS}+ days (atime+mtime)."
  info "A Gradle distribution you invoke even once a month keeps a recent atime and survives."
  local cleaned=0
  if [[ -d "$HOME/.gradle/caches" ]]; then
    clean_dir_unused "$HOME/.gradle/caches" "$CACHE_AGE_DAYS"; cleaned=1
  fi
  if [[ -d "$HOME/.gradle/wrapper/dists" ]]; then
    local sz; sz=$(size_h "$HOME/.gradle/wrapper/dists")
    info "Gradle wrapper distributions: $sz total"
    if confirm "Prune Gradle distributions unused for ${CACHE_AGE_DAYS}+ days?"; then
      clean_dir_unused "$HOME/.gradle/wrapper/dists" "$CACHE_AGE_DAYS"
      cleaned=1
    fi
  fi
  for d in "$HOME/.android/cache" "$HOME/.android/build-cache"; do
    [[ -d "$d" ]] && clean_dir_unused "$d" "$CACHE_AGE_DAYS" && cleaned=1
  done
  (( cleaned )) || info "No Android/Gradle caches found."
  mark_done 2; press_enter
}

# Section 3 — Package manager caches
s03_pkg_managers() {
  header "[3] Package manager caches"

  if has_cmd npm;  then
    if (( DRY_RUN )); then note "[dry-run] npm cache clean --force"
    else info "npm…";  npm cache clean --force >/dev/null 2>&1 && ok "npm cache cleaned" \
                         || warn "npm cache clean failed"; fi
  fi
  if has_cmd yarn; then
    if (( DRY_RUN )); then note "[dry-run] yarn cache clean"
    else info "yarn…"; yarn cache clean >/dev/null 2>&1 && ok "yarn cache cleaned" \
                         || warn "yarn cache clean failed"; fi
  fi
  if has_cmd pnpm; then
    if (( DRY_RUN )); then note "[dry-run] pnpm store prune"
    else info "pnpm…"; pnpm store prune >/dev/null 2>&1 && ok "pnpm store pruned" \
                         || warn "pnpm store prune failed"; fi
  fi
  if has_cmd pod;  then
    if (( DRY_RUN )); then note "[dry-run] pod cache clean --all"
    else info "CocoaPods…"; pod cache clean --all >/dev/null 2>&1 && ok "pod cache cleaned" \
                              || warn "pod cache clean failed"; fi
  fi
  if has_cmd pip;  then
    if (( DRY_RUN )); then note "[dry-run] pip cache purge"
    else info "pip…"; pip cache purge >/dev/null 2>&1 && ok "pip cache purged" \
                        || warn "pip cache purge failed"; fi
  fi
  if has_cmd pip3; then
    if (( DRY_RUN )); then note "[dry-run] pip3 cache purge"
    else pip3 cache purge >/dev/null 2>&1 && ok "pip3 cache purged" || true; fi
  fi
  if has_cmd brew; then
    if (( DRY_RUN )); then
      note "[dry-run] brew cleanup -s"
      (( BREW_AUTOREMOVE )) && note "[dry-run] brew autoremove (--brew-autoremove set)"
    else
      info "Homebrew cleanup…"
      brew cleanup -s >/dev/null 2>&1 || warn "brew cleanup failed"
      # SAFETY (4.3.1): brew autoremove can uninstall formulae that were
      # installed as dependencies and are now considered unused. In
      # practice this can remove `node`, `python`, `openssl`, etc. and
      # silently break every globally-installed tool that depended on
      # them. Now strictly opt-in via --brew-autoremove.
      if (( BREW_AUTOREMOVE )); then
        warn "Running 'brew autoremove' (--brew-autoremove was passed)."
        warn "This can remove formulae installed as dependencies."
        brew autoremove >/dev/null 2>&1 || warn "brew autoremove failed"
      fi
      ok "Homebrew cleaned (cache only)"
    fi
  fi

  # Flutter pub cache (age-aware — pubs you reference recently keep their atime)
  if [[ -d "$HOME/.pub-cache" ]]; then
    local sz; sz=$(size_h "$HOME/.pub-cache")
    if confirm "Prune Flutter pub-cache packages unused for ${CACHE_AGE_DAYS}+ days ($sz total)?" 1; then
      clean_dir_unused "$HOME/.pub-cache" "$CACHE_AGE_DAYS"
    fi
  fi
  # Cargo
  for d in "$HOME/.cargo/registry/cache" "$HOME/.cargo/git/db"; do
    [[ -d "$d" ]] && clean_dir_unused "$d" "$CACHE_AGE_DAYS"
  done
  # Go module cache — `go clean -modcache` would wipe everything; that
  # contradicts the "100-day rule." Default to age-aware prune; only fall
  # back to `go clean -modcache` if --cache-age-days 0 was explicitly set.
  if [[ -d "$HOME/go/pkg/mod/cache" ]]; then
    if (( CACHE_AGE_DAYS == 0 )) && has_cmd go && ! (( DRY_RUN )); then
      info "go clean -modcache (full wipe — --cache-age-days 0)…"
      GOFLAGS="" go clean -modcache 2>/dev/null && ok "go modcache wiped" \
        || { warn "go clean failed; falling back to rm"; clean_dir_unused "$HOME/go/pkg/mod/cache" 0; }
    else
      clean_dir_unused "$HOME/go/pkg/mod/cache" "$CACHE_AGE_DAYS"
    fi
  fi
  # Ruby
  for d in "$HOME/.bundle/cache"; do
    [[ -d "$d" ]] && clean_dir_unused "$d" "$CACHE_AGE_DAYS"
  done
  if [[ -d "$HOME/.gem/cache" ]]; then
    clean_dir_unused "$HOME/.gem/cache" "$CACHE_AGE_DAYS"
  fi
  mark_done 3; press_enter
}

# Section 4 — Docker prune
s04_docker() {
  header "[4] Docker system prune"
  if ! has_cmd docker; then
    info "Docker not installed — skipping."
    mark_done 4; return 0
  fi
  if ! docker info >/dev/null 2>&1; then
    warn "Docker daemon not running. Start Docker Desktop and re-run this section."
    mark_done 4; return 0
  fi
  if confirm "Prune ALL unused Docker containers, images, volumes, networks?"; then
    if (( DRY_RUN )); then
      note "[dry-run] docker system prune -a --volumes -f"
    else
      docker system prune -a --volumes -f
      ok "Docker pruned"
    fi
  fi
  mark_done 4; press_enter
}

# Section 5 — User caches (~/Library/Caches)
s05_user_caches() {
  header "[5] User caches (~/Library/Caches)"
  local cache_root="$HOME/Library/Caches"
  if [[ -d "$cache_root" ]]; then
    info "Sweeping ~/Library/Caches (preserving Apple, browsers, password managers)…"
    local before after
    before=$(size_kb "$cache_root")
    if (( DRY_RUN )); then
      note "[dry-run] would prune most non-Apple, non-browser entries"
    else
      # Preserve Apple, all major browsers (handle in [19]), password managers, system tooling.
      find "$cache_root" -mindepth 1 -maxdepth 1 \
        ! -name 'com.apple.*' \
        ! -name 'com.google.Chrome*' \
        ! -name 'org.mozilla.firefox*' \
        ! -name 'com.apple.Safari*' \
        ! -name 'com.brave.*' \
        ! -name 'BraveSoftware*' \
        ! -name 'Company' \
        ! -name 'com.microsoft.edgemac*' \
        ! -name 'com.operasoftware.Opera*' \
        ! -name 'com.vivaldi.Vivaldi*' \
        ! -name '1Password*' \
        ! -name 'com.agilebits.*' \
        ! -name 'Bitwarden*' \
        -exec rm -rf -- {} + 2>/dev/null || true
    fi
    after=$(size_kb "$cache_root")
    track_freed "$before" "$after"
    ok "Cleared $(human_kb "$(( before - after ))") from $cache_root"
  else
    note "No ~/Library/Caches found."
  fi

  if [[ -d "$HOME/Library/Saved Application State" ]]; then
    local sz; sz=$(size_h "$HOME/Library/Saved Application State")
    if confirm "Clear Saved Application State ($sz)? (windows won't reopen on relaunch)" 1; then
      clean_dir_contents "$HOME/Library/Saved Application State"
    fi
  fi
  if [[ -d "$HOME/Library/Logs/DiagnosticReports" ]]; then
    clean_dir_contents "$HOME/Library/Logs/DiagnosticReports"
  fi
  mark_done 5; press_enter
}

# Section 6 — System caches /Library/Caches (sudo)
s06_system_caches() {
  header "[6] System caches (/Library/Caches)"
  if ! require_sudo "system caches"; then mark_done 6; return 0; fi
  if (( DRY_RUN )); then
    note "[dry-run] would sweep non-Apple entries from /Library/Caches"
  else
    local before after
    before=$(sudo du -sk /Library/Caches 2>/dev/null | awk '{print $1}'); before=${before:-0}
    sudo find /Library/Caches -mindepth 1 -maxdepth 1 ! -name 'com.apple.*' \
      -exec rm -rf -- {} + 2>/dev/null || true
    after=$(sudo du -sk /Library/Caches 2>/dev/null | awk '{print $1}'); after=${after:-0}
    track_freed "$before" "$after"
    ok "Cleared $(human_kb "$(( before - after ))") from /Library/Caches"
  fi
  mark_done 6; press_enter
}

# Section 7 — Logs
s07_logs() {
  header "[7] Logs (user + system)"
  clean_dir_old "$HOME/Library/Logs" 7
  if [[ -d /Library/Logs ]] && require_sudo "system logs"; then
    if (( DRY_RUN )); then
      note "[dry-run] would prune /Library/Logs >30d"
    else
      sudo find /Library/Logs -type f -mtime +30 -delete 2>/dev/null || true
      ok "Pruned old files from /Library/Logs"
    fi
  fi
  if [[ -d /private/var/log ]] && require_sudo "/private/var/log"; then
    if (( DRY_RUN )); then
      note "[dry-run] would prune /private/var/log >14d"
    else
      sudo find /private/var/log -type f -mtime +14 \
        \( -name '*.log' -o -name '*.log.*' -o -name '*.out' -o -name '*.err' \
           -o -name '*.asl' -o -name '*.gz' -o -name '*.bz2' \) \
        -delete 2>/dev/null || true
      ok "Pruned old files from /private/var/log"
    fi
  fi
  mark_done 7; press_enter
}

# Section 8 — Temp files
s08_temp() {
  header "[8] Temp files"
  local user_tmp="${TMPDIR%/}"
  if [[ -n "$user_tmp" && -d "$user_tmp" ]]; then
    if (( DRY_RUN )); then
      note "[dry-run] would prune $user_tmp (user-owned, >1d)"
    else
      find "$user_tmp" -mindepth 1 -user "$(id -un)" -mtime +1 \
        -exec rm -rf -- {} + 2>/dev/null || true
      ok "Pruned old user temp files"
    fi
  fi
  if [[ -d /tmp ]]; then
    if (( DRY_RUN )); then
      note "[dry-run] would prune /tmp (user-owned, >1d)"
    else
      find /tmp -mindepth 1 -user "$(id -un)" -mtime +1 \
        -exec rm -rf -- {} + 2>/dev/null || true
      ok "Pruned old /tmp entries (user-owned)"
    fi
  fi
  if [[ -d "$HOME/tmp" ]]; then
    clean_dir_contents "$HOME/tmp"
  fi
  mark_done 8; press_enter
}

# Section 9 — Update caches
s09_update_caches() {
  header "[9] Update caches"
  [[ -d "$HOME/Library/Updates" ]] && clean_dir_contents "$HOME/Library/Updates"
  if [[ -d /Library/Updates ]] && require_sudo "/Library/Updates"; then
    if (( DRY_RUN )); then
      note "[dry-run] would clear /Library/Updates"
    else
      sudo find /Library/Updates -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + 2>/dev/null || true
      ok "Cleared /Library/Updates"
    fi
  fi
  mark_done 9; press_enter
}

# Section 10 — Empty Trash
s10_trash() {
  header "[10] Empty Trash"
  if [[ ! -d "$HOME/.Trash" ]]; then
    info "No Trash directory found."
    mark_done 10; return 0
  fi
  local sz; sz=$(size_h "$HOME/.Trash")
  local n;  n=$(find "$HOME/.Trash" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | awk '{print $1}')
  if (( n == 0 )); then
    info "Trash is already empty."
    mark_done 10; return 0
  fi
  if confirm "Empty Trash ($n items, $sz)? This is irreversible." 1; then
    clean_dir_contents "$HOME/.Trash"
  fi
  mark_done 10; press_enter
}

# Section 11 — Time Machine local snapshots
s11_time_machine() {
  header "[11] Time Machine local snapshots"
  if ! has_cmd tmutil; then
    info "tmutil not available — skipping."
    mark_done 11; return 0
  fi
  local snaps
  snaps=$(tmutil listlocalsnapshots / 2>/dev/null | wc -l | awk '{print $1}')
  if (( snaps == 0 )); then
    info "No local snapshots present."
    mark_done 11; return 0
  fi
  info "Found $snaps local snapshots:"
  tmutil listlocalsnapshots / 2>/dev/null | sed 's/^/   /'
  if confirm "Delete ALL local Time Machine snapshots?"; then
    if ! require_sudo "snapshot deletion"; then mark_done 11; return 0; fi
    if (( DRY_RUN )); then
      note "[dry-run] sudo tmutil deletelocalsnapshots /"
    else
      sudo tmutil deletelocalsnapshots / 2>&1 | sed 's/^/   /' || warn "snapshot delete had errors"
      ok "Local snapshots deletion attempted (some may persist until APFS frees them)"
    fi
  fi
  mark_done 11; press_enter
}

# Section 12 — Orphaned app data scan
s12_orphaned() {
  header "[12] Orphaned app data"
  info "Scanning ~/Library for data belonging to apps that are no longer installed."

  # Build set of installed app names + bundle IDs.
  local apps_file installed_names installed_bids
  apps_file=$(tmp_file)
  : > "$apps_file"
  local app_dir
  for app_dir in /Applications /System/Applications /System/Applications/Utilities "$HOME/Applications"; do
    [[ -d "$app_dir" ]] || continue
    find "$app_dir" -maxdepth 3 -name "*.app" -type d 2>/dev/null >> "$apps_file"
  done

  installed_names=$(tmp_file); installed_bids=$(tmp_file)
  : > "$installed_names"; : > "$installed_bids"
  local app n bid
  while IFS= read -r app; do
    n=$(basename "$app" .app)
    printf '%s\n' "$n" >> "$installed_names"
    bid=$(defaults read "$app/Contents/Info" CFBundleIdentifier 2>/dev/null || echo "")
    [[ -n "$bid" ]] && printf '%s\n' "$bid" >> "$installed_bids"
  done < "$apps_file"

  # Helper: is given basename matched by any installed app?
  local report; report="$ORPHAN_REPORT"
  if init_report_file "$report" "orphan app data scan"; then
    printf '# Orphan scan results\n\n' >> "$report"
  fi

  # Match function
  _match_installed() {
    # arg = candidate name (e.g. "Spotify" or "com.spotify.client")
    local cand="$1" lc
    lc=$(echo "$cand" | tr '[:upper:]' '[:lower:]')
    # bundle id direct match
    if grep -Fxqi -- "$cand" "$installed_bids" 2>/dev/null; then return 0; fi
    # bundle id prefix match (com.foo.bar.helper → com.foo.bar)
    while IFS= read -r bid; do
      [[ -z "$bid" ]] && continue
      [[ "$cand" == "$bid"* ]] && return 0
      [[ "$bid" == "$cand"* ]] && return 0
    done < "$installed_bids"
    # name match (case-insensitive)
    if grep -Fxqi -- "$cand" "$installed_names" 2>/dev/null; then return 0; fi
    # token presence: split candidate and see if any token equals app name
    local token
    for token in $(echo "$lc" | tr '.,_-' '\n'); do
      [[ ${#token} -lt 4 ]] && continue
      if grep -Fxqi -- "$token" "$installed_names" 2>/dev/null; then return 0; fi
    done
    return 1
  }

  declare -a candidates=()
  local recent_skipped=0
  local _now; _now=$(date +%s)
  local _idle_days="$IDLE_THRESHOLD_DAYS"

  _scan_dir() {
    local dir="$1" pattern="$2"
    [[ -d "$dir" ]] || return 0
    local entry
    while IFS= read -r entry; do
      local base; base=$(basename "$entry")
      # ignore Apple
      is_apple_bundle "$base" && continue
      [[ "$base" == "."* ]] && continue
      _match_installed "$base" && continue
      # 4.3.3 SAFETY: orphaned-by-bundle-ID is condition (a). Now also
      # require condition (b): the entry hasn't been touched (atime AND
      # mtime) for ≥ IDLE_THRESHOLD_DAYS. Skip recently-active items
      # even if our heuristic matcher couldn't find an installed app —
      # something IS using it.
      local _atime _mtime _newer _idle
      _atime=$(stat -f %a "$entry" 2>/dev/null || echo 0)
      _mtime=$(stat -f %m "$entry" 2>/dev/null || echo 0)
      _newer=$_atime
      (( _mtime > _newer )) && _newer=$_mtime
      if (( _newer > 0 )); then
        _idle=$(( (_now - _newer) / 86400 ))
        if (( _idle < _idle_days )); then
          recent_skipped=$(( recent_skipped + 1 ))
          continue
        fi
      fi
      candidates+=("$entry")
    done < <(find "$dir" -mindepth 1 -maxdepth 1 $pattern 2>/dev/null)
  }

  _scan_dir "$HOME/Library/Application Support" "-type d"
  _scan_dir "$HOME/Library/Containers"          "-type d"
  _scan_dir "$HOME/Library/Group Containers"    "-type d"
  _scan_dir "$HOME/Library/Saved Application State" "-type d"
  _scan_dir "$HOME/Library/Preferences"         "-type f -name *.plist"
  _scan_dir "$HOME/Library/LaunchAgents"        "-type f -name *.plist"

  if (( recent_skipped > 0 )); then
    note "Skipped $recent_skipped orphan-shaped entries that were touched within the last ${_idle_days} days (probably still in use)."
  fi

  if (( ${#candidates[@]} == 0 )); then
    ok "No orphaned data found older than ${_idle_days} days."
    mark_done 12; press_enter; return 0
  fi

  info "Found ${#candidates[@]} candidate orphan entries (orphaned AND idle ≥${_idle_days}d). Reporting to:"
  note "$report"
  local total_kb=0 c sz_kb
  for c in "${candidates[@]}"; do
    sz_kb=$(size_kb "$c")
    total_kb=$(( total_kb + sz_kb ))
    printf '%s\t%s\n' "$(human_kb "$sz_kb")" "$c" >> "$report"
  done
  sort -hr "$report" -o "$report" 2>/dev/null || true
  info "Total candidate size: $(human_kb "$total_kb")"

  if (( BATCH_MODE && ! ASSUME_YES )); then
    note "Batch mode: report-only. Re-run interactively to delete."
    mark_done 12; press_enter; return 0
  fi

  if confirm "Review candidates one by one to delete?" 0; then
    local i=0 reply
    for c in "${candidates[@]}"; do
      i=$((i+1))
      sz_kb=$(size_kb "$c")
      printf '\n%b[%d/%d]%b %s  (%s)\n' "$CYAN" "$i" "${#candidates[@]}" "$NC" "$c" "$(human_kb "$sz_kb")"
      printf '%bDelete? [y/N/q to quit]%b ' "$BOLD" "$NC"
      read -r reply || reply=""
      case "$reply" in
        [yY]|[yY][eE][sS])
          if (( DRY_RUN )); then note "[dry-run] would delete $c"
          else
            if rm -rf -- "$c" 2>/dev/null; then
              TOTAL_FREED_KB=$(( TOTAL_FREED_KB + sz_kb ))
              ok "Deleted"
            else
              warn "Failed to delete $c"
            fi
          fi ;;
        [qQ]) info "Stopped at $i."; break ;;
        *) note "Skipped" ;;
      esac
    done
  fi
  mark_done 12; press_enter
}

# Section 13 — Periodic maintenance
s13_maintenance() {
  header "[13] System maintenance scripts (periodic)"
  if ! require_sudo "periodic maintenance"; then mark_done 13; return 0; fi
  if (( DRY_RUN )); then
    note "[dry-run] sudo periodic daily weekly monthly"
  else
    info "Running periodic maintenance (this may take a minute)…"
    sudo periodic daily weekly monthly && ok "periodic maintenance done" \
      || warn "periodic returned non-zero"
  fi
  mark_done 13; press_enter
}

# Section 14 — Deep cache (/private/var/folders) — requires reboot
s14_var_folders() {
  header "[14] Deep cache: /private/var/folders (NEEDS REBOOT)"
  warn "This wipes the per-user temp/cache state used by macOS itself."
  warn "After running this you MUST reboot or many apps will misbehave."
  if ! confirm_yes "Are you sure? Type literal 'yes' to continue"; then
    info "Skipped."
    mark_done 14; return 0
  fi
  if ! require_sudo "/private/var/folders"; then mark_done 14; return 0; fi
  if (( DRY_RUN )); then
    note "[dry-run] sudo find /private/var/folders -mindepth 1 -maxdepth 3 -delete"
  else
    sudo find /private/var/folders -mindepth 1 -maxdepth 3 -print0 2>/dev/null \
      | xargs -0 sudo rm -rf 2>/dev/null || true
    ok "Deep cache cleared. REBOOT NOW."
  fi
  mark_done 14; press_enter
}

# Section 15 — Installer leftovers (advisory)
s15_installer() {
  header "[15] Installer leftovers report"
  local found=0 p
  for p in /Applications/Install\ macOS*.app "$HOME/Applications/Install macOS*.app"; do
    [[ -e "$p" ]] && { warn "Installer present: $p ($(size_h "$p"))"; found=1; }
  done
  for p in "/Previous Systems.localized" "/Previous System" \
           "$HOME/Previous Systems.localized" "$HOME/Previous System" \
           "$HOME/Relocated Items" "$HOME/macOS Install Data" "/macOS Install Data"; do
    [[ -e "$p" ]] && { warn "Leftover: $p ($(size_h "$p"))"; found=1; }
  done
  (( found )) || ok "No installer leftovers found."
  info "(advisory only — review before deleting manually)"
  mark_done 15; press_enter
}

# Section 16 — iOS / iPadOS backups
s16_ios_backups() {
  header "[16] iOS / iPadOS device backups"
  local root="$HOME/Library/Application Support/MobileSync/Backup"
  if [[ ! -d "$root" ]]; then
    info "No iOS backups directory found."
    mark_done 16; return 0
  fi
  local backups=()
  while IFS= read -r d; do backups+=("$d"); done < <(find "$root" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
  if (( ${#backups[@]} == 0 )); then
    info "No backups present."
    mark_done 16; return 0
  fi
  info "Found ${#backups[@]} backup(s) in $root"
  info "Per the 4.3.3 safety rule: items untouched for ${IDLE_THRESHOLD_DAYS}+ days are highlighted as safe-to-delete; recent backups are not."
  local b name date sz_h
  local _now; _now=$(date +%s)
  local i=0
  for b in "${backups[@]}"; do
    i=$((i+1))
    name=""; date=""
    if [[ -f "$b/Info.plist" ]] && has_cmd plutil; then
      name=$(plutil -extract 'Device Name' raw -o - "$b/Info.plist" 2>/dev/null || true)
      date=$(plutil -extract 'Last Backup Date' raw -o - "$b/Info.plist" 2>/dev/null || true)
    fi
    sz_h=$(size_h "$b")
    # Compute age: prefer Last Backup Date from plist; fall back to dir mtime
    local _epoch=0 _age_label="" _flag=""
    if [[ -n "$date" ]]; then
      _epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$date" +%s 2>/dev/null \
        || date -j -f "%Y-%m-%d %H:%M:%S %z" "$date" +%s 2>/dev/null \
        || echo 0)
    fi
    if (( _epoch == 0 )); then
      _epoch=$(stat -f %m "$b" 2>/dev/null || echo 0)
    fi
    if (( _epoch > 0 )); then
      local _age=$(( (_now - _epoch) / 86400 ))
      _age_label="${_age}d"
      if (( _age >= IDLE_THRESHOLD_DAYS )); then
        _flag=" ${YELLOW}[idle ≥${IDLE_THRESHOLD_DAYS}d]${NC}"
      else
        _flag=" ${DIM}(recent)${NC}"
      fi
    fi
    printf '   %b[%d]%b %s  %s — %s — %s — %s%b\n' \
      "$CYAN" "$i" "$NC" "$(basename "$b")" "${name:-?}" \
      "${date:-?}" "$sz_h" "$_age_label" "$_flag"
  done
  if (( BATCH_MODE && ! ASSUME_YES )); then
    note "Batch mode: report-only."
    mark_done 16; press_enter; return 0
  fi
  if confirm "Review backups one by one to delete?"; then
    local reply
    for b in "${backups[@]}"; do
      printf '\n%s (%s)\n' "$b" "$(size_h "$b")"
      printf '%bDelete? [y/N/q]%b ' "$BOLD" "$NC"
      read -r reply || reply=""
      case "$reply" in
        [yY]*) safe_rm_rf "$b" && ok "Deleted" || warn "Failed to delete" ;;
        [qQ]*) break ;;
        *) note "Kept" ;;
      esac
    done
  fi
  mark_done 16; press_enter
}

# Section 17 — Xcode archives
s17_xcode_archives() {
  header "[17] Xcode archives"
  local root="$HOME/Library/Developer/Xcode/Archives"
  if [[ ! -d "$root" ]]; then
    info "No Xcode archives directory found."
    mark_done 17; return 0
  fi
  local archives=()
  while IFS= read -r a; do archives+=("$a"); done < <(find "$root" -name "*.xcarchive" -type d 2>/dev/null)
  if (( ${#archives[@]} == 0 )); then
    info "No archives present."
    mark_done 17; return 0
  fi
  info "Found ${#archives[@]} archive(s) ($(size_h "$root") total). Required for App Store re-signing."
  info "Per the 4.3.3 safety rule: archives untouched ≥${IDLE_THRESHOLD_DAYS}d are highlighted; recent ones are kept by default."
  local a i=0 _now
  _now=$(date +%s)
  for a in "${archives[@]}"; do
    i=$((i+1))
    local _epoch _age_label="" _flag=""
    _epoch=$(stat -f %m "$a" 2>/dev/null || echo 0)
    if (( _epoch > 0 )); then
      local _age=$(( (_now - _epoch) / 86400 ))
      _age_label="${_age}d"
      if (( _age >= IDLE_THRESHOLD_DAYS )); then
        _flag=" ${YELLOW}[idle ≥${IDLE_THRESHOLD_DAYS}d]${NC}"
      else
        _flag=" ${DIM}(recent — likely keep)${NC}"
      fi
    fi
    printf '   %b[%d]%b %s — %s — %s%b\n' \
      "$CYAN" "$i" "$NC" "$(basename "$a")" "$(size_h "$a")" "$_age_label" "$_flag"
  done
  if (( BATCH_MODE && ! ASSUME_YES )); then
    note "Batch mode: report-only."
    mark_done 17; press_enter; return 0
  fi
  if confirm "Review archives one by one to delete?"; then
    local reply
    for a in "${archives[@]}"; do
      printf '\n%s (%s)\n' "$a" "$(size_h "$a")"
      printf '%bDelete? [y/N/q]%b ' "$BOLD" "$NC"
      read -r reply || reply=""
      case "$reply" in
        [yY]*) safe_rm_rf "$a" && ok "Deleted" || warn "Failed" ;;
        [qQ]*) break ;;
        *) note "Kept" ;;
      esac
    done
  fi
  # Clean up empty year/month dirs
  if ! (( DRY_RUN )); then
    find "$root" -mindepth 1 -type d -empty -delete 2>/dev/null || true
  fi
  mark_done 17; press_enter
}

# Section 18 — Large files report (advisory)
s18_large_files() {
  header "[18] Large files report (advisory only)"
  info "Scanning \$HOME for files larger than 500 MB (this can take a minute)…"
  init_report_file "$LARGE_FILES_REPORT" "large files report (>500 MB)" || true
  local _scan; _scan=$(tmp_file)
  find "$HOME" -maxdepth 7 -type f -size +500M \
    ! -path "*/Library/CloudStorage/*" \
    ! -path "*/Library/Mobile Documents/*" \
    ! -path "*/Library/Photos/*" \
    ! -path "*.photoslibrary/*" \
    ! -path "*/Movies/*" \
    ! -path "*/Music/*" \
    ! -path "*/Virtual Machines/*" \
    ! -path "*/.Trash/*" \
    ! -path "*/Parallels/*" \
    ! -path "*/VMware/*" \
    -exec du -h {} + 2>/dev/null \
    | sort -hr \
    | head -25 > "$_scan"
  cat "$_scan"
  if (( ! NO_REPORTS )); then
    cat "$_scan" >> "$LARGE_FILES_REPORT"
    info "Top entries written to: $LARGE_FILES_REPORT"
  fi
  mark_done 18; press_enter
}

# Section 19 — Browser caches
s19_browser_caches() {
  header "[19] Browser caches"
  warn "This invalidates browser caches (next page loads will be slower)."
  if ! confirm "Proceed with browser cache cleanup?"; then mark_done 19; return 0; fi

  # Chrome
  local d
  for d in \
    "$HOME/Library/Caches/com.google.Chrome" \
    "$HOME/Library/Application Support/Google/Chrome/Default/Cache" \
    "$HOME/Library/Application Support/Google/Chrome/Default/Code Cache" \
    "$HOME/Library/Caches/com.google.Chrome.helper"; do
    [[ -d "$d" ]] && clean_dir_contents "$d"
  done
  # Firefox
  for d in \
    "$HOME/Library/Caches/org.mozilla.firefox" \
    "$HOME/Library/Caches/Firefox"; do
    [[ -d "$d" ]] && clean_dir_contents "$d"
  done
  if [[ -d "$HOME/Library/Application Support/Firefox/Profiles" ]]; then
    while IFS= read -r d; do
      [[ -d "$d/cache2" ]] && clean_dir_contents "$d/cache2"
    done < <(find "$HOME/Library/Application Support/Firefox/Profiles" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
  fi
  # Brave
  for d in \
    "$HOME/Library/Caches/BraveSoftware" \
    "$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/Cache" \
    "$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/Code Cache"; do
    [[ -d "$d" ]] && clean_dir_contents "$d"
  done
  # Arc
  for d in "$HOME/Library/Caches/Company/Arc" "$HOME/Library/Caches/com.thebrowser.Browser"; do
    [[ -d "$d" ]] && clean_dir_contents "$d"
  done
  # Edge
  for d in \
    "$HOME/Library/Caches/com.microsoft.edgemac" \
    "$HOME/Library/Application Support/Microsoft Edge/Default/Cache"; do
    [[ -d "$d" ]] && clean_dir_contents "$d"
  done
  info "Safari caches: clear via Safari → Develop → Empty Caches (or Settings → Privacy)."
  mark_done 19; press_enter
}

# Section 20 — DNS / network reset
s20_dns_reset() {
  header "[20] DNS & mDNS reset"
  if ! require_sudo "DNS reset"; then mark_done 20; return 0; fi
  if (( DRY_RUN )); then
    note "[dry-run] dscacheutil -flushcache; killall -HUP mDNSResponder; ipconfig set en0 DHCP"
  else
    sudo dscacheutil -flushcache 2>/dev/null && ok "DNS cache flushed"
    sudo killall -HUP mDNSResponder 2>/dev/null && ok "mDNSResponder restarted"
    if ifconfig en0 >/dev/null 2>&1; then
      sudo ipconfig set en0 DHCP 2>/dev/null && ok "DHCP renewed on en0"
    fi
  fi
  mark_done 20; press_enter
}

# Section 21 — Apps unused N+ days
s21_unused_apps() {
  header "[21] Apps unused for ${UNUSED_APP_THRESHOLD_DAYS}+ days"
  local _t
  _t=$(prompt_int "Days threshold (apps idle ≥ this are flagged)" "$UNUSED_APP_THRESHOLD_DAYS")
  UNUSED_APP_THRESHOLD_DAYS="$_t"
  info "Reading last-used timestamps from Spotlight metadata. Threshold: ${UNUSED_APP_THRESHOLD_DAYS} days."
  local apps_file results
  apps_file=$(tmp_file); results=$(tmp_file)
  : > "$apps_file"; : > "$results"

  local app_dir
  for app_dir in /Applications /Applications/Utilities "$HOME/Applications"; do
    [[ -d "$app_dir" ]] || continue
    find "$app_dir" -maxdepth 2 -name "*.app" -type d 2>/dev/null >> "$apps_file"
  done

  local now last_epoch days_idle bid name app size_kb_v
  now=$(date +%s)

  # We need at least one usable signal per app; if every signal is null we
  # SKIP it (Spotlight may be re-indexing — better to under-flag than to
  # falsely uninstall an app the user actually uses).
  local skipped=0 evaluated=0
  while IFS= read -r app; do
    [[ -z "$app" ]] && continue
    name=$(basename "$app" .app)
    bid=$(defaults read "$app/Contents/Info" CFBundleIdentifier 2>/dev/null || echo "")
    [[ -z "$bid" ]] && continue
    is_apple_bundle "$bid" && continue
    evaluated=$(( evaluated + 1 ))

    local last_epoch=0 source="unknown" last_str=""
    # 1) Spotlight last-used (best signal when present)
    last_str=$(mdls -name kMDItemLastUsedDate -raw "$app" 2>/dev/null || echo "(null)")
    if [[ -n "$last_str" && "$last_str" != "(null)" ]]; then
      last_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S %z" "$last_str" +%s 2>/dev/null || echo 0)
      [[ "$last_epoch" != "0" ]] && source="spotlight"
    fi
    # 2) Saved Application State mtime (updates on every launch)
    if (( last_epoch == 0 )); then
      local sav="$HOME/Library/Saved Application State/$bid.savedState"
      if [[ -e "$sav" ]]; then
        last_epoch=$(stat -f %m "$sav" 2>/dev/null || echo 0)
        [[ "$last_epoch" != "0" ]] && source="savedstate"
      fi
    fi
    # 3) Container mtime (sandboxed apps)
    if (( last_epoch == 0 )); then
      local ctr="$HOME/Library/Containers/$bid"
      if [[ -d "$ctr" ]]; then
        last_epoch=$(stat -f %m "$ctr" 2>/dev/null || echo 0)
        [[ "$last_epoch" != "0" ]] && source="container"
      fi
    fi
    # 4) Preferences plist mtime
    if (( last_epoch == 0 )); then
      local pref="$HOME/Library/Preferences/$bid.plist"
      if [[ -e "$pref" ]]; then
        last_epoch=$(stat -f %m "$pref" 2>/dev/null || echo 0)
        [[ "$last_epoch" != "0" ]] && source="prefs"
      fi
    fi
    # 5) Spotlight kMDItemUseCount (>0 means launched at least once even if date null)
    if (( last_epoch == 0 )); then
      local uc; uc=$(mdls -name kMDItemUseCount -raw "$app" 2>/dev/null || echo "(null)")
      if [[ "$uc" != "(null)" && "$uc" =~ ^[0-9]+$ && "$uc" -gt 0 ]]; then
        # We know it's been used but don't know when — skip rather than flag.
        skipped=$(( skipped + 1 ))
        continue
      fi
    fi

    if (( last_epoch == 0 )); then
      # No signal at all. Skip rather than falsely flag.
      skipped=$(( skipped + 1 ))
      continue
    fi

    days_idle=$(( (now - last_epoch) / 86400 ))
    if (( days_idle >= UNUSED_APP_THRESHOLD_DAYS )); then
      size_kb_v=$(size_kb "$app")
      last_str=$(date -r "$last_epoch" '+%Y-%m-%d' 2>/dev/null || echo "?")
      printf '%d\t%d\t%s\t%s\t%s (%s)\t%s\n' \
        "$days_idle" "$size_kb_v" "$bid" "$name" "$last_str" "$source" "$app" >> "$results"
    fi
  done < "$apps_file"
  note "Evaluated ${evaluated} apps; skipped ${skipped} with no usable last-used signal."

  if [[ ! -s "$results" ]]; then
    ok "No apps idle ≥${UNUSED_APP_THRESHOLD_DAYS} days."
    mark_done 21; press_enter; return 0
  fi

  sort -t$'\t' -k1,1 -nr "$results" -o "$results"
  local _have_report=0
  if init_report_file "$UNUSED_APPS_REPORT" "apps unused ${UNUSED_APP_THRESHOLD_DAYS}+ days"; then
    _have_report=1
    printf '# Threshold: %d days idle\n' "$UNUSED_APP_THRESHOLD_DAYS" >> "$UNUSED_APPS_REPORT"
    printf 'days_idle\tsize\tbundle_id\tname\tlast_used\tpath\n' >> "$UNUSED_APPS_REPORT"
  fi

  printf '\n%bIdle apps:%b\n' "$BOLD" "$NC"
  printf '   %-5s  %-9s  %-40s  %s\n' "DAYS" "SIZE" "NAME" "LAST USED"
  printf '   %s\n' "──────────────────────────────────────────────────────────────────────"

  declare -a uapps=() unames=() ubids=() upaths=() usizes=()
  local line d sz_kb b nm last p
  while IFS=$'\t' read -r d sz_kb b nm last p; do
    uapps+=("$p"); unames+=("$nm"); ubids+=("$b"); upaths+=("$p"); usizes+=("$sz_kb")
    printf '   %-5s  %-9s  %-40s  %s\n' "$d" "$(human_kb "$sz_kb")" "${nm:0:40}" "$last"
    if (( _have_report )); then
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$d" "$(human_kb "$sz_kb")" "$b" "$nm" "$last" "$p" >> "$UNUSED_APPS_REPORT"
    fi
  done < "$results"
  if (( _have_report )); then info "Saved report to $UNUSED_APPS_REPORT"; fi

  if (( BATCH_MODE && ! ASSUME_YES )); then
    note "Batch mode: report-only."
    mark_done 21; press_enter; return 0
  fi

  local n=${#uapps[@]}
  local mode="" mode_reply
  if (( ASSUME_YES )); then
    mode="bulk"
  else
    printf '\n%bChoose action:%b\n' "$BOLD" "$NC"
    printf '   %b[R]%b Review one-by-one (inspect companion data per app)\n' "$CYAN" "$NC"
    printf '   %b[B]%b Bulk select by number (multi-select)\n' "$CYAN" "$NC"
    printf '   %b[N]%b Skip — keep all\n' "$CYAN" "$NC"
    printf '%bChoice [R/B/N]:%b ' "$BOLD" "$NC"
    read -r mode_reply || mode_reply=""
    case "$mode_reply" in
      [bB]*) mode="bulk" ;;
      [nN]*|"") mode="skip" ;;
      *) mode="review" ;;
    esac
  fi
  if [[ "$mode" == "skip" ]]; then
    info "No apps selected."
    mark_done 21; press_enter; return 0
  fi

  # Helper: gather companion-data paths for one app into a global $_data_paths array.
  _gather_app_data_paths() {
    _data_paths=()
    local app_name="$1" app_bid="$2" candidate
    for candidate in \
      "$HOME/Library/Application Support/$app_name" \
      "$HOME/Library/Application Support/$app_bid" \
      "$HOME/Library/Containers/$app_bid" \
      "$HOME/Library/Caches/$app_bid" \
      "$HOME/Library/Caches/$app_name" \
      "$HOME/Library/Preferences/$app_bid.plist" \
      "$HOME/Library/Logs/$app_name" \
      "$HOME/Library/Saved Application State/$app_bid.savedState" \
      "$HOME/Library/LaunchAgents/$app_bid.plist" \
      "$HOME/Library/HTTPStorages/$app_bid" \
      "$HOME/Library/HTTPStorages/$app_bid.binarycookies" \
      "$HOME/Library/WebKit/$app_bid"; do
      [[ -e "$candidate" ]] && _data_paths+=("$candidate")
    done
    while IFS= read -r candidate; do
      [[ -e "$candidate" ]] && _data_paths+=("$candidate")
    done < <(find "$HOME/Library/Group Containers" -maxdepth 1 -name "*$app_bid*" 2>/dev/null)
  }

  # Helper: uninstall a single app + its companion data, tracking freed KB.
  _uninstall_app() {
    local app_path="$1" app_name="$2" app_size_kb="$3"
    local dp kb
    if (( DRY_RUN )); then
      note "[dry-run] would move $app_path to Trash and rm ${#_data_paths[@]} data path(s)"
      return 0
    fi
    if osascript_trash "$app_path"; then
      ok "Moved $app_name to Trash"
      TOTAL_FREED_KB=$(( TOTAL_FREED_KB + app_size_kb ))
    else
      warn "Finder move failed; trying rm -rf"
      if rm -rf -- "$app_path" 2>/dev/null; then
        ok "Removed $app_name"
        TOTAL_FREED_KB=$(( TOTAL_FREED_KB + app_size_kb ))
      else
        warn "Could not remove $app_path (permission?)"
      fi
    fi
    for dp in "${_data_paths[@]+"${_data_paths[@]}"}"; do
      kb=$(size_kb "$dp")
      if rm -rf -- "$dp" 2>/dev/null; then
        TOTAL_FREED_KB=$(( TOTAL_FREED_KB + kb ))
      else
        warn "Could not remove $dp"
      fi
    done
  }

  if [[ "$mode" == "bulk" ]]; then
    local selected
    selected=$(multi_select "$n")
    if [[ -z "$selected" ]]; then
      note "Nothing selected."
      mark_done 21; press_enter; return 0
    fi
    # Compute total to be reclaimed (app + companion data)
    local idx pos sel_total_kb=0 sel_count=0
    while IFS= read -r idx; do
      pos=$(( idx - 1 ))
      _gather_app_data_paths "${unames[$pos]}" "${ubids[$pos]}"
      local data_kb=0 dp_kb
      local _dp
      for _dp in "${_data_paths[@]+"${_data_paths[@]}"}"; do
        dp_kb=$(size_kb "$_dp"); data_kb=$(( data_kb + dp_kb ))
      done
      sel_total_kb=$(( sel_total_kb + ${usizes[$pos]} + data_kb ))
      sel_count=$(( sel_count + 1 ))
    done <<<"$selected"

    printf '\n%bAbout to uninstall %d app(s) — total reclaim ~ %s%b\n' \
      "$BOLD" "$sel_count" "$(human_kb "$sel_total_kb")" "$NC"
    if ! (( ASSUME_YES )); then
      if ! confirm_yes "Confirm bulk uninstall?"; then
        info "Aborted."
        mark_done 21; press_enter; return 0
      fi
    fi
    while IFS= read -r idx; do
      pos=$(( idx - 1 ))
      _gather_app_data_paths "${unames[$pos]}" "${ubids[$pos]}"
      printf '\n%b▸ %s%b  (%s)\n' "$CYAN" "${unames[$pos]}" "$NC" "${upaths[$pos]}"
      _uninstall_app "${upaths[$pos]}" "${unames[$pos]}" "${usizes[$pos]}"
    done <<<"$selected"
    mark_done 21; press_enter; return 0
  fi

  # mode == review (one-by-one with per-app companion-data inspection)
  local i reply
  for (( i=0; i<n; i++ )); do
    local app_path="${upaths[$i]}"
    local app_name="${unames[$i]}"
    local app_bid="${ubids[$i]}"
    local app_size_kb="${usizes[$i]}"
    printf '\n%b[%d/%d] %s%b\n' "$CYAN$BOLD" "$((i+1))" "$n" "$app_name" "$NC"
    printf '   bundle:    %s\n' "$app_bid"
    printf '   path:      %s\n' "$app_path"
    printf '   .app size: %s\n' "$(human_kb "$app_size_kb")"

    _gather_app_data_paths "$app_name" "$app_bid"
    local data_kb=0 dp
    for dp in "${_data_paths[@]+"${_data_paths[@]}"}"; do
      data_kb=$(( data_kb + $(size_kb "$dp") ))
    done
    local total_kb=$(( app_size_kb + data_kb ))
    printf '   data size: %s (%d paths)\n' "$(human_kb "$data_kb")" "${#_data_paths[@]}"
    printf '   %btotal:     %s%b\n' "$BOLD" "$(human_kb "$total_kb")" "$NC"

    printf '%bUninstall? [y/N/d=show data paths/q=quit]%b ' "$BOLD" "$NC"
    read -r reply || reply=""
    case "$reply" in
      [dD]*)
        for dp in "${_data_paths[@]+"${_data_paths[@]}"}"; do printf '     %s\n' "$dp"; done
        printf '%bUninstall now? [y/N]%b ' "$BOLD" "$NC"
        read -r reply || reply=""
        ;;
      [qQ]*) info "Stopped at $((i+1))."; break ;;
    esac

    if [[ "$reply" =~ ^[yY] ]]; then
      _uninstall_app "$app_path" "$app_name" "$app_size_kb"
      ok "Reclaimed ~$(human_kb "$total_kb")"
    else
      note "Skipped"
    fi
  done

  mark_done 21; press_enter
}

# Section 22 — Purgeable space trigger
s22_purgeable_trigger() {
  header "[22] Purgeable space trigger"
  info "Forcing macOS to release purgeable space by briefly creating + deleting a temp file."
  local tmp="$LOG_DIR/.purgeable-bait"
  if (( DRY_RUN )); then
    note "[dry-run] would mkfile -n 1g + rm"
    mark_done 22; return 0
  fi
  if has_cmd mkfile; then
    if mkfile -n 1g "$tmp" 2>/dev/null; then
      sleep 1
      rm -f "$tmp"
      ok "Triggered purgeable-space release."
    else
      note "Not enough free space to allocate 1G bait — skipping."
    fi
  else
    note "mkfile unavailable — skipping."
  fi
  mark_done 22; press_enter
}

# Section 23 — Stale regenerable build artefacts (node_modules, vendor, …)
# Find directories matching STALE_BUILD_PATTERNS that haven't been modified
# in N days. They can always be rebuilt by re-running the project's install
# or build, so deleting old ones is normally safe.
s23_stale_builds() {
  header "[23] Stale build artefacts (node_modules, vendor, dist, build, .next, target, …)"
  info "Find regenerable dev directories untouched (atime+mtime) for a while."
  printf '   %bPatterns:%b %s\n' "$DIM" "$NC" "${STALE_BUILD_PATTERNS[*]}"

  # 4.3.3: default the per-section threshold to IDLE_THRESHOLD_DAYS so
  # `--idle-days N` flows through here too. The dedicated
  # --stale-build-days N still wins if the user passes it explicitly.
  local days
  if [[ "$STALE_BUILD_THRESHOLD_DAYS" == "$STALE_BUILD_THRESHOLD_DAYS_DEFAULT" ]]; then
    STALE_BUILD_THRESHOLD_DAYS="$IDLE_THRESHOLD_DAYS"
  fi
  days=$(prompt_int "Days threshold — flag dirs untouched (atime+mtime) ≥ this" "$STALE_BUILD_THRESHOLD_DAYS")
  STALE_BUILD_THRESHOLD_DAYS="$days"

  # Pick scan roots: --scan-roots override, OR common dev folders only.
  # We deliberately DO NOT fall back to scanning all of $HOME — see the
  # 4.3.0 -> 4.3.1 SAFETY FIX in CHANGELOG.md.
  local roots=()
  while IFS= read -r _r; do roots+=("$_r"); done < <(resolve_scan_roots)
  if (( ${#roots[@]} == 0 )); then
    warn "No common dev folder detected (~/Projects, ~/Code, ~/Developer, ~/dev, ~/repos, ~/work, ~/Documents, ~/Desktop, ~/Downloads)."
    note "To scan a specific path, re-run with:"
    note "    mac-cleanup --only 23 --scan-roots \"\$HOME/path/to/dev\""
    note "Refusing to scan all of \$HOME — that risks deleting toolchain"
    note "directories (~/.nvm, ~/.bun, ~/.pnpm-store, etc.)."
    mark_done 23; press_enter; return 0
  fi

  printf '\n%bScan roots:%b\n' "$BOLD" "$NC"
  local r; for r in "${roots[@]}"; do printf '   • %s\n' "$r"; done
  printf '%bAge filter:%b directories whose atime AND mtime are both ≥ %d days old\n\n' "$BOLD" "$NC" "$days"

  if ! confirm "Proceed with scan?" 1; then mark_done 23; return 0; fi
  info "Scanning… (large trees can take a minute)"

  # Build the -name OR-clause for the find call
  local find_names=() i p
  for i in "${!STALE_BUILD_PATTERNS[@]}"; do
    p="${STALE_BUILD_PATTERNS[$i]}"
    if (( i == 0 )); then find_names+=( -name "$p" )
    else                  find_names+=( -o -name "$p" ); fi
  done

  # Build CRITICAL_HOME_DIRS exclude args. Each entry expands to a pair
  # of `! -path` predicates: one matches the dir literally (e.g. ~/.bun),
  # the other matches anything underneath (~/.bun/...). This is what
  # prevents the 4.3.0 bug from ever recurring.
  local critical_excludes=() _excl
  for _excl in "${CRITICAL_HOME_DIRS[@]}"; do
    critical_excludes+=( ! -path "$HOME/$_excl" ! -path "$HOME/$_excl/*" )
  done

  local results; results=$(tmp_file); : > "$results"
  for r in "${roots[@]}"; do
    find "$r" -type d \
      ! -path "*/Library/CloudStorage/*" \
      ! -path "*/Library/Mobile Documents/*" \
      ! -path "*/.Trash/*" \
      ! -path "$HOME/Library" \
      ! -path "$HOME/Library/*" \
      "${critical_excludes[@]}" \
      \( "${find_names[@]}" \) -prune -atime "+$days" -mtime "+$days" \
      -print 2>/dev/null >> "$results" || true
  done

  if [[ ! -s "$results" ]]; then
    ok "No stale build artefacts found older than ${days} days."
    mark_done 23; press_enter; return 0
  fi

  # Belt-and-braces post-filter: even if find slipped past the path
  # excludes for any reason, drop any candidate whose absolute path
  # touches a CRITICAL_HOME_DIRS entry. This is a final safety net.
  is_in_critical_home_dir() {
    local p="$1" e
    for e in "${CRITICAL_HOME_DIRS[@]}"; do
      [[ "$p" == "$HOME/$e" || "$p" == "$HOME/$e/"* ]] && return 0
    done
    return 1
  }

  # Materialise items + sort by size (largest first)
  declare -a items_path=() items_kb=() items_age=()
  local total_kb=0 now epoch d_age path sz_kb skipped=0
  now=$(date +%s)
  while IFS= read -r path; do
    [[ -d "$path" ]] || continue
    if is_in_critical_home_dir "$path"; then
      skipped=$(( skipped + 1 ))
      continue
    fi
    sz_kb=$(size_kb "$path")
    epoch=$(stat -f %m "$path" 2>/dev/null || echo 0)
    if (( epoch > 0 )); then d_age=$(( (now - epoch) / 86400 )); else d_age=$days; fi
    items_path+=("$path"); items_kb+=("$sz_kb"); items_age+=("$d_age")
    total_kb=$(( total_kb + sz_kb ))
  done < "$results"
  if (( skipped > 0 )); then
    note "Skipped $skipped candidate(s) inside protected toolchain/config dirs."
  fi

  local n=${#items_path[@]}
  if (( n == 0 )); then
    ok "No stale build artefacts found."
    mark_done 23; press_enter; return 0
  fi

  local order; order=$(tmp_file); : > "$order"
  for i in "${!items_path[@]}"; do
    printf '%s\t%s\n' "${items_kb[$i]}" "$i" >> "$order"
  done
  sort -t$'\t' -k1,1 -nr "$order" -o "$order"

  local _have_report=0
  if init_report_file "$STALE_BUILD_REPORT" "stale build artefacts (>${days} days)"; then
    _have_report=1
    printf '# Threshold: directories untouched ≥%d days\n' "$days" >> "$STALE_BUILD_REPORT"
    printf 'size\tage_days\tpath\n' >> "$STALE_BUILD_REPORT"
  fi

  printf '\n%bStale dev artefacts: %d  •  Total size: %s%b\n' \
    "$BOLD" "$n" "$(human_kb "$total_kb")" "$NC"
  printf '   %-4s  %-9s  %-7s  %s\n' '#' 'SIZE' 'AGE(d)' 'PATH'
  printf '   %s\n' "──────────────────────────────────────────────────────────────────────"

  declare -a ordered_idx=()
  local rownum=1 sorted_idx
  while IFS=$'\t' read -r _ sorted_idx; do
    ordered_idx+=("$sorted_idx")
    printf '   %-4d  %-9s  %-7d  %s\n' \
      "$rownum" "$(human_kb "${items_kb[$sorted_idx]}")" "${items_age[$sorted_idx]}" "${items_path[$sorted_idx]}"
    if (( _have_report )); then
      printf '%s\t%d\t%s\n' \
        "$(human_kb "${items_kb[$sorted_idx]}")" "${items_age[$sorted_idx]}" "${items_path[$sorted_idx]}" >> "$STALE_BUILD_REPORT"
    fi
    rownum=$(( rownum + 1 ))
  done < "$order"
  if (( _have_report )); then info "Saved report to $STALE_BUILD_REPORT"; fi

  if (( BATCH_MODE && ! ASSUME_YES )); then
    note "Batch mode: report-only."
    mark_done 23; press_enter; return 0
  fi

  local selected; selected=$(multi_select "$n")
  if [[ -z "$selected" ]]; then
    note "Nothing selected."
    mark_done 23; press_enter; return 0
  fi

  local idx pos sel_total_kb=0 sel_count=0
  while IFS= read -r idx; do
    pos=$(( idx - 1 )); sorted_idx="${ordered_idx[$pos]}"
    sel_total_kb=$(( sel_total_kb + ${items_kb[$sorted_idx]} ))
    sel_count=$(( sel_count + 1 ))
  done <<<"$selected"

  printf '\n%bAbout to delete %d directories totalling %s%b\n' \
    "$BOLD" "$sel_count" "$(human_kb "$sel_total_kb")" "$NC"
  if ! (( ASSUME_YES )); then
    if ! confirm_yes "Confirm bulk delete (these are regenerable, not in Trash)?"; then
      info "Aborted."
      mark_done 23; press_enter; return 0
    fi
  fi

  while IFS= read -r idx; do
    pos=$(( idx - 1 )); sorted_idx="${ordered_idx[$pos]}"
    local p="${items_path[$sorted_idx]}" k="${items_kb[$sorted_idx]}"
    if (( DRY_RUN )); then
      note "[dry-run] rm -rf $p"
    else
      if safe_rm_rf "$p"; then
        TOTAL_FREED_KB=$(( TOTAL_FREED_KB + k ))
        ok "Deleted $p"
      else
        warn "Failed to delete $p"
      fi
    fi
  done <<<"$selected"

  mark_done 23; press_enter
}

# Section 24 — Large stale files (>= N GB unused for M+ days)
# Conservative "unused": both atime AND mtime older than threshold so we
# don't false-flag files you've recently opened (atime) or written (mtime).
s24_large_stale() {
  header "[24] Large stale files (≥ N GB, unused N+ days)"
  info "Find big files in your home tree that you haven't accessed or modified for a long time."

  local size_gb days
  size_gb=$(prompt_int "Min size in GB" "$LARGE_FILE_SIZE_GB")
  LARGE_FILE_SIZE_GB="$size_gb"
  days=$(prompt_int "Days unused (atime AND mtime)" "$LARGE_FILE_THRESHOLD_DAYS")
  LARGE_FILE_THRESHOLD_DAYS="$days"

  local size_arg="+$(( size_gb * 1024 ))M"

  printf '\n%bScan root:%b %s\n' "$BOLD" "$NC" "$HOME"
  printf '%bThreshold:%b ≥ %d GB AND not accessed/modified in ≥ %d days\n\n' \
    "$BOLD" "$NC" "$size_gb" "$days"

  if ! confirm "Proceed with scan?" 1; then mark_done 24; return 0; fi
  info "Scanning… (this may take a few minutes for large home directories)"

  local results; results=$(tmp_file); : > "$results"
  find "$HOME" -type f -size "$size_arg" -atime "+$days" -mtime "+$days" \
    ! -path "*/Library/CloudStorage/*" \
    ! -path "*/Library/Mobile Documents/*" \
    ! -path "*.photoslibrary/*" \
    ! -path "*/Library/Photos/*" \
    ! -path "*/.Trash/*" \
    ! -path "*/Virtual Machines/*" \
    ! -path "*/Parallels/*" \
    ! -path "*/VMware/*" \
    -print 2>/dev/null > "$results" || true

  if [[ ! -s "$results" ]]; then
    ok "No large stale files found (≥ ${size_gb} GB, ≥ ${days} days idle)."
    mark_done 24; press_enter; return 0
  fi

  declare -a items_path=() items_kb=() items_age=()
  local total_kb=0 now atime mtime newer age path sz_kb i
  now=$(date +%s)
  while IFS= read -r path; do
    [[ -f "$path" ]] || continue
    sz_kb=$(size_kb "$path")
    atime=$(stat -f %a "$path" 2>/dev/null || echo 0)
    mtime=$(stat -f %m "$path" 2>/dev/null || echo 0)
    newer=$atime; (( mtime > newer )) && newer=$mtime
    if (( newer > 0 )); then age=$(( (now - newer) / 86400 )); else age=$days; fi
    items_path+=("$path"); items_kb+=("$sz_kb"); items_age+=("$age")
    total_kb=$(( total_kb + sz_kb ))
  done < "$results"

  local n=${#items_path[@]}
  if (( n == 0 )); then
    ok "No large stale files found."
    mark_done 24; press_enter; return 0
  fi

  local order; order=$(tmp_file); : > "$order"
  for i in "${!items_path[@]}"; do
    printf '%s\t%s\n' "${items_kb[$i]}" "$i" >> "$order"
  done
  sort -t$'\t' -k1,1 -nr "$order" -o "$order"

  local _have_report=0
  if init_report_file "$LARGE_STALE_REPORT" "large stale files ≥${size_gb}GB ≥${days}d"; then
    _have_report=1
    printf '# Threshold: files ≥%d GB and not accessed/modified in ≥%d days\n' "$size_gb" "$days" >> "$LARGE_STALE_REPORT"
    printf 'size\tage_days\tpath\n' >> "$LARGE_STALE_REPORT"
  fi

  printf '\n%bLarge stale files: %d  •  Total: %s%b\n' \
    "$BOLD" "$n" "$(human_kb "$total_kb")" "$NC"
  printf '   %-4s  %-9s  %-7s  %s\n' '#' 'SIZE' 'AGE(d)' 'PATH'
  printf '   %s\n' "──────────────────────────────────────────────────────────────────────"

  declare -a ordered_idx=()
  local rownum=1 sorted_idx
  while IFS=$'\t' read -r _ sorted_idx; do
    ordered_idx+=("$sorted_idx")
    printf '   %-4d  %-9s  %-7d  %s\n' \
      "$rownum" "$(human_kb "${items_kb[$sorted_idx]}")" "${items_age[$sorted_idx]}" "${items_path[$sorted_idx]}"
    if (( _have_report )); then
      printf '%s\t%d\t%s\n' \
        "$(human_kb "${items_kb[$sorted_idx]}")" "${items_age[$sorted_idx]}" "${items_path[$sorted_idx]}" >> "$LARGE_STALE_REPORT"
    fi
    rownum=$(( rownum + 1 ))
  done < "$order"
  if (( _have_report )); then info "Saved report to $LARGE_STALE_REPORT"; fi

  if (( BATCH_MODE && ! ASSUME_YES )); then
    note "Batch mode: report-only."
    mark_done 24; press_enter; return 0
  fi

  local selected; selected=$(multi_select "$n")
  if [[ -z "$selected" ]]; then
    note "Nothing selected."
    mark_done 24; press_enter; return 0
  fi

  local idx pos sel_total_kb=0 sel_count=0
  while IFS= read -r idx; do
    pos=$(( idx - 1 )); sorted_idx="${ordered_idx[$pos]}"
    sel_total_kb=$(( sel_total_kb + ${items_kb[$sorted_idx]} ))
    sel_count=$(( sel_count + 1 ))
  done <<<"$selected"

  printf '\n%bAbout to move %d file(s) totalling %s to Trash%b\n' \
    "$BOLD" "$sel_count" "$(human_kb "$sel_total_kb")" "$NC"
  if ! (( ASSUME_YES )); then
    if ! confirm_yes "Confirm move-to-Trash?"; then
      info "Aborted."
      mark_done 24; press_enter; return 0
    fi
  fi

  while IFS= read -r idx; do
    pos=$(( idx - 1 )); sorted_idx="${ordered_idx[$pos]}"
    local p="${items_path[$sorted_idx]}" k="${items_kb[$sorted_idx]}"
    if osascript_trash "$p"; then
      if ! (( DRY_RUN )); then
        TOTAL_FREED_KB=$(( TOTAL_FREED_KB + k ))
        ok "Trashed $p"
      fi
    else
      warn "Finder move failed for: $p (kept)"
    fi
  done <<<"$selected"

  mark_done 24; press_enter
}

# Section 25 — LaunchAgents / LaunchDaemons audit
# Inspect every .plist in the standard launch-item locations, extract its
# Program / ProgramArguments target, and flag entries whose target binary
# no longer exists (or whose AssociatedBundleIdentifiers point to an
# uninstalled app). These are a common source of slow login + zombie
# background processes.
s25_launchitems() {
  header "[25] LaunchAgents / LaunchDaemons audit"
  info "Looking for login items whose target binary is missing."

  local locations=(
    "$HOME/Library/LaunchAgents"
    "/Library/LaunchAgents"
    "/Library/LaunchDaemons"
  )
  local plists=() loc plist
  for loc in "${locations[@]}"; do
    [[ -d "$loc" ]] || continue
    while IFS= read -r plist; do plists+=("$plist"); done \
      < <(find "$loc" -maxdepth 1 -type f -name '*.plist' 2>/dev/null)
  done
  if (( ${#plists[@]} == 0 )); then
    info "No launch items found in standard locations."
    mark_done 25; press_enter; return 0
  fi

  declare -a stale_path=() stale_label=() stale_target=()
  local label target prog first_arg
  for plist in "${plists[@]}"; do
    label=""
    target=""
    if has_cmd plutil; then
      label=$(plutil -extract Label raw -o - "$plist" 2>/dev/null || true)
      prog=$(plutil -extract Program raw -o - "$plist" 2>/dev/null || true)
      first_arg=$(plutil -extract 'ProgramArguments.0' raw -o - "$plist" 2>/dev/null || true)
      [[ -n "$prog" && "$prog" != "(null)" ]] && target="$prog"
      [[ -z "$target" && -n "$first_arg" && "$first_arg" != "(null)" ]] && target="$first_arg"
    fi
    if [[ -z "$target" ]]; then
      # Fallback: grep raw plist bytes for a /-rooted path
      target=$(strings "$plist" 2>/dev/null \
        | awk '/^\/[^ ]+/ && length($0) < 256 {print; exit}' || true)
    fi
    [[ -z "$target" ]] && continue
    # Strip any trailing arg-list noise
    target="${target%% *}"
    if [[ "$target" == /* && ! -e "$target" ]]; then
      stale_path+=("$plist")
      stale_label+=("${label:-?}")
      stale_target+=("$target")
    fi
  done

  if (( ${#stale_path[@]} == 0 )); then
    ok "No stale launch items found."
    mark_done 25; press_enter; return 0
  fi

  printf '\n%bStale launch items: %d%b\n' "$BOLD" "${#stale_path[@]}" "$NC"
  printf '   %-4s  %s\n' '#' 'PLIST  →  MISSING TARGET  (label)'
  printf '   %s\n' "──────────────────────────────────────────────────────────────────────"
  local _have_report=0
  if init_report_file "$LAUNCH_AUDIT_REPORT" "LaunchAgents / LaunchDaemons audit"; then
    _have_report=1
    printf 'plist\tlabel\tmissing_target\n' >> "$LAUNCH_AUDIT_REPORT"
  fi
  local i
  for (( i=0; i<${#stale_path[@]}; i++ )); do
    printf '   %-4d  %s\n' "$((i+1))" "${stale_path[$i]}"
    printf '         → %s   %b(%s)%b\n' "${stale_target[$i]}" "$DIM" "${stale_label[$i]}" "$NC"
    if (( _have_report )); then
      printf '%s\t%s\t%s\n' "${stale_path[$i]}" "${stale_label[$i]}" "${stale_target[$i]}" >> "$LAUNCH_AUDIT_REPORT"
    fi
  done
  if (( _have_report )); then info "Saved report to $LAUNCH_AUDIT_REPORT"; fi

  if (( BATCH_MODE && ! ASSUME_YES )); then
    note "Batch mode: report-only."
    mark_done 25; press_enter; return 0
  fi

  warn "Removing a system launch item under /Library may need sudo."
  warn "Unloading + deleting prevents the orphaned item from running again."
  local selected; selected=$(multi_select "${#stale_path[@]}")
  if [[ -z "$selected" ]]; then
    note "Nothing selected."
    mark_done 25; press_enter; return 0
  fi

  local idx pos p l
  while IFS= read -r idx; do
    pos=$(( idx - 1 ))
    p="${stale_path[$pos]}"
    l="${stale_label[$pos]}"
    if (( DRY_RUN )); then
      note "[dry-run] launchctl unload + rm $p"
      continue
    fi
    case "$p" in
      /Library/*)
        if require_sudo "remove $p"; then
          [[ -n "$l" && "$l" != "?" ]] && sudo launchctl unload -w "$p" 2>/dev/null || true
          if sudo rm -f -- "$p"; then ok "Removed $p"; else warn "Failed: $p"; fi
        fi ;;
      *)
        [[ -n "$l" && "$l" != "?" ]] && launchctl unload -w "$p" 2>/dev/null || true
        if rm -f -- "$p"; then ok "Removed $p"; else warn "Failed: $p"; fi ;;
    esac
  done <<<"$selected"

  mark_done 25; press_enter
}

# Section 26 — Disk usage report (advisory)
# Cheap, fast diagnostic that points at the heaviest folders in $HOME
# and ~/Library. Read-only; no deletion. Helps you decide which sections
# to run next.
s26_du_report() {
  header "[26] Disk usage report ($HOME & ~/Library)"
  info "Computing top space consumers (up to ~30s on large home dirs)."

  local _have_report=0
  if init_report_file "$DU_REPORT" "disk usage snapshot ($HOME & ~/Library)"; then
    _have_report=1
  fi

  local _scan; _scan=$(tmp_file)

  printf '\n%bTop $HOME children:%b\n' "$BOLD" "$NC"
  du -sh "$HOME"/* "$HOME"/.* 2>/dev/null \
    | grep -v -E '^[^ 	]+[ 	]+(\.|\.\.)$' \
    | sort -h \
    | tail -20 > "$_scan"
  sed 's/^/   /' "$_scan"
  if (( _have_report )); then
    {
      printf '## Top $HOME children (largest at the bottom)\n'
      cat "$_scan"
      printf '\n'
    } >> "$DU_REPORT"
  fi

  if [[ -d "$HOME/Library" ]]; then
    printf '\n%bTop ~/Library children:%b\n' "$BOLD" "$NC"
    du -sh "$HOME/Library"/* 2>/dev/null \
      | sort -h \
      | tail -20 > "$_scan"
    sed 's/^/   /' "$_scan"
    if (( _have_report )); then
      {
        printf '## Top ~/Library children\n'
        cat "$_scan"
        printf '\n'
      } >> "$DU_REPORT"
    fi
  fi

  printf '\n%bTip:%b\n' "$BOLD" "$NC"
  note "Library/Caches      → run section 5"
  note "Containers          → big apps storing media; review in [12] / [21]"
  note "Developer           → run sections 1, 17, 23"
  note "Application Support → run section 12 (orphan scan)"

  if (( _have_report )); then info "Saved report to $DU_REPORT"; fi

  mark_done 26; press_enter
}

# ──────────────────────────────────────────────────────────────────────────
#                              MENU / FLOW
# ──────────────────────────────────────────────────────────────────────────

# Sections that --all runs unattended (caches/logs/temp/reports only).
SAFE_BATCH=(0 3 5 7 8 9 13 15 18 22 26)

run_all_safe() {
  step "Running safe-batch sections: ${SAFE_BATCH[*]}"
  local s
  for s in "${SAFE_BATCH[@]}"; do
    case "$s" in
      0)  s00_health ;;
      3)  s03_pkg_managers ;;
      5)  s05_user_caches ;;
      7)  s07_logs ;;
      8)  s08_temp ;;
      9)  s09_update_caches ;;
      13) s13_maintenance ;;
      15) s15_installer ;;
      18) s18_large_files ;;
      22) s22_purgeable_trigger ;;
      26) s26_du_report ;;
    esac
  done
}

session_summary() {
  header "Session summary"
  local elapsed=$(( $(date +%s) - START_EPOCH ))
  DISK_FREE_AFTER_KB=$(disk_free_kb /)
  local disk_delta=0
  if [[ -n "$DISK_FREE_BEFORE_KB" && -n "$DISK_FREE_AFTER_KB" ]]; then
    disk_delta=$(( DISK_FREE_AFTER_KB - DISK_FREE_BEFORE_KB ))
    (( disk_delta < 0 )) && disk_delta=0
  fi
  printf '   Elapsed:           %ds\n' "$elapsed"
  printf '   Tracked freed:     %s\n' "$(human_kb "$TOTAL_FREED_KB")"
  printf '   Disk free Δ:       %s (root)\n' "$(human_kb "$disk_delta")"
  printf '   Sections done:     %s\n' "${COMPLETED_SECTIONS[*]:-(none)}"
  printf '   Logs dir:          %s\n' "$LOG_DIR"
  printf '   Reports dir:       %s\n' "$REPORTS_DIR"
  printf '   Today log file:    %s\n' "$LOG_FILE"
  if (( NO_REPORTS )); then
    printf '%b   Reports skipped (--no-reports)%b\n' "$DIM" "$NC"
  fi
  if (( CLEANUP_LOGS_ON_FINISH )); then
    printf '%b   Log will be removed at exit (--cleanup-logs-on-finish)%b\n' "$DIM" "$NC"
  fi
  if (( DRY_RUN )); then printf '%b   Mode: DRY-RUN — nothing was deleted.%b\n' "$YELLOW" "$NC"; fi
  printf '\n%b   %s v%s — by %s · %s%b\n' \
    "$DIM" "$SCRIPT_NAME" "$SCRIPT_VERSION" "$AUTHOR_NAME" "$PROJECT_REPO" "$NC"
}

show_menu() {
  clear 2>/dev/null || true
  local mac_ver chip ram_b ram_h disk_free_h
  mac_ver=$(sw_vers -productVersion 2>/dev/null || echo "?")
  chip=$(uname -m)
  ram_b=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
  ram_h=$(awk -v b="$ram_b" 'BEGIN{printf "%.0f GB", b/1024/1024/1024}')
  disk_free_h=$(df -h / | awk 'NR==2 {print $4}')

  printf '%b%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$BOLD" "$MAGENTA" "$NC"
  printf '%b   mac-cleanup v%s   —   macOS %s (%s)   RAM %s   Free %s%b\n' \
    "$BOLD$MAGENTA" "$SCRIPT_VERSION" "$mac_ver" "$chip" "$ram_h" "$disk_free_h" "$NC"
  if (( DRY_RUN )); then
    printf '%b   DRY-RUN MODE — nothing will be deleted%b\n' "$YELLOW" "$NC"
  fi
  printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n\n' "$BOLD$MAGENTA" "$NC"

  local LBL=()
  LBL[0]="System health & process monitor"
  LBL[1]="Xcode caches, DerivedData, simulators"
  LBL[2]="Android / Gradle caches"
  LBL[3]="Package manager caches (npm, yarn, pnpm, brew, pip, pod, flutter, cargo, go, ruby)"
  LBL[4]="Docker prune (containers/images/volumes)"
  LBL[5]="User caches (~/Library/Caches, Saved State, DiagnosticReports)"
  LBL[6]="System caches (/Library/Caches) — sudo"
  LBL[7]="Logs (user + system)"
  LBL[8]="Temp files (\$TMPDIR, /tmp, ~/tmp)"
  LBL[9]="Update caches"
  LBL[10]="Empty Trash"
  LBL[11]="Time Machine local snapshots — sudo"
  LBL[12]="Orphaned app data scan"
  LBL[13]="System maintenance (periodic) — sudo"
  LBL[14]="Deep cache /private/var/folders — sudo + REBOOT"
  LBL[15]="Installer leftovers report"
  LBL[16]="iOS / iPadOS device backups"
  LBL[17]="Xcode archives"
  LBL[18]="Large files report"
  LBL[19]="Browser caches (Chrome, Firefox, Brave, Arc, Edge)"
  LBL[20]="DNS / mDNS reset — sudo"
  LBL[21]="Apps unused ${UNUSED_APP_THRESHOLD_DAYS}+ days (review/bulk uninstall)"
  LBL[22]="Purgeable space trigger"
  LBL[23]="Stale build artefacts ${STALE_BUILD_THRESHOLD_DAYS}+ days (node_modules, vendor, dist, build, …)"
  LBL[24]="Large stale files ≥${LARGE_FILE_SIZE_GB}GB unused ${LARGE_FILE_THRESHOLD_DAYS}+ days"
  LBL[25]="LaunchAgents / LaunchDaemons audit (orphaned login items)"
  LBL[26]="Disk usage report (\$HOME & ~/Library)"

  local i mark
  for i in $(seq 0 26); do
    if is_done "$i"; then mark="${GREEN}✓${NC}"; else mark=" "; fi
    printf '   %s [%2d] %s\n' "$mark" "$i" "${LBL[$i]}"
  done
  printf '\n   %b[A]%b Run all SAFE sections (unattended)\n' "$BOLD" "$NC"
  printf '   %b[D]%b Toggle dry-run (currently: %s)\n' "$BOLD" "$NC" "$([[ $DRY_RUN -eq 1 ]] && echo ON || echo OFF)"
  printf '   %b[Y]%b Toggle assume-yes (currently: %s)\n' "$BOLD" "$NC" "$([[ $ASSUME_YES -eq 1 ]] && echo ON || echo OFF)"
  printf '   %b[S]%b Show session summary\n' "$BOLD" "$NC"
  printf '   %b[Q]%b Quit\n' "$BOLD" "$NC"
  printf '\n'
}

dispatch() {
  case "$1" in
    0)  s00_health ;;
    1)  s01_xcode ;;
    2)  s02_android ;;
    3)  s03_pkg_managers ;;
    4)  s04_docker ;;
    5)  s05_user_caches ;;
    6)  s06_system_caches ;;
    7)  s07_logs ;;
    8)  s08_temp ;;
    9)  s09_update_caches ;;
    10) s10_trash ;;
    11) s11_time_machine ;;
    12) s12_orphaned ;;
    13) s13_maintenance ;;
    14) s14_var_folders ;;
    15) s15_installer ;;
    16) s16_ios_backups ;;
    17) s17_xcode_archives ;;
    18) s18_large_files ;;
    19) s19_browser_caches ;;
    20) s20_dns_reset ;;
    21) s21_unused_apps ;;
    22) s22_purgeable_trigger ;;
    23) s23_stale_builds ;;
    24) s24_large_stale ;;
    25) s25_launchitems ;;
    26) s26_du_report ;;
    *)  warn "Unknown section: $1" ;;
  esac
}

main() {
  parse_args "$@"
  # Make sure logs/reports dirs exist after any --logs-dir / --reports-dir
  # overrides that may have been parsed from argv.
  mkdir -p "$LOG_DIR" "$REPORTS_DIR" 2>/dev/null || true
  init_log_file
  DISK_FREE_BEFORE_KB=$(disk_free_kb /)
  log_to_file "── mac-cleanup v$SCRIPT_VERSION started ──"

  # Optional opt-in update check (no telemetry).
  check_update_npm

  # Resolve --profile to an explicit section list. --only takes precedence
  # over --profile if both were given (they are still composed with
  # --exclude in the same way).
  if [[ -z "$ONLY_SECTIONS" && -n "$PROFILE_NAME" ]]; then
    ONLY_SECTIONS="$(profile_sections "$PROFILE_NAME")"
    info "Profile '$PROFILE_NAME' → sections $ONLY_SECTIONS"
  fi

  # Apply --exclude on top of --only / --profile / --all alike.
  if [[ -n "$EXCLUDE_SECTIONS" ]]; then
    if [[ -n "$ONLY_SECTIONS" ]]; then
      ONLY_SECTIONS="$(apply_exclude "$ONLY_SECTIONS")"
      info "After --exclude: sections $ONLY_SECTIONS"
    fi
    # For --all we'll filter at run_all_safe time below.
  fi

  if [[ -n "$ONLY_SECTIONS" ]]; then
    step "Running explicit sections: $ONLY_SECTIONS"
    local s
    IFS=',' read -r -a _arr <<<"$ONLY_SECTIONS"
    for s in "${_arr[@]}"; do
      s="${s// /}"
      [[ "$s" =~ ^[0-9]+$ ]] || { warn "Skipping invalid section '$s'"; continue; }
      dispatch "$s"
    done
    session_summary
    notify_user "mac-cleanup" "Done — freed $(human_kb "$TOTAL_FREED_KB")"
    return 0
  fi

  if (( RUN_ALL )); then
    if [[ -n "$EXCLUDE_SECTIONS" ]]; then
      # Build a filtered version of SAFE_BATCH and run those instead.
      local _safe_csv _filtered s
      _safe_csv="$(IFS=,; echo "${SAFE_BATCH[*]}")"
      _filtered="$(apply_exclude "$_safe_csv")"
      step "Safe batch with --exclude: $_filtered"
      IFS=',' read -r -a _arr <<<"$_filtered"
      for s in "${_arr[@]}"; do
        s="${s// /}"
        [[ "$s" =~ ^[0-9]+$ ]] && dispatch "$s"
      done
    else
      run_all_safe
    fi
    session_summary
    notify_user "mac-cleanup" "Done — freed $(human_kb "$TOTAL_FREED_KB")"
    return 0
  fi

  while true; do
    show_menu
    printf '%bSelect [0-26 / A / D / Y / S / Q]:%b ' "$BOLD" "$NC"
    local choice
    read -r choice || { echo; break; }
    case "$choice" in
      [Qq]*) break ;;
      [Aa]*) BATCH_MODE=1; run_all_safe; BATCH_MODE=0 ;;
      [Dd]*) DRY_RUN=$(( 1 - DRY_RUN )) ;;
      [Yy]*) ASSUME_YES=$(( 1 - ASSUME_YES )) ;;
      [Ss]*) session_summary; press_enter ;;
      ''   ) continue ;;
      *)
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 0 && choice <= 26 )); then
          dispatch "$choice"
        else
          warn "Unrecognised choice: $choice"
        fi ;;
    esac
  done

  session_summary
  log_to_file "── mac-cleanup ended ──"
  notify_user "mac-cleanup" "Done — freed $(human_kb "$TOTAL_FREED_KB")"
  # Note: --cleanup-logs-on-finish is handled by the EXIT trap so it
  # fires for every code path (interactive quit, --only, --all, signals).
}

main "$@"
