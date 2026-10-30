# shellcheck shell=bash
# macleanup — module 07 of 10, lines 2674–3073 of the pre-5.2.2 single script.
# Sourced in order by macleanup.sh; never run on its own.

# Section 19 — Browser caches
s19_browser_caches() {
  header "[19] Browser caches"
  warn "This invalidates browser caches (next page loads will be slower)."
  if ! confirm "Proceed with browser cache cleanup?"; then mark_done 19; return 0; fi

  # Chromium-family browsers: "<App Support User-Data dir>|<~/Library/Caches dir>".
  # Covers all profiles (Default, Profile 1…), not just Default.
  local entry as_rel caches_rel
  for entry in \
    "Google/Chrome|com.google.Chrome" \
    "Google/Chrome Canary|com.google.Chrome.canary" \
    "BraveSoftware/Brave-Browser|BraveSoftware" \
    "Microsoft Edge|com.microsoft.edgemac" \
    "Vivaldi|com.vivaldi.Vivaldi" \
    "Chromium|org.chromium.Chromium" \
    "com.operasoftware.Opera|com.operasoftware.Opera" \
    "com.operasoftware.OperaGX|com.operasoftware.OperaGX" \
    "DuckDuckGo|com.duckduckgo.macos.browser" \
    "Arc|com.thebrowser.Browser"; do
    as_rel="${entry%%|*}"; caches_rel="${entry#*|}"
    clean_chromium_caches "$HOME/Library/Application Support/$as_rel" "$HOME/Library/Caches/$caches_rel"
  done
  # Chrome helper + Arc's "Company" cache dir (non-standard locations).
  local d
  for d in "$HOME/Library/Caches/com.google.Chrome.helper" "$HOME/Library/Caches/Company/Arc"; do
    [[ -d "$d" ]] && clean_dir_contents "$d"
  done

  # Firefox-family (Firefox + forks share the cache2 layout): top-level Caches
  # entries plus per-profile cache2 under each profiles root.
  local ff
  for ff in \
    "org.mozilla.firefox" "Firefox" \
    "org.mozilla.firefoxdeveloperedition" "org.mozilla.nightly" \
    "org.mozilla.librewolf" "org.floorp.Floorp" "app.zen-browser.zen"; do
    [[ -d "$HOME/Library/Caches/$ff" ]] && clean_dir_contents "$HOME/Library/Caches/$ff"
  done
  local prof_root
  for prof_root in \
    "$HOME/Library/Application Support/Firefox/Profiles" \
    "$HOME/Library/Application Support/zen/Profiles" \
    "$HOME/Library/Application Support/Floorp/Profiles" \
    "$HOME/Library/Application Support/LibreWolf/Profiles"; do
    [[ -d "$prof_root" ]] || continue
    while IFS= read -r d; do
      [[ -d "$d/cache2" ]] && clean_dir_contents "$d/cache2"
    done < <(find "$prof_root" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
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
  local skipped=0 evaluated=0 running_skipped=0
  while IFS= read -r app; do
    [[ -z "$app" ]] && continue
    name=$(basename "$app" .app)
    bid=$(defaults read "$app/Contents/Info" CFBundleIdentifier 2>/dev/null || echo "")
    [[ -z "$bid" ]] && continue
    is_apple_bundle "$bid" && continue
    # Condition (a) — "not used by any active software": never flag an app that
    # is running right now. pgrep failures (e.g. a regex-special char in the
    # path) are swallowed and fall through to the timestamp logic, matching the
    # prior behaviour. The '.' in '.app' over-matches slightly toward "running",
    # which is the safe direction.
    if pgrep -f "$app/Contents/MacOS/" >/dev/null 2>&1; then
      running_skipped=$(( running_skipped + 1 )); continue
    fi
    evaluated=$(( evaluated + 1 ))

    local last_epoch=0 source="unknown" last_str=""
    # 1) Spotlight last-used (best signal when present)
    last_str=$(mdls -name kMDItemLastUsedDate -raw "$app" 2>/dev/null || echo "(null)")
    if [[ -n "$last_str" && "$last_str" != "(null)" ]]; then
      last_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S %z" "$last_str" +%s 2>/dev/null || echo 0)
      [[ "$last_epoch" != "0" ]] && source="spotlight"
    fi
    # 2) Saved Application State — newest of atime/mtime (a recent READ counts
    #    as a launch even when the file wasn't rewritten).
    if (( last_epoch == 0 )); then
      local sav="$HOME/Library/Saved Application State/$bid.savedState"
      if [[ -e "$sav" ]]; then
        last_epoch=$(_path_newer_ts "$sav")
        [[ "$last_epoch" != "0" ]] && source="savedstate"
      fi
    fi
    # 3) Container (sandboxed apps) — newest of atime/mtime.
    if (( last_epoch == 0 )); then
      local ctr="$HOME/Library/Containers/$bid"
      if [[ -d "$ctr" ]]; then
        last_epoch=$(_path_newer_ts "$ctr")
        [[ "$last_epoch" != "0" ]] && source="container"
      fi
    fi
    # 4) Preferences plist — newest of atime/mtime. Prefs are only REWRITTEN
    #    when settings change, but they're READ on every launch, so atime is
    #    the more reliable recency signal here.
    if (( last_epoch == 0 )); then
      local pref="$HOME/Library/Preferences/$bid.plist"
      if [[ -e "$pref" ]]; then
        last_epoch=$(_path_newer_ts "$pref")
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
  note "Evaluated ${evaluated} apps; skipped ${skipped} with no usable last-used signal; skipped ${running_skipped} currently running."

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
  local d sz_kb b nm last p
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
    # Guard against an empty name/bundle-id producing a bare parent directory
    # (e.g. ".../Application Support/") that would then be deleted wholesale.
    [[ -n "$app_name" && -n "$app_bid" ]] || return 0
    # Bundle-ID-confined paths: a bundle id is unique, so these belong only to
    # THIS app — safe to remove with the app.
    for candidate in \
      "$HOME/Library/Application Support/$app_bid" \
      "$HOME/Library/Containers/$app_bid" \
      "$HOME/Library/Caches/$app_bid" \
      "$HOME/Library/Preferences/$app_bid.plist" \
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
    # Name-based paths: a DIFFERENT, actively-used installed app could store
    # data under the same display-name folder (generic names like "Updater",
    # "Player"). Only include such a folder when it is itself idle for
    # >= UNUSED_APP_THRESHOLD_DAYS (readable timestamp required); recent or
    # unknown-age => keep, so we never delete an in-use app's data. (4.5.0)
    local _now2; _now2=$(date +%s)
    for candidate in \
      "$HOME/Library/Application Support/$app_name" \
      "$HOME/Library/Caches/$app_name" \
      "$HOME/Library/Logs/$app_name"; do
      [[ -e "$candidate" ]] || continue
      local _ca _cm _cn
      _ca=$(stat -f %a "$candidate" 2>/dev/null || echo 0)
      _cm=$(stat -f %m "$candidate" 2>/dev/null || echo 0)
      _cn=$_ca; (( _cm > _cn )) && _cn=$_cm
      if (( _cn > 0 )) && (( (_now2 - _cn) / 86400 >= UNUSED_APP_THRESHOLD_DAYS )); then
        _data_paths+=("$candidate")
      fi
    done
  }

  # Helper: uninstall a single app + its companion data, tracking freed KB.
  _uninstall_app() {
    local app_path="$1" app_name="$2" app_size_kb="$3"
    local dp kb
    if (( DRY_RUN )); then
      note "[dry-run] would move $app_path and ${#_data_paths[@]} data path(s) to Trash"
      return 0
    fi
    if osascript_trash "$app_path"; then
      ok "Moved $app_name to Trash"
      TOTAL_FREED_KB=$(( TOTAL_FREED_KB + app_size_kb ))
    else
      warn "Could not move $app_path to Trash; left app and data in place. Check Finder Automation access."
      return 1
    fi
    # Companion data must also remain recoverable if a name-match was wrong.
    for dp in "${_data_paths[@]+"${_data_paths[@]}"}"; do
      kb=$(size_kb "$dp")
      if osascript_trash "$dp"; then
        TOTAL_FREED_KB=$(( TOTAL_FREED_KB + kb ))
      else
        warn "Could not move $dp to Trash; left it in place. Check Finder Automation access."
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

