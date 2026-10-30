# shellcheck shell=bash
# macleanup — module 05 of 10, lines 1877–2238 of the pre-5.2.2 single script.
# Sourced in order by macleanup.sh; never run on its own.

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
  [[ -d "$HOME/.bundle/cache" ]] && clean_dir_unused "$HOME/.bundle/cache" "$CACHE_AGE_DAYS"
  [[ -d "$HOME/.gem/cache" ]]    && clean_dir_unused "$HOME/.gem/cache" "$CACHE_AGE_DAYS"

  # Modern dev caches — regenerable, age-gated. Explicit cache SUBPATHS only;
  # never the toolchain roots (~/.bun, ~/.nvm, ~/.cache, … are in
  # CRITICAL_HOME_DIRS and hold installed binaries / tool state). Caches that
  # live under ~/Library/Caches (Deno, SwiftPM, Carthage, sccache) are already
  # swept by section 5, so they're not repeated here.
  local _devcache
  for _devcache in \
    "$HOME/.bun/install/cache" \
    "$HOME/.ccache" \
    "$HOME/.cache/uv" \
    "$HOME/.cache/deno" \
    "$HOME/.composer/cache" \
    "$HOME/.nvm/.cache"; do
    [[ -d "$_devcache" ]] && clean_dir_unused "$_devcache" "$CACHE_AGE_DAYS"
  done
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
  # Default prune deliberately EXCLUDES --volumes: named volumes routinely hold
  # the only copy of a database for a stopped project, and their loss is
  # irreversible. Images/containers/networks/build-cache are all recoverable.
  if confirm "Prune unused Docker containers, images, networks, build cache (NOT volumes)?"; then
    if (( DRY_RUN )); then
      note "[dry-run] docker system prune -a -f"
    else
      docker system prune -a -f
      ok "Docker pruned (volumes preserved)"
    fi
  fi
  # Volume deletion is offered separately behind a literal-yes gate, and is
  # NEVER run unattended — even with --yes — because the BATCH_MODE skip takes
  # precedence over confirm_yes's (ASSUME_YES && BATCH_MODE) auto-approve.
  if (( BATCH_MODE )); then
    note "Skipping volume prune in batch mode (would delete named-volume data). Run interactively to remove volumes."
  elif confirm_yes "Also remove ALL unused Docker VOLUMES? This permanently deletes database data in named volumes for stopped projects and is NOT recoverable."; then
    if (( DRY_RUN )); then
      note "[dry-run] docker volume prune -f"
    else
      docker volume prune -f && ok "Docker volumes pruned" || warn "docker volume prune failed"
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
    # Preserve Apple, all major browsers (handled in [19]), password managers,
    # and the corepack cache — built from USER_CACHE_PRESERVE so the allowlist
    # has a single source of truth. Each pattern becomes a `! -name P` predicate
    # (AND of negations) — DO NOT introduce -o/grouping here or the allowlist
    # would collapse and the sweep would delete everything.
    local _preserve_args=() _pp
    for _pp in "${USER_CACHE_PRESERVE[@]}"; do _preserve_args+=( ! -name "$_pp" ); done
    if (( DRY_RUN )); then
      local est=0 _entry _ekb
      # One du per top-level entry (the same set the real run removes), so the
      # event stream can list each cache folder with its size.
      while IFS= read -r -d '' _entry; do
        _ekb=$(size_kb "$_entry")
        est=$(( est + _ekb ))
        (( JSON_EVENTS )) && ev_item "$_entry" "$_ekb" delete
      done < <(excl_top_args "$cache_root"; find "$cache_root" -mindepth 1 -maxdepth 1 "${_preserve_args[@]}" ${EXCL_TOP[@]+"${EXCL_TOP[@]}"} -print0 2>/dev/null)
      emit_kept_tops "$cache_root"
      note "[dry-run] would prune ~$(human_kb "$est") of non-Apple/browser/password-manager caches"
      track_freed "$est" 0
    else
      local before after _entry
      before=$(size_kb "$cache_root")
      if (( JSON_EVENTS )); then
        while IFS= read -r -d '' _entry; do
          ev_item "$_entry" "$(size_kb "$_entry")" delete
        done < <(excl_top_args "$cache_root"; find "$cache_root" -mindepth 1 -maxdepth 1 "${_preserve_args[@]}" ${EXCL_TOP[@]+"${EXCL_TOP[@]}"} -print0 2>/dev/null)
      fi
      excl_top_args "$cache_root"
      emit_kept_tops "$cache_root"
      find "$cache_root" -mindepth 1 -maxdepth 1 \
        "${_preserve_args[@]}" ${EXCL_TOP[@]+"${EXCL_TOP[@]}"} \
        -exec rm -rf -- {} + 2>/dev/null || true
      after=$(size_kb "$cache_root")
      track_freed "$before" "$after"
      ok "Cleared $(human_kb "$(( before - after ))") from $cache_root"
    fi
  else
    note "No ~/Library/Caches found."
  fi

  if [[ -d "$HOME/Library/Saved Application State" ]]; then
    local sz; sz=$(size_h "$HOME/Library/Saved Application State")
    if confirm "Clear Saved Application State ($sz)? (windows won't reopen on relaunch)" 1; then
      clean_dir_contents "$HOME/Library/Saved Application State"
    fi
  fi
  # Prune old crash/diagnostic reports (age-aware, matching section 7's logs
  # treatment) rather than wiping unconditionally — a just-filed report can
  # still be useful for --report-issue.
  if [[ -d "$HOME/Library/Logs/DiagnosticReports" ]]; then
    clean_dir_old "$HOME/Library/Logs/DiagnosticReports" 7
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
    excl_top_args /Library/Caches
    sudo find /Library/Caches -mindepth 1 -maxdepth 1 ! -name 'com.apple.*' ${EXCL_TOP[@]+"${EXCL_TOP[@]}"} \
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
      excl_deep_args
      sudo find /Library/Logs -type f -mtime +30 ${EXCL_DEEP[@]+"${EXCL_DEEP[@]}"} -delete 2>/dev/null || true
      ok "Pruned old files from /Library/Logs"
    fi
  fi
  if [[ -d /private/var/log ]] && require_sudo "/private/var/log"; then
    if (( DRY_RUN )); then
      note "[dry-run] would prune /private/var/log >14d"
    else
      excl_deep_args
      sudo find /private/var/log -type f -mtime +14 \
        \( -name '*.log' -o -name '*.log.*' -o -name '*.out' -o -name '*.err' \
           -o -name '*.asl' -o -name '*.gz' -o -name '*.bz2' \) \
        ${EXCL_DEEP[@]+"${EXCL_DEEP[@]}"} -delete 2>/dev/null || true
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
      note "[dry-run] would prune top-level files in $user_tmp (user-owned, at least 2d old)"
    else
      excl_deep_args
      find "$user_tmp" -mindepth 1 -maxdepth 1 -type f -user "$(id -un)" -mtime +1 \
        ${EXCL_DEEP[@]+"${EXCL_DEEP[@]}"} -delete 2>/dev/null || true
      ok "Pruned old user temp files"
    fi
  fi
  if [[ -d /private/tmp ]]; then
    if (( DRY_RUN )); then
      note "[dry-run] would prune top-level files in /tmp (user-owned, at least 2d old)"
    else
      find /private/tmp -mindepth 1 -maxdepth 1 -type f -user "$(id -un)" -mtime +1 \
        ${EXCL_DEEP[@]+"${EXCL_DEEP[@]}"} -delete 2>/dev/null || true
      ok "Pruned old /tmp entries (user-owned)"
    fi
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
      excl_top_args /Library/Updates
      sudo find /Library/Updates -mindepth 1 -maxdepth 1 ${EXCL_TOP[@]+"${EXCL_TOP[@]}"} -exec rm -rf -- {} + 2>/dev/null || true
      ok "Cleared /Library/Updates"
    fi
  fi
  mark_done 9; press_enter
}

