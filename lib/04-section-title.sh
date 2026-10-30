# shellcheck shell=bash
# macleanup — module 04 of 10, lines 1408–1876 of the pre-5.2.2 single script.
# Sourced in order by macleanup.sh; never run on its own.

# section_title id → the --list label.
section_title() {
  local entry
  for entry in "${SECTION_CATALOGUE[@]}"; do
    [[ "${entry%%|*}" == "$1" ]] && { printf '%s' "${entry#*|}"; return 0; }
  done
}

# _ev_section_obj id → {"id":…,"title":…,"stamp":…,"sudo":…,"deep":…}
_ev_section_obj() {
  printf '{"id":%d,"title":"%s","stamp":"%s","sudo":%s,"deep":%s}' "$1" \
    "$(json_escape "$(section_title "$1")")" "${SECTION_TIERS[$1]:-read}" \
    "$(_ev_in "$1" "$SUDO_SECTIONS")" "$(_ev_in "$1" "$DEEP_INTERACTIVE_SECTIONS")"
}

# ev_plan "csv of ids"
ev_plan() {
  (( JSON_EVENTS )) || return 0
  local arr="" s
  IFS=',' read -r -a _plan_ids <<<"$1"
  for s in "${_plan_ids[@]+"${_plan_ids[@]}"}"; do
    s="${s// /}"; [[ "$s" =~ ^[0-9]+$ ]] && (( s <= 27 )) || continue
    [[ -n "$arr" ]] && arr+=","
    arr+="$(_ev_section_obj "$s")"
  done
  local prof="null"; [[ -n "$PROFILE_NAME" ]] && prof="\"$(json_escape "$PROFILE_NAME")\""
  ev_emit plan "\"version\":\"$(json_escape "$SCRIPT_VERSION")\",\"dry_run\":$([[ $DRY_RUN -eq 1 ]] && echo true || echo false),\"profile\":$prof,\"sections\":[$arr]"
}

# ev_disk before|after — free space plus the local-snapshot note.
ev_disk() {
  (( JSON_EVENTS )) || return 0
  local total free snaps=0
  total=$(df -k / 2>/dev/null | awk 'NR==2 {print $2+0}')
  free=$(disk_free_kb /)
  if has_cmd tmutil; then
    snaps=$(tmutil listlocalsnapshots / 2>/dev/null | grep -c 'com.apple' || true)
  fi
  snaps=${snaps:-0}
  ev_emit disk "\"phase\":\"$1\",\"total_kb\":${total:-0},\"free_kb\":${free:-0},\"purgeable_kb\":null,\"snapshots\":$snaps,\"snapshot_note\":$( (( snaps > 0 )) && echo true || echo false)"
}

# ev_item path kb action — one path a section would touch (dry run) or touched.
ev_item() {
  (( JSON_EVENTS )) && [[ -n "$CURRENT_SECTION" ]] || return 0
  SECTION_ITEMS=$(( SECTION_ITEMS + 1 ))
  local _ts _age="null"
  if [[ -e "$1" ]]; then
    _ts=$(_path_newer_ts "$1")
    (( _ts > 0 )) && _age=$(( ( $(date +%s) - _ts ) / 86400 ))
  fi
  ev_emit item "\"id\":$CURRENT_SECTION,\"path\":\"$(json_escape "$1")\",\"kb\":${2:-0},\"action\":\"$3\",\"unique\":$(_ev_in "$CURRENT_SECTION" "$UNIQUE_DATA_SECTIONS"),\"age_days\":$_age${4:+,$4}"
  ev_emit progress "\"id\":$CURRENT_SECTION,\"done\":$SECTION_ITEMS,\"total\":null"
}

# ev_error message
ev_error() {
  local id="null"; [[ -n "$CURRENT_SECTION" ]] && id="$CURRENT_SECTION"
  ev_emit error "\"id\":$id,\"message\":\"$(json_escape "$1")\""
}

# _ev_ids name-of-array → comma-joined ids
_ev_ids() {
  local IFS=,
  eval "printf '%s' \"\${$1[*]+\${$1[*]}}\""
}

