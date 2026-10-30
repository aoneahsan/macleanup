# shellcheck shell=bash
# macleanup — module 06 of 10, lines 2239–2673 of the pre-5.2.2 single script.
# Sourced in order by macleanup.sh; never run on its own.

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
    n=${app##*/}; n=${n%.app}   # builtin basename (no fork)
    printf '%s\n' "$n" >> "$installed_names"
    bid=$(defaults read "$app/Contents/Info" CFBundleIdentifier 2>/dev/null || echo "")
    [[ -n "$bid" ]] && printf '%s\n' "$bid" >> "$installed_bids"
  done < "$apps_file"

  # Helper: is given basename matched by any installed app?
  local report _have_report=0
  report="$ORPHAN_REPORT"
  if init_report_file "$report" "orphan app data scan"; then
    _have_report=1
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
    # token presence: split candidate and see if any token equals app name.
    # Floor of 2 chars (lowered from 4 in 4.5.0): matching MORE is the safe
    # direction here — every extra match means an entry is treated as belonging
    # to an installed app and skipped, so it can only REDUCE false orphans.
    local token
    for token in $(echo "$lc" | tr '.,_-' '\n'); do
      [[ ${#token} -lt 2 ]] && continue
      if grep -Fxqi -- "$token" "$installed_names" 2>/dev/null; then return 0; fi
    done
    return 1
  }

  declare -a candidates=() recent_list=()
  local recent_skipped=0
  local _now; _now=$(date +%s)
  local _idle_days="$IDLE_THRESHOLD_DAYS"

  _scan_dir() {
    # Take find predicates as discrete positional args (not a single splittable
    # string): passing them as "$@" keeps globs like '*.plist' literal instead
    # of letting the shell expand them against the CURRENT directory before find
    # ever sees them (which silently broke the Preferences/LaunchAgents scan
    # when run from a folder containing .plist files).
    local dir="$1"; shift
    [[ -d "$dir" ]] || return 0
    local entry
    while IFS= read -r entry; do
      local base=${entry##*/}
      # ignore Apple
      is_apple_bundle "$base" && continue
      [[ "$base" == "."* ]] && continue
      _match_installed "$base" && continue
      # 4.3.3 SAFETY: orphaned-by-bundle-ID is condition (a). Now also
      # require condition (b): the entry hasn't been touched (atime AND
      # mtime) for ≥ IDLE_THRESHOLD_DAYS. Skip recently-active items
      # even if our heuristic matcher couldn't find an installed app —
      # something IS using it.
      local _newer _idle
      _newer=$(_path_newer_ts "$entry")   # one stat, max(atime,mtime)
      # Unknown age (unreadable timestamps) MUST mean keep, not delete — for a
      # safety-critical non-cache delete, "I can't tell how old this is" fails
      # toward preservation. Only entries with a readable timestamp AND
      # idle >= threshold become candidates.
      if (( _newer <= 0 )); then
        recent_skipped=$(( recent_skipped + 1 ))
        (( ${#recent_list[@]} < 500 )) && recent_list+=("$entry")
        continue
      fi
      _idle=$(( (_now - _newer) / 86400 ))
      if (( _idle < _idle_days )); then
        recent_skipped=$(( recent_skipped + 1 ))
        (( ${#recent_list[@]} < 500 )) && recent_list+=("$entry")
        continue
      fi
      candidates+=("$entry")
    done < <(find "$dir" -mindepth 1 -maxdepth 1 "$@" 2>/dev/null)
  }

  _scan_dir "$HOME/Library/Application Support" -type d
  _scan_dir "$HOME/Library/Containers"          -type d
  _scan_dir "$HOME/Library/Group Containers"    -type d
  _scan_dir "$HOME/Library/Saved Application State" -type d
  _scan_dir "$HOME/Library/Preferences"         -type f -name '*.plist'
  _scan_dir "$HOME/Library/LaunchAgents"        -type f -name '*.plist'

  if (( recent_skipped > 0 )); then
    note "Skipped $recent_skipped orphan-shaped entries that were touched within the last ${_idle_days} days (probably still in use)."
    note "They are listed for review in the report. A skipped entry is not proof that nothing is left behind."
    local _r
    if (( _have_report )); then
      printf '\n# Recent orphan-shaped entries (touched within %s days; review only, never removed by this section)\n\n' "$_idle_days" >> "$report"
    fi
    for _r in "${recent_list[@]+"${recent_list[@]}"}"; do
      (( _have_report )) && printf '%s\n' "$_r" >> "$report"
      (( JSON_EVENTS )) && ev_item "$_r" 0 report
    done
    (( _have_report )) && printf '\n# Orphan candidates (idle at least %s days)\n\n' "$_idle_days" >> "$report"
  fi

  if (( ${#candidates[@]} == 0 )); then
    ok "No orphaned data found older than ${_idle_days} days."
    mark_done 12; press_enter; return 0
  fi

  info "Found ${#candidates[@]} candidate orphan entries (orphaned AND idle ≥${_idle_days}d). Reporting to:"
  note "$report"
  # Compute each candidate's size ONCE and cache it (reused in the review loop).
  # Write data rows to a temp file and sort only those, so the report's branding
  # banner isn't shuffled into the data — and so --no-reports writes nothing.
  local total_kb=0 c sz_kb idx=0
  declare -a cand_kb=()
  local data; data=$(tmp_file); : > "$data"
  for c in "${candidates[@]}"; do
    sz_kb=$(size_kb "$c")
    cand_kb[idx]=$sz_kb; idx=$(( idx + 1 ))
    (( JSON_EVENTS )) && ev_item "$c" "$sz_kb" trash
    total_kb=$(( total_kb + sz_kb ))
    printf '%s\t%s\n' "$(human_kb "$sz_kb")" "$c" >> "$data"
  done
  if (( _have_report )); then
    sort -hr "$data" 2>/dev/null >> "$report" || cat "$data" >> "$report"
  fi
  info "Total candidate size: $(human_kb "$total_kb")"

  if (( BATCH_MODE && ! ASSUME_YES )); then
    note "Batch mode: report-only. Re-run interactively to delete."
    mark_done 12; press_enter; return 0
  fi

  if confirm "Review candidates one by one to delete?" 0; then
    local i=0 reply
    for c in "${candidates[@]}"; do
      i=$((i+1))
      sz_kb=${cand_kb[$(( i - 1 ))]}
      printf '\n%b[%d/%d]%b %s  (%s)\n' "$CYAN" "$i" "${#candidates[@]}" "$NC" "$c" "$(human_kb "$sz_kb")"
      printf '%bDelete? [y/N/q to quit]%b ' "$BOLD" "$NC"
      read -r reply || reply=""
      case "$reply" in
        [yY]|[yY][eE][sS])
          # Orphan matching is a heuristic. A Finder failure must leave the
          # candidate in place rather than turn a recoverable action into a
          # permanent delete.
          if (( DRY_RUN )); then note "[dry-run] would move to Trash: $c"
          elif osascript_trash "$c"; then
            TOTAL_FREED_KB=$(( TOTAL_FREED_KB + sz_kb ))
            ok "Moved to Trash"
          else
            warn "Could not move $c to Trash; left it in place. Check Finder Automation access."
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
  # NOTE: this is a deliberate FULL wipe of /private/var/folders to depth 3 —
  # the T (temp), C (Darwin user cache) and 0 (per-bootsession) subtrees, which
  # is why it demands literal "yes", sudo, and a reboot. We exclude symlinks
  # (! -type l) so a link is never followed/expanded, but otherwise do not
  # age-filter: clearing the accumulated state is the whole point of this
  # menu-only nuclear option.
  if (( DRY_RUN )); then
    note "[dry-run] sudo find /private/var/folders -mindepth 1 -maxdepth 3 ! -type l -print0 | xargs -0 sudo rm -rf"
  else
    sudo find /private/var/folders -mindepth 1 -maxdepth 3 ! -type l -print0 2>/dev/null \
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

  # Old iOS/iPadOS software-update downloads (.ipsw) — multi-GB and fully
  # re-downloadable from Apple. Age-gated, and handled before the backups
  # check so they're swept even when no device backup exists.
  local _ipsw
  for _ipsw in \
    "$HOME/Library/iTunes/iPhone Software Updates" \
    "$HOME/Library/iTunes/iPad Software Updates"; do
    if [[ -d "$_ipsw" ]]; then
      info "iOS software-update downloads: $(size_h "$_ipsw") in $(basename "$_ipsw")"
      clean_dir_unused "$_ipsw" "$CACHE_AGE_DAYS"
    fi
  done

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
      # The first form's trailing 'Z' is literal UTC; force TZ=UTC so the epoch
      # isn't shifted by the local zone. The second form carries its own %z and
      # must NOT be wrapped, or it would be double-shifted.
      _epoch=$(TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%SZ" "$date" +%s 2>/dev/null \
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
  # Prune (do not descend into) libraries and synced folders: a ! -path filter
  # still walks every file beneath them, and iCloud folders can be very slow.
  find "$HOME" -maxdepth 7 \
    \( -path "*/Library/CloudStorage" -o -path "*/Library/Mobile Documents" \
       -o -path "*/Library/Photos" -o -name "*.photoslibrary" -o -path "$HOME/Movies" \
       -o -path "$HOME/Music" -o -name "Virtual Machines" -o -path "$HOME/.Trash" \
       -o -name "Parallels" -o -name "VMware" \) -prune \
    -o -type f -size +500M -exec du -h {} + 2>/dev/null \
    | sort -hr \
    | head -25 > "$_scan"
  (( QUIET )) || cat "$_scan"
  if (( JSON_EVENTS )); then
    local _sz _p
    while IFS=$'\t' read -r _sz _p; do
      [[ -n "$_p" ]] && ev_item "$_p" "$(size_kb "$_p")" report
    done < "$_scan"
  fi
  if (( ! NO_REPORTS )); then
    cat "$_scan" >> "$LARGE_FILES_REPORT"
    info "Top entries written to: $LARGE_FILES_REPORT"
  fi
  mark_done 18; press_enter
}

# clean_chromium_caches USER_DATA_DIR  CACHES_DIR
# Clears a Chromium-family browser's HTTP cache (CACHES_DIR under
# ~/Library/Caches) plus per-profile cache subdirs (Default, Profile 1…,
# Guest/System Profile) under USER_DATA_DIR. Only cache subdirs that exist are
# touched — profile data, history, logins, extensions are left intact. Pure
# cache, so clean_dir_contents (DRY_RUN-aware, freed-KB tracking) is used.
clean_chromium_caches() {
  local user_data="$1" caches_dir="$2" prof sub
  [[ -n "$caches_dir" && -d "$caches_dir" ]] && clean_dir_contents "$caches_dir"
  [[ -d "$user_data" ]] || return 0
  while IFS= read -r prof; do
    for sub in "Cache" "Code Cache" "GPUCache" "DawnGraphiteCache" "DawnWebGPUCache" \
               "Service Worker/CacheStorage" "Service Worker/ScriptCache"; do
      [[ -d "$prof/$sub" ]] && clean_dir_contents "$prof/$sub"
    done
  done < <(find "$user_data" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
}