# Section 10 — Empty Trash (home + mounted external volumes)
s10_trash() {
  header "[10] Empty Trash"
  local uid root_dev
  uid=$(id -u)
  root_dev=$(stat -f %d / 2>/dev/null || echo "")

  # Prompt for + empty one trash dir if it has contents. Reuses clean_dir_contents
  # (DRY_RUN-aware, symlink-guarded, tracks freed KB). auto_yes=1 keeps parity
  # with the prior home-Trash behaviour.
  _empty_trash_dir() {
    local _label="$1" _dir="$2" _sz _n
    [[ -d "$_dir" ]] || return 0
    _n=$(find "$_dir" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | awk '{print $1}')
    if (( _n == 0 )); then note "$_label: already empty."; return 0; fi
    _sz=$(size_h "$_dir")
    if confirm "Empty $_label ($_n items, $_sz)? This is irreversible." 1; then
      clean_dir_contents "$_dir"
    fi
  }

  if [[ -d "$HOME/.Trash" ]]; then
    _empty_trash_dir "Trash (home)" "$HOME/.Trash"
  else
    info "No home Trash directory found."
  fi

  # Per-volume trashes on mounted external/removable volumes live at
  # /Volumes/<name>/.Trashes/<uid>. We set nullglob (restoring prior state) so a
  # no-match glob doesn't iterate a literal path, skip the boot volume (same
  # device id as /), and skip read-only mounts. Kept in the current shell — NOT
  # a subshell — so clean_dir_contents' freed-KB tracking propagates.
  local _ng_was_set=0; shopt -q nullglob && _ng_was_set=1
  shopt -s nullglob
  local vol vdev t
  for vol in /Volumes/*; do
    [[ -d "$vol" ]] || continue
    vdev=$(stat -f %d "$vol" 2>/dev/null || echo "")
    [[ -n "$root_dev" && "$vdev" == "$root_dev" ]] && continue   # skip boot volume
    t="$vol/.Trashes/$uid"
    [[ -d "$t" ]] || continue
    if [[ ! -w "$t" ]]; then note "Skipping read-only volume trash: $(basename "$vol")"; continue; fi
    _empty_trash_dir "Trash on $(basename "$vol")" "$t"
  done
  (( _ng_was_set )) || shopt -u nullglob

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

