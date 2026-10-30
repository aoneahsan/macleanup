# shellcheck shell=bash
# macleanup — module 09 of 10, lines 3448–3888 of the pre-5.2.2 single script.
# Sourced in order by macleanup.sh; never run on its own.

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
  s25_running_services

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
      # Fallback: grep raw plist bytes for a /-rooted path. Unlike a
      # structured plist value, a raw string with spaces could be either a
      # pathname or a command plus arguments; do not guess and misreport it.
      target=$(strings "$plist" 2>/dev/null \
        | awk '/^\/[^ ]+/ && length($0) < 256 {print; exit}' || true)
      [[ "$target" == *' '* ]] && continue
    fi
    [[ -z "$target" ]] && continue
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

  # --yes auto-selects every item in multi_select. Keep the audit report-only
  # in batch unless removal has the same two-flag opt-in as deep sections.
  if (( BATCH_MODE && ( ! ASSUME_YES || ! DEEP_OPT_IN ) )); then
    note "Batch mode: report-only. To remove stale launch items unattended, pass both --yes and --i-understand-deep."
    mark_done 25; press_enter; return 0
  fi

  warn "Removing a system launch item under /Library may need sudo."
  warn "Unloading + deleting prevents the orphaned item from running again."
  local selected
  if (( BATCH_MODE )); then
    selected=$(multi_select "${#stale_path[@]}")
  else
    # The menu's assume-yes toggle must not silently select every plist.
    selected=$(ASSUME_YES=0 multi_select "${#stale_path[@]}")
  fi
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
  # Use find -mindepth 1 -maxdepth 1 rather than a "$HOME"/* "$HOME"/.* glob:
  # the glob's `.*` expands to `.` (re-scans all of $HOME) and `..` (= /Users,
  # scanning EVERY user's home). The old grep tried to drop those but the regex
  # never matched the full absolute paths, so du walked them anyway — turning a
  # ~30s report into a multi-minute, cross-user scan.
  find "$HOME" -mindepth 1 -maxdepth 1 -exec du -sh {} + 2>/dev/null \
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

# Section 27 — macOS UI maintenance: QuickLook thumbnails + font caches
# Resets regenerable UI caches that commonly cause garbled fonts or stale
# QuickLook previews. Everything here rebuilds automatically on demand, so it
# is non-destructive. Menu / --only only (never in --all).
s27_ui_maintenance() {
  header "[27] macOS UI maintenance: QuickLook + font caches"
  info "Resets regenerable UI caches (QuickLook thumbnails, font caches). They rebuild on demand."

  # QuickLook thumbnail cache — no sudo; regenerates next time you preview a file.
  if has_cmd qlmanage; then
    if (( DRY_RUN )); then
      note "[dry-run] qlmanage -r cache"
    else
      qlmanage -r cache >/dev/null 2>&1 && ok "QuickLook thumbnail cache reset" \
        || warn "qlmanage cache reset returned non-zero"
    fi
  else
    note "qlmanage unavailable — skipping QuickLook cache."
  fi

  # Font caches — clearing fixes duplicate/garbled fonts. User scope needs no
  # sudo; the system scope is offered separately and never forced.
  if has_cmd atsutil; then
    if (( DRY_RUN )); then
      note "[dry-run] atsutil databases -removeUser"
    else
      atsutil databases -removeUser >/dev/null 2>&1 && ok "User font cache cleared" \
        || warn "atsutil (user) returned non-zero"
    fi
    if confirm "Also clear the SYSTEM font cache (needs sudo)?"; then
      if require_sudo "system font cache"; then
        if (( DRY_RUN )); then
          note "[dry-run] sudo atsutil databases -remove"
        else
          sudo atsutil databases -remove >/dev/null 2>&1 && ok "System font cache cleared" \
            || warn "atsutil (system) returned non-zero"
          note "A logout or restart finalises the font-cache rebuild."
        fi
      fi
    fi
  else
    note "atsutil unavailable — skipping font caches."
  fi

  mark_done 27; press_enter
}

# ──────────────────────────────────────────────────────────────────────────
#                              MENU / FLOW
# ──────────────────────────────────────────────────────────────────────────

# Sections that --all runs unattended (caches/logs/temp/reports only).
# Section 13 (`sudo periodic`) was removed in 4.5.0 — it is privileged system
# maintenance, not a cache/log/temp/report cleanup, so it no longer runs under
# --all; invoke it from the menu or with --only 13.
SAFE_BATCH=(0 3 5 7 8 9 15 18 22 26)

# Deep, irreversible sections that must NOT run unattended via --only/--profile
# /--all even with --yes. They require a logged-in human at the menu, OR the
# explicit --i-understand-deep opt-in (which --yes alone does NOT set). The set
# is space-padded for a substring membership test.
#   6  system caches wiped as root      10 Trash emptied permanently
#   11 Time Machine local snapshots      14 /private/var/folders deep wipe
#   21 app uninstall + companion data   24 large stale files → Trash
DEEP_INTERACTIVE_SECTIONS=" 6 10 11 14 21 24 "

