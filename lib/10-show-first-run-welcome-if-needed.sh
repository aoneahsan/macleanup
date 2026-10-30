# shellcheck shell=bash
# macleanup — module 10 of 10, lines 3889–4042 of the pre-5.2.2 single script.
# Sourced in order by macleanup.sh; never run on its own.

# show_first_run_welcome_if_needed — one-time intro screen, marker file
# at $DEFAULT_DATA_DIR/.welcomed. Skipped for non-interactive runs
# (BATCH_MODE is set when --all / --only / --profile is used). Skipped
# also when stdin isn't a TTY (cron, CI). Quick-exit flags like
# --version / --help / --contact / --stats already exit before main()
# is called, so they never see this.
show_first_run_welcome_if_needed() {
  local marker="$DEFAULT_DATA_DIR/.welcomed"
  [[ -f "$marker" ]] && return 0
  (( BATCH_MODE )) && { touch "$marker" 2>/dev/null; return 0; }
  [[ -t 0 ]] || { touch "$marker" 2>/dev/null; return 0; }

  printf '\n%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$BOLD$MAGENTA" "$NC"
  printf '%b   Welcome to %s — first run on this machine 👋%b\n' "$BOLD$MAGENTA" "$SCRIPT_NAME" "$NC"
  printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n\n' "$BOLD$MAGENTA" "$NC"

  printf '%b A few things you should know:%b\n\n' "$BOLD" "$NC"
  printf '   1. %bDry-run is sacred.%b The very first time you try a destructive\n' "$GREEN" "$NC"
  printf '      section, prefix it with %b--dry-run%b. Nothing will be deleted.\n\n' "$CYAN" "$NC"
  printf '   2. %bReports + logs persist%b at %s\n' "$GREEN" "$NC" "$DEFAULT_DATA_DIR"
  printf '      They survive npx cache cleanup. Run %b%s --stats%b later for history.\n\n' "$CYAN" "$SCRIPT_NAME" "$NC"
  printf '   3. %bSafety rules%b — non-cache deletes need both:\n' "$GREEN" "$NC"
  printf '      (a) not used by any active software/tool, AND\n'
  printf '      (b) not touched by you for ≥ 100 days. Idleness uses mtime +\n'
  printf '      atime as a best-effort heuristic (atime on APFS is approximate).\n\n'
  printf '   4. %bSomething wrong?%b\n' "$GREEN" "$NC"
  printf '      %b%s --report-issue%b   open a pre-filled GitHub issue\n' "$CYAN" "$SCRIPT_NAME" "$NC"
  printf '      %b%s --feedback%b       email the macleanup team\n' "$CYAN" "$SCRIPT_NAME" "$NC"
  printf '      %b%s --contact%b        full contact card\n\n' "$CYAN" "$SCRIPT_NAME" "$NC"
  printf '%b Recommended first run:%b\n   %s --dry-run --all\n\n' "$BOLD" "$NC" "$SCRIPT_NAME"

  printf '%bPress Enter to continue (this screen shows once)…%b' "$DIM" "$NC"
  read -r _ || true
  touch "$marker" 2>/dev/null || true
  printf '\n'
}

# print_legacy_notes — one stderr line per pre-5 name still in use.
print_legacy_notes() {
  local note
  for note in "${LEGACY_NOTES[@]+"${LEGACY_NOTES[@]}"}"; do
    printf '%b[NOTE]%b %s\n' "$YELLOW" "$NC" "$note" >&2
  done
}

main() {
  # Load ~/.macleanuprc defaults BEFORE argv so explicit CLI flags win.
  load_rc_file
  print_legacy_notes
  parse_args "$@"
  # Make sure logs/reports dirs exist after any --logs-dir / --reports-dir
  # overrides that may have been parsed from argv.
  mkdir -p "$LOG_DIR" "$REPORTS_DIR" 2>/dev/null || true
  init_log_file
  show_first_run_welcome_if_needed
  DISK_FREE_BEFORE_KB=$(disk_free_kb /)
  log_to_file "── macleanup v$SCRIPT_VERSION started ──"

  # --json: send every human/log line to stderr (real stdout saved on fd 3) so
  # the only thing written to stdout is the JSON object emitted by _finish_run.
  if (( JSON_MODE )); then exec 3>&1 1>&2; fi
  if (( JSON_EVENTS )); then
    if (( JSON_MODE )); then err "--json and --json-events cannot be combined"; exit 2; fi
    if [[ -z "$ONLY_SECTIONS" && -z "$PROFILE_NAME" ]] && (( ! RUN_ALL )); then
      err "--json-events needs --only, --profile or --all"; exit 2
    fi
    exec 3>&1 1>&2
    EV_READY=1
  fi

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
    ev_plan "$ONLY_SECTIONS"; ev_disk before
    step "Running explicit sections: $ONLY_SECTIONS"
    local s
    IFS=',' read -r -a _arr <<<"$ONLY_SECTIONS"
    for s in "${_arr[@]+"${_arr[@]}"}"; do
      s="${s// /}"
      [[ "$s" =~ ^[0-9]+$ ]] || { warn "Skipping invalid section '$s'"; continue; }
      dispatch "$s"
    done
    _finish_run
    (( JSON_EVENTS )) && (( ${#FAILED_SECTIONS[@]} > 0 )) && exit 1
    return 0
  fi

  if (( RUN_ALL )); then
    if [[ -n "$EXCLUDE_SECTIONS" ]]; then
      # Build a filtered version of SAFE_BATCH and run those instead.
      local _safe_csv _filtered s
      _safe_csv="$(IFS=,; echo "${SAFE_BATCH[*]}")"
      _filtered="$(apply_exclude "$_safe_csv")"
      ev_plan "$_filtered"; ev_disk before
      step "Safe batch with --exclude: $_filtered"
      IFS=',' read -r -a _arr <<<"$_filtered"
      for s in "${_arr[@]+"${_arr[@]}"}"; do
        s="${s// /}"
        [[ "$s" =~ ^[0-9]+$ ]] && dispatch "$s"
      done
    else
      ev_plan "$(IFS=,; echo "${SAFE_BATCH[*]}")"; ev_disk before
      run_all_safe
    fi
    _finish_run
    (( JSON_EVENTS )) && (( ${#FAILED_SECTIONS[@]} > 0 )) && exit 1
    return 0
  fi

  while true; do
    show_menu
    printf '%bSelect [0-27 / A / D / Y / S / Q]:%b ' "$BOLD" "$NC"
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
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 0 && choice <= 27 )); then
          dispatch "$choice"
        else
          warn "Unrecognised choice: $choice"
        fi ;;
    esac
  done

  _finish_run
  log_to_file "── macleanup ended ──"
  # Note: --cleanup-logs-on-finish is handled by the EXIT trap so it
  # fires for every code path (interactive quit, --only, --all, signals).
}

