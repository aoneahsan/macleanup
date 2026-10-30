# shellcheck shell=bash
# macleanup — module 03 of 10, lines 939–1407 of the pre-5.2.2 single script.
# Sourced in order by macleanup.sh; never run on its own.

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
  --exclude-path PATH         Never touch PATH (or anything under it). Every
                              section's delete and Trash move honours it.
                              Repeatable. (Keep.)
  --archive-path PATH         Before PATH is deleted or moved to the Trash,
                              write it to a private archive in
                              ~/.macleanup/archives/ (mode 600). If the
                              archive fails, PATH is left in place. Repeatable.
  --logs-dir PATH             Persistent logs directory
                              (default: \$HOME/.macleanup/logs).
  --reports-dir PATH          Persistent reports directory
                              (default: \$HOME/.macleanup/reports).
  --no-reports                Skip writing per-section .txt report files.
                              (Logs still written.)
  --cleanup-logs-on-finish    Delete this run's log file at exit.
                              Default: keep all logs forever.
  --quiet                     Less chatter (errors and warnings still shown).
  --json                      Emit a one-line JSON run summary on stdout (all
                              other output goes to stderr). Implies --quiet.
                              Best paired with --only / --all for scripting/CI.
  --json-events               Stream one JSON event per line on stdout (plan,
                              per-section items and results, summary). Needs
                              --only / --profile / --all; not with --json.
                              Schema: docs/json-events.md in the repo.
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
  --idle-days N               Universal idle threshold (days). GATES deletes
                              in sections 12 (orphan data) and 23 (stale
                              build artefacts); also sets the idle HIGHLIGHT
                              threshold in sections 16 (iOS backups) and 17
                              (Xcode archives). Default: ${IDLE_THRESHOLD_DAYS_DEFAULT}. Per the
                              safety rule, gated items are only deleted if
                              they're (a) not in use by any active software
                              AND (b) untouched for ≥ N days. Idleness is
                              measured via atime+mtime, which on APFS is a
                              best-effort heuristic (background scanners can
                              refresh atime — failing safe — and Finder/Time
                              Machine restores can reset it).
  --i-understand-deep         Allow the deepest, irreversible sections
                              (6, 10, 11, 14, 21, 24) to run unattended under
                              --only / --profile / --all when combined with
                              --yes. Also permits section 25 to remove stale
                              launch items in batch mode. WITHOUT this flag
                              the deep sections are refused in
                              batch mode (a one-char typo of a section number
                              can't trigger them). --yes alone never enables
                              them. Dry-run previews are always allowed.
  --list                      List every section number and label, then exit.
  --version, -V               Print version and exit.
  --contact                   Print author contact card and exit.
  --feedback                  Open mail client with prefilled message.
  --report-issue              Collect environment info LOCALLY and open
       (--report-bug)         a pre-filled GitHub issue (you review it
                              before submitting — nothing is auto-sent).
  --stats                     Show history of runs at $HOME/.macleanup.
  --prune-history [N]         Delete logs + reports older than N days from
                              $HOME/.macleanup (default N=90). Honours
                              --dry-run.
  --uninstall-data            Remove the entire $HOME/.macleanup data dir
                              (logs, reports, run history) after confirming.
  -h, --help                  Show this help.

${BOLD}Config file${NC}
  Defaults can be set in ~/.macleanuprc (or \$MACLEANUP_RC) as simple
  key=value lines; CLI flags always override. Recognised keys:
  cache-age-days, idle-days, threshold, stale-build-days, large-file-days,
  large-file-size-gb, scan-roots, quiet, notify, brew-autoremove.

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
  • --all (even --all --yes) only ever runs the safe batch: caches, logs,
    temp, and read-only reports. It never runs the deep sections.
  • The deepest, irreversible sections (6 system caches as root, 11 TM
    snapshots, 14 /private/var/folders wipe, 21 app uninstall, 24 large
    files → Trash) are NEVER auto-run by --only / --profile / --all unless
    you ALSO pass --i-understand-deep. Pick them from the interactive menu,
    or opt in explicitly. --yes alone will not auto-run them.
  • Logs are written to: ${LOG_FILE}
EOF
}

# Named profile presets — bundles of section numbers users can invoke
# instead of memorising lists. Resolved by resolve_profile() into a
# comma-separated list compatible with --only.
profile_sections() {
  case "$1" in
    dev)        printf '1,2,3,4,23' ;;
    minimal)    printf '5,7,8,9' ;;
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
  local title="${1:-macleanup}" msg="${2:-Done}"
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

# url_encode "string" → URL-encoded form (uses python3 which ships
# with macOS by default). Used to prefill mailto: + GitHub issue URLs.
url_encode() {
  python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "${1:-}" 2>/dev/null \
    || printf '%s' "${1:-}"
}

