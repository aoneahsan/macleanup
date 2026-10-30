# shellcheck shell=bash
# macleanup — module 01 of 10, lines 40–484 of the pre-5.2.2 single script.
# Sourced in order by macleanup.sh; never run on its own.

# ── runtime preflight ────────────────────────────────────────────────────
if [[ "$(uname -s 2>/dev/null)" != "Darwin" ]]; then
  printf 'macleanup: this tool only runs on macOS (Darwin). Detected: %s\n' \
    "$(uname -s 2>/dev/null || echo unknown)" >&2
  exit 1
fi
if [[ -z "${BASH_VERSINFO+set}" ]] \
   || (( BASH_VERSINFO[0] < 3 )) \
   || (( BASH_VERSINFO[0] == 3 && BASH_VERSINFO[1] < 2 )); then
  printf 'macleanup: bash 3.2+ required. Detected: %s\n' "${BASH_VERSION:-unknown}" >&2
  exit 1
fi

# ──────────────────────────────────────────────────────────────────────────
#                                CONSTANTS
# ──────────────────────────────────────────────────────────────────────────
# Single source of truth is package.json: the npx/npm launcher (bin/macleanup.js)
# exports its version as MACLEANUP_VERSION. For a direct `./macleanup.sh`
# checkout the literal fallback is used; `yarn prepublishOnly` asserts the two
# stay in sync so they can never drift on a publish.
SCRIPT_VERSION="${MACLEANUP_VERSION:-5.3.0}"
SCRIPT_NAME="macleanup"
TODAY="$(date +%Y-%m-%d)"
RUN_TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S %Z')"

# ── Product / team constants — embedded in every log + report ─────────────
# The product speaks as its team; no personal phone, address or profile links.
AUTHOR_NAME="the macleanup team"
AUTHOR_EMAIL="aoneahsan@gmail.com"
PROJECT_WEBSITE="https://macleanup.aoneahsan.com"
PROJECT_DOCS="https://macleanup-docs.aoneahsan.com"
PROJECT_REPO="https://github.com/aoneahsan/macleanup"
PROJECT_NPM="https://www.npmjs.com/package/macleanup"

# ── Persistent runtime directories (survive npx cache cleanup) ────────────
# Default to $HOME/.macleanup/{logs,reports} so reports + history are
# stable regardless of whether the script ran from a git checkout, an
# /opt install, or `npx macleanup`. Both paths can be
# overridden via --logs-dir / --reports-dir or environment variables.
DEFAULT_DATA_DIR="$HOME/.macleanup"

# ── 5.0.0 one-name rename: pre-5 names are read as fallbacks for 5.x ─────
# Before 5.0.0 the tool used ~/.mac-cleanup, ~/.mac-cleanuprc and
# MAC_CLEANUP_* variables. The new names always win; an old name is used only
# when its new counterpart is unset, and each use prints one deprecation note.
LEGACY_DATA_DIR="$HOME/.mac-cleanup"
LEGACY_RC_FILE="$HOME/.mac-cleanuprc"
LEGACY_NOTES=()
for _legacy_pair in LOGS_DIR REPORTS_DIR RC; do
  _new_var="MACLEANUP_${_legacy_pair}"; _old_var="MAC_CLEANUP_${_legacy_pair}"
  if [[ -z "${!_new_var:-}" && -n "${!_old_var:-}" ]]; then
    printf -v "$_new_var" '%s' "${!_old_var}"
    LEGACY_NOTES+=("\$${_old_var} is deprecated; use \$${_new_var}.")
  fi
done
unset _legacy_pair _new_var _old_var

LOG_DIR="${MACLEANUP_LOGS_DIR:-$DEFAULT_DATA_DIR/logs}"
REPORTS_DIR="${MACLEANUP_REPORTS_DIR:-$DEFAULT_DATA_DIR/reports}"
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
  # pnpm setup target on macOS (PNPM_HOME default) — holds global bin
  # shims, the content-addressable store, and the v11 global node_modules
  # tree. Deleting anything under here breaks every `pnpm add -g` tool,
  # corepack-managed yarn shims, and forces a full `pnpm setup` recovery.
  Library/pnpm
  # pnpm setup target on Linux (XDG default); harmless on macOS but kept
  # so the same script is safe to run from a Linux home synced via Time
  # Machine restore / migration assistant.
  .local/share/pnpm .local/state/pnpm
  # Corepack home (PATH'd via `corepack enable`). Holds vendored yarn /
  # pnpm / npm binaries pinned per-project via package.json#packageManager.
  .cache/node/corepack Library/Caches/node/corepack
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

