# shellcheck shell=bash
# macleanup — module 02 of 10, lines 485–938 of the pre-5.2.2 single script.
# Sourced in order by macleanup.sh; never run on its own.

# archive_if_requested path → 0 when no archive was asked for, or the archive
# was written; 1 when one was asked for and could not be written (the caller
# must then leave the path in place). Archives are gzip tarballs, mode 600,
# in a mode-700 folder, named <date>-<basename>.tar.gz.
archive_if_requested() {
  local p="${1%/}" a want=0
  for a in "${ARCHIVE_PATHS[@]+"${ARCHIVE_PATHS[@]}"}"; do
    [[ "$p" == "$a" || "$p" == "$a/"* ]] && { want=1; break; }
  done
  (( want )) || return 0
  local base out
  base="${p##*/}"; base="${base//[^A-Za-z0-9._-]/_}"
  out="$ARCHIVE_DIR/$(date '+%Y%m%d-%H%M%S')-${base}.tar.gz"
  if (( DRY_RUN )); then
    note "[dry-run] would archive $p to $out"
    (( JSON_EVENTS )) && ev_item "$p" "$(size_kb "$p")" archive
    return 0
  fi
  ( umask 077; mkdir -p "$ARCHIVE_DIR" ) || return 1
  chmod 700 "$ARCHIVE_DIR" 2>/dev/null || true
  if ( umask 077; tar -czf "$out" -C "$(dirname "$p")" "${p##*/}" ) 2>/dev/null; then
    chmod 600 "$out" 2>/dev/null || true
    ok "Archived $p → $out"
    (( JSON_EVENTS )) && ev_item "$p" "$(size_kb "$p")" archive
    return 0
  fi
  rm -f -- "$out" 2>/dev/null || true
  warn "Could not archive $p; left it in place."
  return 1
}

# safe_rm_rf path → respects DRY_RUN; refuses suspicious paths.
# This is the central deletion chokepoint. Its refusal list is intentionally
# broad: top-level system roots, user document roots, and every
# CRITICAL_HOME_DIRS entry are rejected even on an exact match, and any path
# containing a relative ".."/"." component is rejected outright (we never
# canonicalise — macOS lacks GNU `readlink -f` by default).
safe_rm_rf() {
  local p="$1"
  # Reject relative-escape / dot components before anything else.
  case "$p" in
    *"/../"*|*"/.."|".."|*"/."|".") err "Refusing relative/dot path: '$p'"; return 1 ;;
  esac
  # Static blocklist of system + user-data roots (with trailing-slash forms).
  case "$p" in
    ""|"/"|"/Users"|"/Users/"|"$HOME"|"$HOME/" \
    |"/Library"|"/Library/"|"/System"|"/System/"|"/System/Library"|"/System/Applications" \
    |"/Applications"|"/Applications/"|"/private"|"/private/"|"/usr"|"/usr/" \
    |"/etc"|"/etc/"|"/var"|"/var/"|"/bin"|"/bin/"|"/sbin"|"/sbin/"|"/cores"|"/cores/" \
    |"$HOME/Documents"|"$HOME/Documents/"|"$HOME/Desktop"|"$HOME/Desktop/" \
    |"$HOME/Downloads"|"$HOME/Downloads/"|"$HOME/Pictures"|"$HOME/Pictures/" \
    |"$HOME/Movies"|"$HOME/Movies/"|"$HOME/Music"|"$HOME/Music/"|"$HOME/Library"|"$HOME/Library/")
      err "Refusing to delete protected path: '$p'"
      return 1 ;;
  esac
  # Refuse any CRITICAL_HOME_DIRS entry on exact match (toolchains/secrets).
  local _e
  for _e in "${CRITICAL_HOME_DIRS[@]}"; do
    case "$p" in
      "$HOME/$_e"|"$HOME/$_e/") err "Refusing protected toolchain/config dir: '$p'"; return 1 ;;
    esac
  done
  if path_is_excluded "$p"; then
    note "Kept (excluded): $p"
    (( JSON_EVENTS )) && ev_item "$p" 0 skip
    return 0
  fi
  archive_if_requested "$p" || return 1
  (( JSON_EVENTS )) && ev_item "$p" "$(size_kb "$p")" delete
  if (( DRY_RUN )); then
    note "[dry-run] rm -rf $p"
    return 0
  fi
  rm -rf -- "$p" 2>/dev/null || return 1
}

