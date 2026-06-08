// Small formatting helpers (no deps).

/** KB -> human-readable size, matching the CLI's human_kb(). */
export function humanKb(kb: number): string {
  if (!kb || kb < 1) return '0 B';
  if (kb < 1024) return `${Math.round(kb)} KB`;
  if (kb < 1024 * 1024) return `${(kb / 1024).toFixed(1)} MB`;
  if (kb < 1024 * 1024 * 1024) return `${(kb / 1024 / 1024).toFixed(2)} GB`;
  return `${(kb / 1024 / 1024 / 1024).toFixed(2)} TB`;
}

/** Seconds -> "1m 20s" / "45s". */
export function humanDuration(s: number): string {
  if (s < 60) return `${s}s`;
  const m = Math.floor(s / 60);
  const r = s % 60;
  return r ? `${m}m ${r}s` : `${m}m`;
}