run_all_safe() {
  step "Running safe-batch sections: ${SAFE_BATCH[*]}"
  local s
  for s in "${SAFE_BATCH[@]}"; do
    dispatch "$s"
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
  if (( ${#ATTEMPTED_SECTIONS[@]} > 0 )); then
    printf '   Attempted:         %s\n' "${ATTEMPTED_SECTIONS[*]}"
    printf '   Skipped:           %s\n' "${SKIPPED_SECTIONS[*]:-(none)}"
    printf '   Failed:            %s\n' "${FAILED_SECTIONS[*]:-(none)}"
  fi
  local _snaps=0
  has_cmd tmutil && _snaps=$(tmutil listlocalsnapshots / 2>/dev/null | grep -c 'com.apple' || true)
  if (( ${_snaps:-0} > 0 )); then
    printf '%b   Local snapshots:   %s — space from deleted files may stay in use until macOS releases them (section 11).%b\n' "$DIM" "$_snaps" "$NC"
  fi
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
  printf '\n%b   %s v%s · %s%b\n' \
    "$DIM" "$SCRIPT_NAME" "$SCRIPT_VERSION" "$PROJECT_WEBSITE" "$NC"
}

# _finish_run — common end-of-run handling. Prints the human session summary
# (which, in --json mode, has been redirected to stderr by main), then in
# --json mode restores real stdout (saved on fd 3) and emits the JSON object as
# the sole stdout line, and finally fires the optional completion notification.
_finish_run() {
  session_summary
  if (( JSON_MODE )); then
    exec 1>&3 3>&-
    emit_json
  fi
  if (( JSON_EVENTS )); then
    DISK_FREE_AFTER_KB=$(disk_free_kb /)
    ev_disk after
    ev_summary
    exec 1>&3 3>&-
  fi
  notify_user "macleanup" "Done — freed $(human_kb "$TOTAL_FREED_KB")"
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
  printf '%b   macleanup v%s   —   macOS %s (%s)   RAM %s   Free %s%b\n' \
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
  LBL[8]="Temp files (\$TMPDIR, /tmp)"
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
  LBL[27]="macOS UI maintenance: QuickLook + font caches"

  local i mark
  for i in $(seq 0 27); do
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

# dispatch n — run one section; under --json-events, frame it with
# section_start / section_result and the attempted/completed/skipped/failed
# accounting.
dispatch() {
  local n="$1" rc=0 freed_before reason status
  CURRENT_SECTION="$n"; SECTION_ITEMS=0; LAST_SKIP_REASON=""
  ATTEMPTED_SECTIONS+=("$n")
  freed_before=$TOTAL_FREED_KB
  ev_emit section_start "\"id\":$n,\"title\":\"$(json_escape "$(section_title "$n")")\",\"stamp\":\"${SECTION_TIERS[$n]:-read}\""
  dispatch_section "$n" || rc=$?
  reason="null"
  if is_done "$n"; then
    status=completed
  elif (( rc != 0 )); then
    status=failed; FAILED_SECTIONS+=("$n")
    reason="\"$(json_escape "${LAST_SKIP_REASON:-section returned $rc}")\""
  else
    status=skipped; SKIPPED_SECTIONS+=("$n")
    case "$LAST_SKIP_REASON" in
      *interactive-only*) LAST_SKIP_REASON="needs --i-understand-deep" ;;
      *sudo*) LAST_SKIP_REASON="needs administrator password" ;;
    esac
    reason="\"$(json_escape "${LAST_SKIP_REASON:-nothing to do}")\""
  fi
  ev_emit section_result "\"id\":$n,\"status\":\"$status\",\"freed_kb\":$(( TOTAL_FREED_KB - freed_before )),\"items\":$SECTION_ITEMS,\"reason\":$reason"
  CURRENT_SECTION=""
  return 0
}

dispatch_section() {
  local n="$1"
  # Enforce the "human-present" safety contract: deep destructive sections are
  # refused under batch mode unless the operator explicitly opted in with
  # both --yes and --i-understand-deep. Dry-run is allowed through (it cannot
  # touch disk) so previews still work. The interactive menu is unaffected.
  if (( BATCH_MODE && ! DRY_RUN && ( ! DEEP_OPT_IN || ! ASSUME_YES ) )) \
     && [[ "$DEEP_INTERACTIVE_SECTIONS" == *" $n "* ]]; then
    warn "Section $n is interactive-only; refusing to auto-run it under --only/--profile/--all."
    note "Run it from the menu, or pass both --yes and --i-understand-deep to allow it unattended."
    return 0
  fi
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
    27) s27_ui_maintenance ;;
    *)  warn "Unknown section: $1" ;;
  esac
}