# Top-level ~/Library/Caches entries that section 5 must PRESERVE. Apple and the
# major browsers (handled by section 19) are kept so their caches aren't wiped
# out from under a running browser; password managers are kept to avoid churn;
# and `node` is kept because ~/Library/Caches/node/corepack is a
# CRITICAL_HOME_DIRS entry (deleting it breaks every corepack-pinned yarn/pnpm).
# Best-effort, hand-maintained list — patterns are matched by `find ! -name`.
USER_CACHE_PRESERVE=(
  'com.apple.*'
  'com.google.Chrome*' 'org.mozilla.firefox*' 'com.apple.Safari*'
  'com.brave.*' 'BraveSoftware*' 'Company'
  'com.microsoft.edgemac*' 'com.operasoftware.Opera*' 'com.operasoftware.OperaGX*'
  'com.vivaldi.Vivaldi*' 'com.thebrowser.Browser*' 'company.thebrowser.*'
  'com.duckduckgo.macos.browser*' 'com.kagi.kagimacOS*'
  'app.zen-browser.zen*' 'org.floorp.*' 'net.imput.chromium*' 'org.chromium.Chromium*'
  '1Password*' 'com.agilebits.*' 'Bitwarden*' 'org.keepassxc.keepassxc*'
  'node'
)

# migrate_legacy_data_dir — one-time, copy-only move to the 5.0.0 data dir.
# When ~/.mac-cleanup exists and ~/.macleanup does not, copy it (never move or
# delete), then write a marker naming the source. The old folder stays in
# place for the user to remove when ready.
migrate_legacy_data_dir() {
  [[ -d "$LEGACY_DATA_DIR" && ! -e "$DEFAULT_DATA_DIR" ]] || return 0
  if cp -Rp "$LEGACY_DATA_DIR" "$DEFAULT_DATA_DIR" 2>/dev/null; then
    printf 'Copied from %s on %s\n' "$LEGACY_DATA_DIR" "$RUN_TIMESTAMP" \
      > "$DEFAULT_DATA_DIR/.migrated-from-4x" 2>/dev/null || true
    LEGACY_NOTES+=("Copied $LEGACY_DATA_DIR to $DEFAULT_DATA_DIR. The old folder was left in place; remove it when you no longer need it.")
  else
    LEGACY_NOTES+=("Could not copy $LEGACY_DATA_DIR to $DEFAULT_DATA_DIR. Older logs and reports stay in the old folder.")
  fi
}

migrate_legacy_data_dir
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
IDLE_THRESHOLD_DAYS="$IDLE_THRESHOLD_DAYS_DEFAULT"  # --idle-days N (sections 12, 23 gate; 16, 17 highlight)
DEEP_OPT_IN=0      # --i-understand-deep (allow deep destructive sections under batch)
EXCLUDE_PATHS=()   # --exclude-path PATH (repeatable; never touched by any section's delete or Trash move)
ARCHIVE_PATHS=()   # --archive-path PATH (repeatable; archived to ~/.macleanup/archives before removal)
ARCHIVE_DIR="${MACLEANUP_ARCHIVES_DIR:-$DEFAULT_DATA_DIR/archives}"
JSON_MODE=0        # --json (emit a machine-readable summary on stdout)
JSON_EVENTS=0      # --json-events (NDJSON event stream on stdout; docs/json-events.md)
EV_READY=0         # fd 3 holds the real stdout for the event stream
CURRENT_SECTION="" # section id being dispatched (for --json-events attribution)
SECTION_ITEMS=0    # items reported by the current section
LAST_SKIP_REASON="" # last "Skipping …" warning inside the current section
ATTEMPTED_SECTIONS=()
SKIPPED_SECTIONS=()
FAILED_SECTIONS=()

TOTAL_FREED_KB=0
DISK_FREE_BEFORE_KB=""
DISK_FREE_AFTER_KB=""
START_EPOCH="$(date +%s)"
COMPLETED_SECTIONS=()
TMPFILES=()

_cleanup_temps() {
  local rc=$?
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
  # Crash hint — when exiting non-zero AND the script actually got far
  # enough to set up logs (post-parse_args, where SCRIPT_VERSION is
  # known and the welcome was past), point the user at --report-issue.
  # Skip rc=0 (success) and rc=2 (deliberate user-error from
  # parse_args; "Unknown option" already printed help).
  if (( rc != 0 )) && (( rc != 2 )) && [[ -d "${LOG_DIR:-}" ]]; then
    printf '\n%b   Something went wrong (exit %d).%b\n' "${YELLOW:-}" "$rc" "${NC:-}" >&2
    printf '%b   Run \`%s --report-issue\` to file a pre-filled bug report,%b\n' "${YELLOW:-}" "${SCRIPT_NAME:-macleanup}" "${NC:-}" >&2
    printf '%b   or \`%s --feedback\` to email the author directly.%b\n\n' "${YELLOW:-}" "${SCRIPT_NAME:-macleanup}" "${NC:-}" >&2
  fi
  # Reset terminal attributes so an interrupted printf doesn't leave the
  # shell in a coloured / dimmed state — only when we were using colours.
  if [[ -n "${NC:-}" ]]; then
    printf '%b' "$NC" 2>/dev/null || true
  fi
}

