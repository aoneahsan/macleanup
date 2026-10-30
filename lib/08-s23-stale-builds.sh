# shellcheck shell=bash
# macleanup — module 08 of 10, lines 3074–3447 of the pre-5.2.2 single script.
# Sourced in order by macleanup.sh; never run on its own.

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
    note "    macleanup --only 23 --scan-roots \"\$HOME/path/to/dev\""
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
  # User-supplied --exclude-path entries get the same literal + subtree guard.
  local _xp
  for _xp in "${EXCLUDE_PATHS[@]+"${EXCLUDE_PATHS[@]}"}"; do
    critical_excludes+=( ! -path "$_xp" ! -path "$_xp/*" )
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
    for e in "${EXCLUDE_PATHS[@]+"${EXCLUDE_PATHS[@]}"}"; do
      [[ "$p" == "$e" || "$p" == "$e/"* ]] && return 0
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

  # Honour any --exclude-path entries (literal path + subtree).
  local _xpaths=() _xp
  for _xp in "${EXCLUDE_PATHS[@]+"${EXCLUDE_PATHS[@]}"}"; do
    _xpaths+=( ! -path "$_xp" ! -path "$_xp/*" )
  done

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
    "${_xpaths[@]+"${_xpaths[@]}"}" \
    -print 2>/dev/null > "$results" || true

  if [[ ! -s "$results" ]]; then
    ok "No large stale files found (≥ ${size_gb} GB, ≥ ${days} days idle)."
    mark_done 24; press_enter; return 0
  fi

  declare -a items_path=() items_kb=() items_age=()
  local total_kb=0 now newer age path sz_kb i
  now=$(date +%s)
  while IFS= read -r path; do
    [[ -f "$path" ]] || continue
    sz_kb=$(size_kb "$path")
    newer=$(_path_newer_ts "$path")   # one stat, max(atime,mtime)
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
# s25_running_services — list loaded Homebrew and third-party services in BOTH
# launchd domains (your user's gui domain and the system domain). `brew
# services list` only shows the domain it was run in, so a root service can be
# running while it says "none". Read-only: nothing is stopped here.
s25_running_services() {
  has_cmd launchctl || return 0
  local uid line domain label shown=0
  uid=$(id -u)
  for domain in "gui/$uid" system; do
    while IFS= read -r line; do
      label=$(printf '%s' "$line" | awk '{print $NF}')
      [[ -z "$label" || "$label" == com.apple.* ]] && continue
      case "$label" in
        homebrew.mxcl.*|*.mxcl.*) ;;
        *) [[ "$domain" == system ]] || continue ;;
      esac
      if (( shown == 0 )); then
        printf '\n%bLoaded services (user and system domains):%b\n' "$BOLD" "$NC"
        shown=1
      fi
      printf '   %-10s %s\n' "${domain%%/*}" "$label"
      (( JSON_EVENTS )) && ev_item "launchd:${domain%%/*}/$label" 0 report
    done < <(launchctl print "$domain" 2>/dev/null \
      | awk '/^[[:space:]]*services = \{/{f=1;next} f&&/^[[:space:]]*\}/{f=0} f{print}' \
      | awk '$1 ~ /^[0-9]+$/ && $1 > 0 {print}')
  done
  if (( shown )); then
    note "Running system-domain services keep working after a user-level \"brew services\" says none."
    note "Stop one with: sudo brew services stop <name>  (or keep it; this audit changes nothing)."
  fi
}