# ev_summary — the last line of every finished stream.
ev_summary() {
  (( JSON_EVENTS )) || return 0
  local elapsed reps="" r _rmt
  elapsed=$(( $(date +%s) - START_EPOCH ))
  for r in "$ORPHAN_REPORT" "$UNUSED_APPS_REPORT" "$LARGE_FILES_REPORT" "$STALE_BUILD_REPORT" \
           "$LARGE_STALE_REPORT" "$LAUNCH_AUDIT_REPORT" "$DU_REPORT"; do
    [[ -f "$r" ]] || continue
    _rmt=$(stat -f %m "$r" 2>/dev/null || echo 0)
    (( _rmt >= START_EPOCH )) || continue
    [[ -n "$reps" ]] && reps+=","
    reps+="\"$(json_escape "$r")\""
  done
  ev_emit summary "\"attempted\":[$(_ev_ids ATTEMPTED_SECTIONS)],\"completed\":[$(_ev_ids COMPLETED_SECTIONS)],\"skipped\":[$(_ev_ids SKIPPED_SECTIONS)],\"failed\":[$(_ev_ids FAILED_SECTIONS)],\"freed_kb\":$TOTAL_FREED_KB,\"disk_free_before_kb\":${DISK_FREE_BEFORE_KB:-0},\"disk_free_after_kb\":${DISK_FREE_AFTER_KB:-0},\"elapsed_s\":$elapsed,\"reports\":[$reps],\"log\":\"$(json_escape "$LOG_FILE")\",\"dry_run\":$([[ $DRY_RUN -eq 1 ]] && echo true || echo false)"
}

# emit_json — print a single-line machine-readable run summary to stdout.
# Used by --json. Caller is responsible for keeping other output off stdout.
emit_json() {
  local elapsed disk_delta=0 arr="" reps="" s r
  elapsed=$(( $(date +%s) - START_EPOCH ))
  DISK_FREE_AFTER_KB=$(disk_free_kb /)
  if [[ -n "$DISK_FREE_BEFORE_KB" && -n "$DISK_FREE_AFTER_KB" ]]; then
    disk_delta=$(( DISK_FREE_AFTER_KB - DISK_FREE_BEFORE_KB )); (( disk_delta < 0 )) && disk_delta=0
  fi
  for s in "${COMPLETED_SECTIONS[@]+"${COMPLETED_SECTIONS[@]}"}"; do
    [[ -n "$arr" ]] && arr+=","
    arr+="$s"
  done
  # Only report files written by THIS run (mtime ≥ run start) — not stale
  # reports left from earlier runs the same day.
  local _rmt
  for r in "$ORPHAN_REPORT" "$UNUSED_APPS_REPORT" "$LARGE_FILES_REPORT" "$STALE_BUILD_REPORT" \
           "$LARGE_STALE_REPORT" "$LAUNCH_AUDIT_REPORT" "$DU_REPORT"; do
    [[ -f "$r" ]] || continue
    _rmt=$(stat -f %m "$r" 2>/dev/null || echo 0)
    (( _rmt >= START_EPOCH )) || continue
    [[ -n "$reps" ]] && reps+=","
    reps+="\"$(json_escape "$r")\""
  done
  printf '{"tool":"%s","version":"%s","dry_run":%s,"freed_kb":%d,"disk_free_delta_kb":%d,"elapsed_s":%d,"sections_done":[%s],"reports":[%s],"log_file":"%s"}\n' \
    "$(json_escape "$SCRIPT_NAME")" "$(json_escape "$SCRIPT_VERSION")" \
    "$([[ $DRY_RUN -eq 1 ]] && echo true || echo false)" \
    "$TOTAL_FREED_KB" "$disk_delta" "$elapsed" "$arr" "$reps" "$(json_escape "$LOG_FILE")"
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
  "8|Temp files (\$TMPDIR, /tmp)"
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
  "27|macOS UI maintenance: QuickLook + font caches"
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
    # Accept the --flag=value form in addition to --flag value, so callers
    # (scripts, cron, and the desktop GUI) can pass either. Split a leading
    # --key=value token into two positional args before matching.
    if [[ "$1" == --*=* ]]; then
      set -- "${1%%=*}" "${1#*=}" "${@:2}"
    fi
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
      --i-understand-deep)
        DEEP_OPT_IN=1 ;;
      --exclude-path)
        shift
        [[ -n "${1:-}" ]] || { err "--exclude-path needs a path"; exit 2; }
        EXCLUDE_PATHS+=("$1") ;;
      --archive-path)
        shift
        [[ -n "${1:-}" ]] || { err "--archive-path needs a path"; exit 2; }
        ARCHIVE_PATHS+=("${1%/}") ;;
      --json)
        JSON_MODE=1; QUIET=1 ;;
      --json-events)
        JSON_EVENTS=1; QUIET=1 ;;
      --prune-history)
        local _ph=90
        if [[ "${2:-}" =~ ^[0-9]+$ ]]; then _ph="$2"; shift; fi
        cmd_prune_history "$_ph"; exit 0 ;;
      --uninstall-data)
        cmd_uninstall_data; exit 0 ;;
      --no-color)
        RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""; MAGENTA=""; BOLD=""; DIM=""; NC=""
        ;;
      --list)
        print_section_list; exit 0 ;;
      --version|-V)
        printf '%s %s\n' "$SCRIPT_NAME" "$SCRIPT_VERSION"
        exit 0 ;;
      --contact)
        cmd_contact; exit 0 ;;
      --feedback)
        cmd_feedback; exit 0 ;;
      --report-issue|--report-bug)
        cmd_report_issue; exit 0 ;;
      --stats)
        cmd_stats; exit 0 ;;
      -h|--help)    print_help; exit 0 ;;
      *)
        err "Unknown option: $1"
        err "Run '$SCRIPT_NAME --help' to see all available options."
        exit 2 ;;
    esac
    shift
  done
}