# Wire cleanup to EXIT for normal/error paths, and handle signals separately so
# that Ctrl-C (INT) / TERM actually TERMINATE the script. A combined
# `trap … EXIT INT TERM` handler that merely returns would let bash RESUME the
# interrupted command (e.g. a destructive delete loop) after cleanup — a real
# hazard for a tool that removes files. _on_signal disables the traps (so
# cleanup runs exactly once), cleans up, then re-raises the signal to die with
# the conventional code (130 INT / 143 TERM).
trap _cleanup_temps EXIT
_on_signal() {
  local sig="$1"
  trap - INT TERM EXIT
  _cleanup_temps
  kill -s "$sig" "$$"
}
trap '_on_signal INT' INT
trap '_on_signal TERM' TERM

# ──────────────────────────────────────────────────────────────────────────
#                                LOGGING
# ──────────────────────────────────────────────────────────────────────────
log_to_file() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$LOG_FILE" 2>/dev/null || true; }
info()        { (( QUIET )) || printf '%b[INFO]%b %s\n' "$BLUE" "$NC" "$*"; log_to_file "INFO  $*"; }
ok()          { (( QUIET )) || printf '%b[ OK ]%b %s\n' "$GREEN" "$NC" "$*"; log_to_file "OK    $*"; }
warn()        { printf '%b[WARN]%b %s\n' "$YELLOW" "$NC" "$*"; log_to_file "WARN  $*"; [[ -n "$CURRENT_SECTION" ]] && LAST_SKIP_REASON="$*"; return 0; }
err()         { printf '%b[ERR ]%b %s\n' "$RED" "$NC" "$*" >&2; log_to_file "ERR   $*"; (( JSON_EVENTS )) && ev_error "$*"; return 0; }
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

# _path_newer_ts path → the MORE RECENT of atime/mtime as an epoch (0 if
# unreadable). Used as an "idleness" signal: a file that was recently READ
# (atime) OR written (mtime) counts as recently touched, which fails safe
# (an app whose prefs were read on launch looks used even if never rewritten).
_path_newer_ts() {
  local _s _a _m
  _s=$(stat -f '%a %m' "$1" 2>/dev/null || echo "0 0")
  _a=${_s%% *}; _m=${_s##* }
  [[ "$_a" =~ ^[0-9]+$ ]] || _a=0
  [[ "$_m" =~ ^[0-9]+$ ]] || _m=0
  if (( _m > _a )); then printf '%s' "$_m"; else printf '%s' "$_a"; fi
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

# path_is_excluded path → 0 when path equals or sits under an --exclude-path.
path_is_excluded() {
  local p="${1%/}" x
  for x in "${EXCLUDE_PATHS[@]+"${EXCLUDE_PATHS[@]}"}"; do
    x="${x%/}"
    [[ -n "$x" ]] || continue
    [[ "$p" == "$x" || "$p" == "$x/"* ]] && return 0
  done
  return 1
}

# excl_top_args dir → sets EXCL_TOP to find predicates that skip every direct
# child of dir which is a kept path (--exclude-path) or contains one. Used by the
# bulk "wipe this folder's contents" sites so Keep holds there too; a folder
# that holds a kept path is left whole rather than partly emptied.
excl_top_args() {
  local d="${1%/}" x rel
  EXCL_TOP=()
  for x in "${EXCLUDE_PATHS[@]+"${EXCLUDE_PATHS[@]}"}"; do
    x="${x%/}"
    [[ "$x" == "$d/"* ]] || continue
    rel="${x#"$d"/}"
    EXCL_TOP+=( ! -path "$d/${rel%%/*}" )
  done
}

# excl_deep_args → sets EXCL_DEEP to find predicates that skip every kept path
# and everything under it. Used by the age-based prune sites.
excl_deep_args() {
  local x
  EXCL_DEEP=()
  for x in "${EXCLUDE_PATHS[@]+"${EXCLUDE_PATHS[@]}"}"; do
    x="${x%/}"
    [[ -n "$x" ]] && EXCL_DEEP+=( ! -path "$x" ! -path "$x/*" )
  done
}

# emit_kept_tops dir → under --json-events, one "skip" item per kept child of dir,
# so a preview shows the same keep the real run honours.
emit_kept_tops() {
  (( JSON_EVENTS )) || return 0
  local d="${1%/}" x rel seen=" "
  for x in "${EXCLUDE_PATHS[@]+"${EXCLUDE_PATHS[@]}"}"; do
    x="${x%/}"
    [[ "$x" == "$d/"* ]] || continue
    rel="${x#"$d"/}"; rel="${rel%%/*}"
    [[ "$seen" == *" $rel "* ]] && continue
    seen+="$rel "
    [[ -e "$d/$rel" ]] && ev_item "$d/$rel" 0 skip
  done
}