# cmd_contact — prints contact info in a tidy, copy-friendly card.
cmd_contact() {
  printf '\n%b%s — %s%b\n' "$BOLD$MAGENTA" "$SCRIPT_NAME" "$AUTHOR_NAME" "$NC"
  printf '%b%s%b\n' "$DIM" "─────────────────────────────────────────────" "$NC"
  printf '   Email      : %s\n' "$AUTHOR_EMAIL"
  printf '   Website    : %s\n' "$PROJECT_WEBSITE"
  printf '   Docs       : %s\n' "$PROJECT_DOCS"
  printf '   Issues     : %s/issues\n' "$PROJECT_REPO"
  printf '   Project    : %s\n' "$PROJECT_REPO"
  printf '   npm (pkg)  : %s\n' "$PROJECT_NPM"
  printf '\n%bGet help / give feedback%b\n' "$BOLD" "$NC"
  printf '   %s --feedback       %bemail with prefilled subject%b\n' "$SCRIPT_NAME" "$DIM" "$NC"
  printf '   %s --report-issue   %bopen a pre-filled GitHub issue%b\n' "$SCRIPT_NAME" "$DIM" "$NC"
  printf '\n'
}

# cmd_feedback — opens the user's default mail client with a prefilled
# message to the author. Falls back to printing the URL if `open` is
# unavailable (e.g. headless / sandbox).
cmd_feedback() {
  local subj body url
  subj="$(url_encode "Feedback: ${SCRIPT_NAME} v${SCRIPT_VERSION}")"
  body="$(url_encode "Hi macleanup team,

I'm using ${SCRIPT_NAME} v${SCRIPT_VERSION} on macOS $(sw_vers -productVersion 2>/dev/null || echo '?').

[your feedback here]

— sent from \`${SCRIPT_NAME} --feedback\`")"
  url="mailto:${AUTHOR_EMAIL}?subject=${subj}&body=${body}"
  printf '\n%bOpening your mail client…%b\n' "$BOLD" "$NC"
  printf '   to:      %s\n' "$AUTHOR_EMAIL"
  printf '   subject: Feedback: %s v%s\n\n' "$SCRIPT_NAME" "$SCRIPT_VERSION"
  if has_cmd open; then
    open "$url" >/dev/null 2>&1 \
      || { warn "Couldn't open mail client. Email manually:"; printf '   %s\n' "$AUTHOR_EMAIL"; }
  else
    printf 'Email manually: %s\n' "$AUTHOR_EMAIL"
  fi
  printf '\nPrefer the issue tracker?\n   %s\n' "$PROJECT_REPO/issues/new"
}

# cmd_report_issue — opens a pre-filled GitHub issue with environment
# info collected ENTIRELY LOCALLY. Nothing is transmitted automatically;
# the user reviews the prefilled body and clicks Submit themselves.
cmd_report_issue() {
  local mac_ver chip ram_h node_v latest_log
  mac_ver=$(sw_vers -productVersion 2>/dev/null || echo "?")
  chip=$(uname -m)
  ram_h=$(awk -v b="$(sysctl -n hw.memsize 2>/dev/null || echo 0)" 'BEGIN{printf "%.0f GB", b/1024/1024/1024}')
  node_v=$(node --version 2>/dev/null || echo "n/a (running script directly)")
  latest_log=$(ls -1t "$LOG_DIR"/${SCRIPT_NAME}-*.log 2>/dev/null | head -1)

  local body subj url
  subj="$(url_encode "[bug] ")"
  body=$(cat <<EOF
**Describe the bug**
<!-- what happened, what you expected, steps to reproduce -->

**Environment**
- ${SCRIPT_NAME} version: ${SCRIPT_VERSION}
- macOS: ${mac_ver} (${chip})
- RAM: ${ram_h}
- bash: ${BASH_VERSION}
- Node: ${node_v}
- Latest log: ${latest_log:-(none — run a section first)}

**Command you ran**
\`\`\`bash
# paste the exact command
\`\`\`

**Output / error**
<!-- copy the relevant stderr/stdout lines, redact personal paths if needed -->

**Latest log excerpt** (from ${latest_log:-?})
<!-- last 30 lines that show the failure -->
EOF
)
  body="$(url_encode "$body")"
  url="${PROJECT_REPO}/issues/new?title=${subj}&body=${body}"

  printf '\n%bOpening a pre-filled GitHub issue…%b\n' "$BOLD" "$NC"
  printf '   environment info collected LOCALLY — review before submitting.\n'
  printf '   nothing is sent until you click Submit on github.com.\n\n'
  if [[ -n "$latest_log" ]] && has_cmd pbcopy; then
    if tail -50 "$latest_log" 2>/dev/null | pbcopy 2>/dev/null; then
      ok "Last 50 log lines copied to clipboard — paste into the 'Latest log excerpt' section."
    fi
  fi
  if has_cmd open; then
    open "$url" >/dev/null 2>&1 \
      || { warn "Couldn't open browser. Visit manually:"; printf '   %s\n' "${PROJECT_REPO}/issues/new"; }
  else
    printf 'Visit manually: %s\n' "${PROJECT_REPO}/issues/new"
  fi
  printf '\nPrefer email?  %s\n' "$AUTHOR_EMAIL"
}

# cmd_stats — read-only summary of historical runs from ~/.macleanup/.
cmd_stats() {
  printf '\n%b%s — runtime stats%b\n' "$BOLD$MAGENTA" "$SCRIPT_NAME" "$NC"
  printf '%b%s%b\n' "$DIM" "─────────────────────────────────────────────" "$NC"
  printf '%bData directory:%b %s\n\n' "$BOLD" "$NC" "$DEFAULT_DATA_DIR"

  local logs_n reports_n logs_size reports_size oldest_log newest_log
  if [[ -d "$LOG_DIR" ]]; then
    logs_n=$(find "$LOG_DIR" -type f -name "${SCRIPT_NAME}-*.log" 2>/dev/null | wc -l | awk '{print $1}')
    logs_size=$(du -sh "$LOG_DIR" 2>/dev/null | awk '{print $1}')
    oldest_log=$(ls -1t "$LOG_DIR"/${SCRIPT_NAME}-*.log 2>/dev/null | tail -1 | xargs -I{} basename {} 2>/dev/null)
    newest_log=$(ls -1t "$LOG_DIR"/${SCRIPT_NAME}-*.log 2>/dev/null | head -1 | xargs -I{} basename {} 2>/dev/null)
    printf '   Logs        : %s files, %s total\n' "${logs_n:-0}" "${logs_size:-0B}"
    [[ -n "$oldest_log" ]] && printf '                 oldest %s\n' "$oldest_log"
    [[ -n "$newest_log" && "$newest_log" != "$oldest_log" ]] && printf '                 newest %s\n' "$newest_log"
  else
    printf '   Logs        : (no logs dir yet — run a section first)\n'
  fi

  if [[ -d "$REPORTS_DIR" ]]; then
    reports_n=$(find "$REPORTS_DIR" -type f -name "*.txt" 2>/dev/null | wc -l | awk '{print $1}')
    reports_size=$(du -sh "$REPORTS_DIR" 2>/dev/null | awk '{print $1}')
    printf '   Reports     : %s files, %s total\n' "${reports_n:-0}" "${reports_size:-0B}"
    if (( reports_n > 0 )); then
      printf '\n%bRecent reports:%b\n' "$BOLD" "$NC"
      ls -1t "$REPORTS_DIR"/*.txt 2>/dev/null | head -8 | while IFS= read -r f; do
        printf '   • %s   %s\n' "$(stat -f '%Sm' -t '%Y-%m-%d' "$f" 2>/dev/null)" "$(basename "$f")"
      done
    fi
  fi

  printf '\n%bGet help%b\n' "$BOLD" "$NC"
  printf '   %s --feedback       email the macleanup team\n' "$SCRIPT_NAME"
  printf '   %s --report-issue   open a pre-filled bug report\n' "$SCRIPT_NAME"
  printf '   %s --contact        full contact card\n' "$SCRIPT_NAME"
  printf '\n'
}

# cmd_prune_history N — delete logs + report files older than N days from the
# persistent data dir. Honours DRY_RUN. Quick-exit command (never sets batch).
cmd_prune_history() {
  local days="${1:-90}"
  [[ "$days" =~ ^[0-9]+$ ]] || { err "--prune-history needs a number of days"; exit 2; }
  printf '\n%b%s — prune history older than %s days%b\n' "$BOLD$MAGENTA" "$SCRIPT_NAME" "$days" "$NC"
  local d before=0 after=0
  for d in "$LOG_DIR" "$REPORTS_DIR"; do
    [[ -d "$d" ]] || continue
    before=$(( before + $(size_kb "$d") ))
    if (( DRY_RUN )); then
      note "[dry-run] would delete files >${days}d in $d"
      find "$d" -type f -mtime "+$days" -print 2>/dev/null | sed 's/^/   would remove: /'
    else
      find "$d" -type f -mtime "+$days" -print0 2>/dev/null | xargs -0 rm -f 2>/dev/null || true
      after=$(( after + $(size_kb "$d") ))
    fi
  done
  if (( DRY_RUN )); then
    note "Dry-run — nothing deleted."
  else
    ok "Pruned $(human_kb "$(( before - after ))") of old logs/reports (kept files newer than ${days}d)."
  fi
}

# cmd_uninstall_data — remove the entire persistent data dir (~/.macleanup:
# logs, reports, the first-run marker). Confirms first; honours DRY_RUN.
cmd_uninstall_data() {
  printf '\n%b%s — remove persistent data%b\n' "$BOLD$MAGENTA" "$SCRIPT_NAME" "$NC"
  printf '   Target: %s  (%s)\n\n' "$DEFAULT_DATA_DIR" "$(size_h "$DEFAULT_DATA_DIR")"
  if [[ ! -d "$DEFAULT_DATA_DIR" ]]; then
    info "Nothing to remove — $DEFAULT_DATA_DIR does not exist."
    return 0
  fi
  if (( DRY_RUN )); then
    note "[dry-run] would remove $DEFAULT_DATA_DIR"
    return 0
  fi
  if confirm_yes "Delete all logs, reports, and run history under $DEFAULT_DATA_DIR?"; then
    if safe_rm_rf "$DEFAULT_DATA_DIR"; then
      ok "Removed $DEFAULT_DATA_DIR"
    else
      warn "Could not remove $DEFAULT_DATA_DIR"
    fi
  else
    info "Kept."
  fi
}

# load_rc_file — read ~/.macleanuprc (or $MACLEANUP_RC) as simple key=value
# lines BEFORE CLI parsing, so explicit flags always win. Parsed with `read`
# (never source/eval); only a whitelist of keys is honoured; malformed lines
# warn and are skipped so a stray line can never brick the tool.
load_rc_file() {
  local rc="${MACLEANUP_RC:-$HOME/.macleanuprc}"
  if [[ -z "${MACLEANUP_RC:-}" && ! -f "$rc" && -f "$LEGACY_RC_FILE" ]]; then
    rc="$LEGACY_RC_FILE"
    LEGACY_NOTES+=("Read $LEGACY_RC_FILE; rename it to $HOME/.macleanuprc.")
  fi
  [[ -f "$rc" ]] || return 0
  local key val
  while IFS='=' read -r key val; do
    # trim surrounding whitespace
    key="${key#"${key%%[![:space:]]*}"}"; key="${key%"${key##*[![:space:]]}"}"
    val="${val#"${val%%[![:space:]]*}"}"; val="${val%"${val##*[![:space:]]}"}"
    [[ -z "$key" || "$key" == \#* ]] && continue
    case "$key" in
      cache-age-days|idle-days|threshold|stale-build-days|large-file-days|large-file-size-gb)
        if [[ "$val" =~ ^[0-9]+$ ]]; then
          case "$key" in
            cache-age-days)     CACHE_AGE_DAYS="$val" ;;
            idle-days)          IDLE_THRESHOLD_DAYS="$val" ;;
            threshold)          UNUSED_APP_THRESHOLD_DAYS="$val" ;;
            stale-build-days)   STALE_BUILD_THRESHOLD_DAYS="$val" ;;
            large-file-days)    LARGE_FILE_THRESHOLD_DAYS="$val" ;;
            large-file-size-gb) LARGE_FILE_SIZE_GB="$val" ;;
          esac
        else
          warn "$rc: key '$key' needs a number, got '$val' — ignored."
        fi ;;
      scan-roots)  [[ -n "$val" ]] && SCAN_ROOTS_OVERRIDE="$val" ;;
      quiet)       [[ "$val" == "1" || "$val" == "true" ]] && QUIET=1 ;;
      notify)      [[ "$val" == "1" || "$val" == "true" ]] && NOTIFY=1 ;;
      brew-autoremove) [[ "$val" == "1" || "$val" == "true" ]] && BREW_AUTOREMOVE=1 ;;
      *)           warn "$rc: unknown key '$key' — ignored." ;;
    esac
  done < "$rc"
}

# json_escape — escape backslashes and double-quotes for embedding in JSON.
json_escape() {
  local s="${1:-}"
  s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"; s="${s//$'\r'/\\r}"; s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

# ── --json-events (schema v1, docs/json-events.md) ───────────────────────
# Recovery tier per section id 0..27 (same as the docs and the desktop app).
SECTION_TIERS=(read routine routine routine routine routine routine routine routine routine \
  permanent permanent trash read permanent read permanent permanent read routine \
  read trash read permanent trash permanent read routine)
SUDO_SECTIONS=" 6 7 11 13 14 20 25 "
UNIQUE_DATA_SECTIONS=" 12 16 17 21 24 "

# _ev_bool cond-string → true/false for "space-padded set contains id"
_ev_in() { [[ "$2" == *" $1 "* ]] && printf true || printf false; }

# ev_emit type json-fields → one NDJSON line on the saved real stdout (fd 3).
ev_emit() {
  (( JSON_EVENTS && EV_READY )) || return 0
  local extra="${2:-}"
  [[ -n "$extra" ]] && extra=",$extra"
  printf '{"v":1,"type":"%s","ts":%s%s}\n' "$1" "$(( $(date +%s) * 1000 ))" "$extra" >&3
}