safe_rm_f() {
  local p="$1"
  if path_is_excluded "$p"; then note "Kept (excluded): $p"; return 0; fi
  archive_if_requested "$p" || return 1
  (( JSON_EVENTS )) && ev_item "$p" "$(size_kb "$p")" delete
  if (( DRY_RUN )); then note "[dry-run] rm -f $p"; return 0; fi
  rm -f -- "$p" 2>/dev/null || return 1
}

# clean_dir_contents path
# Removes everything inside path (but not the dir itself), tracks freed KB.
# _sum_kb_nul — read NUL-delimited paths on stdin, echo the total size in KB.
# Used by dry-run to ESTIMATE how much a delete would free without touching
# disk. (`du -sk` per arg works for both files and directories.)
_sum_kb_nul() {
  xargs -0 du -sk 2>/dev/null | awk '{ s += $1 } END { print s + 0 }'
}

clean_dir_contents() {
  local d="$1" before
  [[ -z "$d" ]] && return 0
  if path_is_excluded "$d"; then note "Kept (excluded): $d"; return 0; fi
  if [[ ! -d "$d" ]]; then
    note "Skipping (missing): $d"
    return 0
  fi
  before=$(size_kb "$d")
  ev_item "$d" "$before" delete
  if (( DRY_RUN )); then
    note "[dry-run] would clear $(human_kb "$before") in $d"
    track_freed "$before" 0   # estimate: the whole directory would be cleared
    return 0
  fi
  # Revalidate immediately before the wipe: reject a symlinked $d (its /* glob
  # would delete through to the link target) and close the TOCTOU window.
  [[ -d "$d" && ! -L "$d" ]] || { note "Skipping (symlink or not a real dir): $d"; return 0; }
  # Delete contents; never the directory itself. Use ${var:?} guard.
  excl_top_args "$d"
  if (( ${#EXCL_TOP[@]} > 0 )); then
    emit_kept_tops "$d"
    find "$d" -mindepth 1 -maxdepth 1 "${EXCL_TOP[@]}" -exec rm -rf -- {} + 2>/dev/null || true
    track_freed "$before" "$(size_kb "$d")"
  else
    ( shopt -s dotglob nullglob; rm -rf -- "${d:?}"/* 2>/dev/null ) || true
    # The directory was fully emptied; skip a second du and report `before`.
    track_freed "$before" 0
  fi
  ok "Cleared $(human_kb "$before") from $d"
}

# clean_dir_old path days [name_glob…]
# Deletes files older than N days inside dir; honors DRY_RUN; tracks freed KB.
clean_dir_old() {
  local d="$1" days="$2"
  shift 2
  local globs=("$@")
  [[ ! -d "$d" ]] && return 0
  if path_is_excluded "$d"; then note "Kept (excluded): $d"; return 0; fi
  local before after
  before=$(size_kb "$d")
  # Build the -name OR-clause once (shared by the estimate + the real delete).
  local name_args=()
  if (( ${#globs[@]} > 0 )); then
    local g
    for g in "${globs[@]}"; do name_args+=( -o -name "$g" ); done
    name_args=( "${name_args[@]:1}" )  # drop leading -o
  fi
  if (( DRY_RUN )); then
    local est
    if (( ${#name_args[@]} == 0 )); then
      est=$(find "$d" -type f -mtime "+$days" -print0 2>/dev/null | _sum_kb_nul)
    else
      est=$(find "$d" -type f -mtime "+$days" \( "${name_args[@]}" \) -print0 2>/dev/null | _sum_kb_nul)
    fi
    note "[dry-run] would prune $(human_kb "$est") (>${days}d) from $d"
    ev_item "$d" "$est" delete
    track_freed "$est" 0
    return 0
  fi
  excl_deep_args
  if (( ${#name_args[@]} == 0 )); then
    find "$d" -type f -mtime "+$days" ${EXCL_DEEP[@]+"${EXCL_DEEP[@]}"} -print0 2>/dev/null | xargs -0 rm -f 2>/dev/null || true
  else
    find "$d" -type f -mtime "+$days" \( "${name_args[@]}" \) ${EXCL_DEEP[@]+"${EXCL_DEEP[@]}"} -print0 2>/dev/null \
      | xargs -0 rm -f 2>/dev/null || true
  fi
  after=$(size_kb "$d")
  track_freed "$before" "$after"
  ev_item "$d" "$(( before - after ))" delete
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
  if path_is_excluded "$d"; then note "Kept (excluded): $d"; return 0; fi
  if [[ ! -d "$d" ]]; then
    note "Skipping (missing): $d"
    return 0
  fi
  local before after freed
  before=$(size_kb "$d")
  if (( DRY_RUN )); then
    local est
    if (( days == 0 )); then
      est="$before"
      note "[dry-run] would full-wipe $d ($(human_kb "$est"))"
    else
      est=$(find "$d" -mindepth 1 -type f -atime "+$days" -mtime "+$days" -print0 2>/dev/null | _sum_kb_nul)
      note "[dry-run] would prune $(human_kb "$est") (>${days}d unused) from $d"
    fi
    ev_item "$d" "$est" delete
    track_freed "$est" 0
    return 0
  fi
  if (( days == 0 )); then
    # Revalidate immediately before the full wipe (reject symlinked $d).
    [[ -d "$d" && ! -L "$d" ]] || { note "Skipping (symlink or not a real dir): $d"; return 0; }
    excl_top_args "$d"
    if (( ${#EXCL_TOP[@]} > 0 )); then
      emit_kept_tops "$d"
      find "$d" -mindepth 1 -maxdepth 1 "${EXCL_TOP[@]}" -exec rm -rf -- {} + 2>/dev/null || true
      after=$(size_kb "$d")
    else
      ( shopt -s dotglob nullglob; rm -rf -- "${d:?}"/* 2>/dev/null ) || true
      after=0   # directory was fully emptied; avoid a second du
    fi
  else
    # Files where BOTH atime > N days AND mtime > N days. Anything used
    # recently (read by a tool, or rewritten) keeps its atime/mtime fresh
    # and survives.
    excl_deep_args
    find "$d" -mindepth 1 -type f -atime "+$days" -mtime "+$days" ${EXCL_DEEP[@]+"${EXCL_DEEP[@]}"} \
      -print0 2>/dev/null | xargs -0 rm -f 2>/dev/null || true
    # Collapse newly-empty directories. Multiple passes handle nesting
    # (parent becomes empty after children are removed, etc.).
    for _ in 1 2 3 4; do
      find "$d" -mindepth 1 -type d -empty -delete 2>/dev/null || break
    done
    after=$(size_kb "$d")
  fi
  track_freed "$before" "$after"
  freed=$(( before - after ))
  ev_item "$d" "$freed" delete
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

# When invoked by the desktop GUI (which sets MACLEANUP_ASKPASS to a graphical
# password helper), route sudo through that askpass so the user is prompted
# ONCE per run via a native dialog — no TTY needed. sudo caches the credential
# for the rest of the run, so all subsequent privileged steps are prompt-free.
# Terminal users are unaffected (MACLEANUP_ASKPASS is unset → normal sudo).
if [[ -n "${MACLEANUP_ASKPASS:-}" && -x "${MACLEANUP_ASKPASS:-}" ]]; then
  export SUDO_ASKPASS="$MACLEANUP_ASKPASS"
  sudo() { command sudo -A "$@"; }
fi

# require_sudo — returns 0 if we have (or got) sudo, 1 otherwise
require_sudo() {
  if (( NO_SUDO )); then
    warn "Skipping (sudo disabled): $*"
    return 1
  fi
  # Dry-run previews never perform privileged work, so never prompt for a
  # password during a preview — only a real run asks.
  if (( DRY_RUN )); then
    return 0
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
    printf '#  Made by   : %s <%s>\n' "$AUTHOR_NAME" "$AUTHOR_EMAIL"
    printf '#  Website   : %s\n' "$PROJECT_WEBSITE"
    printf '#  Docs      : %s\n' "$PROJECT_DOCS"
    printf '#  Repo      : %s\n' "$PROJECT_REPO"
    printf '#  npm pkg   : %s\n' "$PROJECT_NPM"
    printf '#  License   : MIT — free to use, copy, modify, and redistribute\n'
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
  if path_is_excluded "$p"; then
    note "Kept (excluded): $p"
    (( JSON_EVENTS )) && ev_item "$p" 0 skip
    return 1
  fi
  archive_if_requested "$p" || return 1
  (( JSON_EVENTS )) && ev_item "$p" "$(size_kb "$p")" trash
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
  f=$(mktemp -t macleanup.XXXXXX)
  TMPFILES+=("$f")
  printf '%s' "$f"
}

# ──────────────────────────────────────────────────────────────────────────
#                              ARGS / HELP
