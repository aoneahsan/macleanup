// Bridge to the Rust backend that runs the bundled mac-cleanup.sh.
import { invoke } from '@tauri-apps/api/core';
import { listen, type UnlistenFn } from '@tauri-apps/api/event';

export interface RunArgs {
  sections?: string; // "5,7,8"
  all?: boolean;
  dryRun?: boolean;
  yes?: boolean;
  understandDeep?: boolean;
  extraArgs?: string[];
}

/** The JSON summary emitted by `mac-cleanup.sh --json`. */
export interface CleanSummary {
  tool: string;
  version: string;
  dry_run: boolean;
  freed_kb: number;
  disk_free_delta_kb: number;
  elapsed_s: number;
  sections_done: number[];
  reports: string[];
  log_file: string;
}

export interface CleanDone {
  code: number;
  summary: CleanSummary | null;
  raw: string;
}

/** App (GUI) version, from the Rust binary. */
export function appVersion(): Promise<string> {
  return invoke<string>('app_version');
}

/**
 * Start a cleanup. Resolves once the run is dispatched; subscribe with
 * onLog / onDone / onError for progress.
 */
export function runClean(args: RunArgs): Promise<void> {
  return invoke('run_clean', { args });
}

/** Subscribe to live log lines (human-readable stderr from the CLI). */
export function onLog(cb: (line: string) => void): Promise<UnlistenFn> {
  return listen<string>('clean:log', (e) => cb(e.payload));
}

/** Subscribe to run completion. Parses the JSON summary if present. */
export function onDone(cb: (done: CleanDone) => void): Promise<UnlistenFn> {
  return listen<{ code: number; json: string }>('clean:done', (e) => {
    let summary: CleanSummary | null = null;
    try {
      summary = e.payload.json ? (JSON.parse(e.payload.json) as CleanSummary) : null;
    } catch {
      summary = null;
    }
    cb({ code: e.payload.code, summary, raw: e.payload.json });
  });
}

/** Subscribe to spawn errors. */
export function onError(cb: (msg: string) => void): Promise<UnlistenFn> {
  return listen<string>('clean:error', (e) => cb(e.payload));
}

/** Start the loopback OAuth listener; returns the localhost port. */
export function oauthListen(): Promise<number> {
  return invoke<number>('oauth_listen');
}

/** Subscribe to the OAuth redirect (raw query string with code+state). */
export function onOauthRedirect(cb: (query: string) => void): Promise<UnlistenFn> {
  return listen<{ query: string }>('oauth:redirect', (e) => cb(e.payload.query));
}
