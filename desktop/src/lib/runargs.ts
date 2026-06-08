import type { AppSettings } from '../hooks/useSettings';

// Build the CLI threshold flags from settings as DISCRETE argv tokens
// (e.g. ["--cache-age-days", "30"]) — NOT a single "--cache-age-days=30"
// token. Each array element becomes one argument passed to mac-cleanup.sh.
// (The CLI also accepts the =value form now, but discrete tokens are the
// canonical, unambiguous way to pass arguments.)
export function buildExtraArgs(settings: AppSettings): string[] {
  return [
    '--cache-age-days', String(settings.cacheAgeDays),
    '--idle-days', String(settings.idleDays),
    '--large-file-size-gb', String(settings.largeFileSizeGb),
  ];
}