# ══════════════════════════════════════════════════════════════════════════
# ───────────────────────── SECTION FUNCTIONS ──────────────────────────────
# ══════════════════════════════════════════════════════════════════════════

# Section 0 — System Health Check & Process Monitor
# s00_toolchains — read-only inventory of developer toolchains: what is
# installed, which versions, and how much space each takes. Nothing is changed;
# removing a toolchain is the toolchain's own uninstaller's job. Each entry is
# reported as an `item` with action "report" and a "tool"/"version" pair.
s00_toolchains() {
  local found=0 d tool ver kb
  _tc() {  # _tc tool version path
    [[ -e "$3" ]] || return 0
    kb=$(size_kb "$3")
    if (( found == 0 )); then printf '\n%bDeveloper toolchains:%b\n' "$BOLD" "$NC"; found=1; fi
    printf '   %-14s %-22s %10s  %s\n' "$1" "$2" "$(human_kb "$kb")" "$3"
    (( JSON_EVENTS )) && ev_item "$3" "$kb" report "\"tool\":\"$(json_escape "$1")\",\"version\":\"$(json_escape "$2")\""
    return 0
  }
  for d in "$HOME"/.nvm/versions/node/*/;        do [[ -d "$d" ]] && _tc node "$(basename "$d")" "${d%/}"; done
  for d in "$HOME"/.pyenv/versions/*/;           do [[ -d "$d" ]] && _tc python "$(basename "$d")" "${d%/}"; done
  for d in "$HOME"/.rbenv/versions/*/;           do [[ -d "$d" ]] && _tc ruby "$(basename "$d")" "${d%/}"; done
  for d in "$HOME"/.rustup/toolchains/*/;        do [[ -d "$d" ]] && _tc rust "$(basename "$d")" "${d%/}"; done
  for d in "$HOME"/.sdkman/candidates/java/*/;   do [[ -d "$d" && ! -L "${d%/}" ]] && _tc java "$(basename "$d")" "${d%/}"; done
  for d in /Library/Java/JavaVirtualMachines/*/; do [[ -d "$d" ]] && _tc java "$(basename "$d")" "${d%/}"; done
  for d in /Applications/Xcode*.app;             do [[ -d "$d" ]] && _tc xcode "$(defaults read "$d/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "?")" "$d"; done
  [[ -d "$HOME/Library/Android/sdk" ]] && _tc android-sdk "sdk" "$HOME/Library/Android/sdk"
  [[ -d "/Applications/Android Studio.app" ]] && _tc android-studio "app" "/Applications/Android Studio.app"
  [[ -d "/Applications/Docker.app" ]] && _tc docker "$(defaults read /Applications/Docker.app/Contents/Info CFBundleShortVersionString 2>/dev/null || echo "?")" "/Applications/Docker.app"
  [[ -d "$HOME/flutter" ]] && _tc flutter "sdk" "$HOME/flutter"
  for d in /opt/homebrew/Cellar /usr/local/Cellar; do
    [[ -d "$d" ]] && _tc homebrew "$(find "$d" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ') formulae" "$d"
  done
  if (( found )); then
    note "Reported only. Remove a toolchain with its own uninstaller (nvm uninstall, rustup toolchain uninstall, brew uninstall, …)."
  fi
  return 0
}

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

  # The detailed disk/memory/CPU/battery/SMART panels are advisory; suppress
  # them under --quiet (the one-line info() summaries above already self-gate).
  if (( ! QUIET )); then
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
  fi

  s00_toolchains

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

