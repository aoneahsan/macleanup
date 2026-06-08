// Forced update on launch. On start we check the updater manifest; if a newer
// version exists we download + install it and relaunch BEFORE the app is
// usable (per the "users must update to keep using" requirement). If the
// updater isn't configured yet (placeholder pubkey / no release), or the check
// fails (offline), we fail OPEN so the app still launches.
import { check, type Update } from '@tauri-apps/plugin-updater';
import { relaunch } from '@tauri-apps/plugin-process';

export type UpdatePhase =
  | { phase: 'checking' }
  | { phase: 'up-to-date' }
  | { phase: 'available'; version: string; notes?: string }
  | { phase: 'downloading'; pct: number }
  | { phase: 'installing' }
  | { phase: 'error'; message: string };

/**
 * Check for an update. Returns the Update handle if one is available, else null.
 * Never throws — returns null on any failure (fail-open).
 */
export async function checkForUpdate(onPhase?: (p: UpdatePhase) => void): Promise<Update | null> {
  try {
    onPhase?.({ phase: 'checking' });
    const update = await check();
    if (update) {
      onPhase?.({ phase: 'available', version: update.version, notes: update.body });
      return update;
    }
    onPhase?.({ phase: 'up-to-date' });
    return null;
  } catch (e) {
    // Not configured yet / offline / no release — don't block launch.
    onPhase?.({ phase: 'error', message: String(e) });
    return null;
  }
}

/** Download + install the update with progress, then relaunch. */
export async function installAndRelaunch(update: Update, onPhase?: (p: UpdatePhase) => void): Promise<void> {
  let total = 0;
  let downloaded = 0;
  await update.downloadAndInstall((event) => {
    switch (event.event) {
      case 'Started':
        total = event.data.contentLength ?? 0;
        onPhase?.({ phase: 'downloading', pct: 0 });
        break;
      case 'Progress':
        downloaded += event.data.chunkLength;
        onPhase?.({ phase: 'downloading', pct: total ? Math.round((downloaded / total) * 100) : 0 });
        break;
      case 'Finished':
        onPhase?.({ phase: 'installing' });
        break;
    }
  });
  await relaunch();
}
